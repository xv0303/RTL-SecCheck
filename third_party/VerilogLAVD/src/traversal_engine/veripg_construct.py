from pyverilog.vparser.parser import parse

from neo4j import GraphDatabase

driver = None

#需要跳过的节点列表
skip_nodes = [
    "Var", 
    "Lvalue", 
    "Rvalue",
    "Block"
]

#需要删除的节点列表
delete_nodes = [
    "Source",
    "Description",
    "ModuleDef",
]

#需要更名的节点列表
rename_nodes = {
    "IfStatement":"If",
    "ForStatement":"For",
    "BlockingSubstitution":"=",
    "NonblockingSubstitution":"<=",
    "Plus":"+",
    "Minus":"-",
}
#语句节点
stmt_nodes = [
    "If",
    "For",
    "<=",
    "="
]

node_map = {}
always_nodes = []
if_nodes = []
for_nodes = []
assign_nodes = []
blocking_nodes = []
nonblocking_nodes = []
declvar_nodes = []
switch_nodes = []
nb_nodes = []

def get_node_by_elementid(elementid):
    """
    根据elementid获取节点
    :param elementid: 节点的elementid
    :return: 节点对象
    """
    global driver
    session = driver.session()

    res = session.run(
        "MATCH (n) WHERE elementId(n) = $element_id RETURN n",
        element_id=elementid
    )
    result = res.single()[0]
    
    session.close()
    return result

def create_node_by_astnode(ast_node):
    """
    根据ast节点创建neo4j节点
    :param ast_node: ast节点
    :return: neo4j节点id
    """
    global driver
    session = driver.session()
    
    node_type = ast_node.__class__.__name__
    node_attr = {"lineno": ast_node.lineno, 'name': ast_node.__class__.__name__}
    for key in ast_node.attr_names:
        node_attr[key if key!='name' else 'label'] = getattr(ast_node, key)

    attributes = ", ".join([f"{key}: ${key}" for key in node_attr.keys()])
    query = f"CREATE (n:{node_type} {{{attributes}}}) RETURN elementId(n) AS element_id"
    result = session.run(query, **node_attr)
    new_element_id = result.single()["element_id"]

    session.close()
    return new_element_id

def get_nodes_count():
    """
    获取节点数量
    :return: 节点数量
    """
    global driver
    session = driver.session()
    res = session.run("MATCH (n) RETURN count(n) AS count")
    result = res.single()["count"]
    session.close()
    return result

def get_relationships_count():
    """
    获取关系数量
    :return: 关系数量
    """
    global driver
    session = driver.session()
    res = session.run("MATCH ()-[r]->() RETURN count(r) AS count")
    result = res.single()["count"]
    session.close()
    return result

def delete_all_nodes():
    global driver
    session = driver.session()
    session.run("MATCH (n) DETACH DELETE n")
    session.close()
    global node_map, always_nodes, if_nodes, for_nodes, assign_nodes, blocking_nodes, nonblocking_nodes,declvar_nodes,switch_nodes, nb_nodes
    node_map = {}
    always_nodes = []
    if_nodes = []
    for_nodes = []
    assign_nodes = []
    blocking_nodes = []
    nonblocking_nodes = []
    declvar_nodes = []
    switch_nodes = []
    nb_nodes = []

def create_relationship(start_elementid, end_elementid, rel_type, condition):
    global driver
    session = driver.session()
    
    query = f"MATCH (n) WHERE elementId(n) = $start_elementid MATCH (m) WHERE elementId(m) = $end_elementid " \
            f"CREATE (n)-[r:{rel_type} {{condition: $condition}}]->(m) RETURN elementId(r) AS element_id"
    res = session.run(query, start_elementid=start_elementid, end_elementid=end_elementid, condition=condition)
    result = res.single()
    if result is not None:
        result = result["element_id"]
    session.close()
    return result

def delete_node(node_type):
    """
    删除指定类型的节点
    :param node_type: 节点类型
    :return: None
    """
    global driver
    session = driver.session()
    session.run(f"MATCH (n:{node_type}) DETACH DELETE n")
    session.close()

def ast2neo4j(ast_node, node_id):
    """
    将AST节点转换为Neo4j节点
    :param ast_node: AST节点
    """
    #存储特定ast_node
    if(ast_node.__class__.__name__ == 'Always'):
        always_nodes.append(ast_node)
    elif(ast_node.__class__.__name__ == 'IfStatement'):
        if_nodes.append(ast_node)
    elif(ast_node.__class__.__name__ == 'ForStatement'):
        for_nodes.append(ast_node)
    elif(ast_node.__class__.__name__ == 'BlockingSubstitution'):
        blocking_nodes.append(ast_node)
    elif(ast_node.__class__.__name__ == 'NonblockingSubstitution'):
        nonblocking_nodes.append(ast_node)
    elif(ast_node.__class__.__name__ == 'Decl'):
        declvar_nodes.append(ast_node)
    elif(ast_node.__class__.__name__ == 'Assign'):
        assign_nodes.append(ast_node)
    elif(ast_node.__class__.__name__ == 'CaseStatement'):
        switch_nodes.append(ast_node)
        
    if ast_node.__class__.__name__ == 'BlockingSubstitution' or ast_node.__class__.__name__ == 'NonblockingSubstitution':
        nb_nodes.append(ast_node)

    node_map[object.__repr__(ast_node)] = node_id

    ast_node_children = list(ast_node.children())

    # 遍历AST节点的子节点
    for ast_child_node in ast_node_children:
        #跳过需要删除节点
        if ast_child_node.__class__.__name__ in delete_nodes or ast_child_node.__class__.__name__ in skip_nodes:
            ast_node_children.extend(ast_child_node.children())
            continue

        child_id = create_node_by_astnode(ast_child_node)
        create_relationship(node_id, child_id, "AST", "")
        ast2neo4j(ast_child_node, child_id)

def set_assign_relationship():
    """
    设置赋值关系
    """
    non_blocking_assign_nodes = nonblocking_nodes + blocking_nodes + assign_nodes
    for node in non_blocking_assign_nodes:
        left_node = node.left.var
        right_node = node.right.var
        # node_id = node_map[object.__repr__(node)]
        # left_node_id = node_map[object.__repr__(left_node)]
        # right_node_id = node_map[object.__repr__(right_node)]
        break_relationship_by_ast_node(node, left_node)
        break_relationship_by_ast_node(node, right_node)
        create_relationship_by_ast_node(node, left_node, "AST", "left")
        create_relationship_by_ast_node(node, right_node, "AST", "right")

def get_ast_children_by_relation(ast_node, relation):
    """
    获取AST节点的子节点
    :param ast_node: AST节点
    :return: 子节点列表
    """
    ast_node_children = []
    ast_node_child = getattr(ast_node, relation)
    if(ast_node_child is None):
        return ast_node_children
    elif(ast_node_child.__class__.__name__ == 'Block'):
        ast_node_children = list(ast_node_child.children())
    else:
        ast_node_children = [ast_node_child]

    return ast_node_children

def create_relationship_by_ast_node(ast_node_a, ast_node_b, relation, condition):
    """
    创建节点之间的关系
    :param node_a_id: 节点A的ID
    :param node_b_id: 节点B的ID
    :param relation: 关系类型
    :param condition: 关系条件
    :return: 关系ID
    """
    node_a_id = node_map[object.__repr__(ast_node_a)]
    node_b_id = node_map[object.__repr__(ast_node_b)]
    return create_relationship(node_a_id, node_b_id, relation, condition)

def break_relationship_by_ast_node(ast_node_a, ast_node_b):
    """
    删除节点之间的关系
    :param node_a_id: 节点A的ID
    :param node_b_id: 节点B的ID
    :return: None
    """
    node_a_id = node_map[object.__repr__(ast_node_a)]
    node_b_id = node_map[object.__repr__(ast_node_b)]
    global driver
    session = driver.session()
    session.run(
        "MATCH (n)-[r]->(m) WHERE elementId(n) = $node_a_id AND elementId(m) = $node_b_id DELETE r",
        node_a_id=node_a_id, node_b_id=node_b_id
    )
    session.close()

def Insert_node_before_ast_node(ast_node, ast_node_insert, relation):
    """
    在指定AST节点之前插入一个新节点
    :param ast_node: 原AST节点
    :param ast_node_insert: 新AST节点
    :param relation: 关系类型
    :return: None
    """
    node_id = node_map[object.__repr__(ast_node)]
    node_insert_id = node_map[object.__repr__(ast_node_insert)]
    global driver
    session = driver.session()
    query = (
        f"MATCH (b) WHERE elementId(b) = $node_insert_id "
        f"MATCH (c) WHERE elementId(c) = $node_id "
        f"MATCH (a)-[r:{relation}]->(c)"
        f"CREATE (a)-[new_r:{relation}]->(b) "
        f"SET new_r = properties(r) "
        f"CREATE (b)-[new_r2:{relation}]->(c) "
        f"SET new_r2.condition = '' "
        f"DELETE r"
    )
    session.run(query, node_id=node_id, node_insert_id=node_insert_id)
    session.close()

def Append_node_at_relationship_end(ast_node, ast_node_insert, relation):
    """
    在指定AST节点之后插入一个新节点
    :param ast_node: 原AST节点
    :param ast_node_insert: 新AST节点
    :param relation: 关系类型
    :return: None
    """
    node_id = node_map[object.__repr__(ast_node)]
    node_insert_id = node_map[object.__repr__(ast_node_insert)]
    global driver
    session = driver.session()
    query = (
        f"MATCH path = (start)-[:{relation}*]->(last)"
        f"WHERE elementId(start) = $node_id AND NOT (last)-[:{relation}]->()"
        f"MATCH (end) WHERE elementId(end) = $node_insert_id "
        f"CREATE (last)-[r:{relation}]->(end)"
        f"SET r.condition = '' "
    )
    session.run(query, node_id=node_id, node_insert_id=node_insert_id)
    session.close()


def cfg2neo4j():
    for always_ast in always_nodes:
        always_ast_children = get_ast_children_by_relation(always_ast, 'statement')
        for always_ast_child in always_ast_children:
            break_relationship_by_ast_node(always_ast, always_ast_child)
            create_relationship_by_ast_node(always_ast, always_ast_child, "CFG", "")
    
    for if_ast in if_nodes:
        if_ast_children = get_ast_children_by_relation(if_ast, 'true_statement')
        for if_ast_child in if_ast_children:
            break_relationship_by_ast_node(if_ast, if_ast_child)
            create_relationship_by_ast_node(if_ast, if_ast_child, "CFG", "true")
        
        if_ast_children = get_ast_children_by_relation(if_ast, 'false_statement')
        for if_ast_child in if_ast_children:
            break_relationship_by_ast_node(if_ast, if_ast_child)
            create_relationship_by_ast_node(if_ast, if_ast_child, "CFG", "false")
    
    for for_ast in for_nodes:
        for_ast_children = get_ast_children_by_relation(for_ast, 'statement')
        for_ast_init = get_ast_children_by_relation(for_ast, 'pre')
        for_ast_post = get_ast_children_by_relation(for_ast, 'post')
        # for_ast_cond = get_ast_children_by_relation(for_ast, 'cond')
        for for_ast_child in for_ast_children:
            break_relationship_by_ast_node(for_ast, for_ast_child)
            create_relationship_by_ast_node(for_ast, for_ast_child, "CFG", "true")
        
        for for_ast_child in for_ast_init:
            break_relationship_by_ast_node(for_ast, for_ast_child)
            Insert_node_before_ast_node(for_ast, for_ast_child, "CFG")
        
        for for_ast_child in for_ast_post:
            break_relationship_by_ast_node(for_ast, for_ast_child)
            Append_node_at_relationship_end(for_ast, for_ast_child, "CFG")
            create_relationship_by_ast_node(for_ast_child, for_ast, "CFG", "")
    
    for switch_ast in switch_nodes:
        caselist = switch_ast.caselist
        for case_ast in caselist:
            break_relationship_by_ast_node(switch_ast, case_ast)
            create_relationship_by_ast_node(switch_ast, case_ast, "CFG", "")
            for case_ast_child in get_ast_children_by_relation(case_ast, 'statement'):
                cond_list = getattr(case_ast, 'cond', [])
                if cond_list is None:
                    cond_list = []
                if case_ast_child not in cond_list:
                    break_relationship_by_ast_node(case_ast, case_ast_child)
                    create_relationship_by_ast_node(case_ast, case_ast_child, "CFG", "")

def get_all_nodes_by_relationship(start_node_id, relation):
    """
    获取所有节点
    :param start_node_id: 起始节点ID
    :param relation: 关系类型
    :return: 节点列表
    """
    global driver
    session = driver.session()
    query = """
        MATCH (start)
        WHERE elementId(start) = $start_node_id
        MATCH path = (start)-[:{relation}*0..20]->(endNode)
        UNWIND nodes(path) AS node
        RETURN DISTINCT elementId(node) AS node_id
        """
    result = session.run(query, start_node_id=start_node_id)
    return [record["node_id"] for record in result]

def get_label_values(start_node_id):
    """
    获取标识符名称
    :param start_node_id: 起始节点ID
    :return: 标识符名称列表
    """
    global driver
    session = driver.session()
    query = """
        MATCH (start)
        WHERE elementId(start) = $start_node_id
        MATCH path = (start)-[:AST*0..10]->(endNode)
        UNWIND nodes(path) AS node
        WITH node
        WHERE node.label IS NOT NULL
        RETURN node.label AS label_value
        """
    result = session.run(query, start_node_id=start_node_id)
    values = [record["label_value"] for record in result]
    session.close()

    return values

def ddg2neo4j():
    value_map_id = {}
    for declvar in declvar_nodes:
        value_map_id[get_label_values(node_map[object.__repr__(declvar)])[0]] = node_map[object.__repr__(declvar)]

    print("value_map_id:", value_map_id)
    
    aif_nodes = always_nodes + if_nodes + for_nodes
    for aif_node in aif_nodes:
        label_values = get_label_values(node_map[object.__repr__(aif_node)])
        for label_value in label_values:
            if label_value in value_map_id:
                start_node_id = value_map_id[label_value]
                end_node_id = node_map[object.__repr__(aif_node)]
                create_relationship(start_node_id, end_node_id, "DDG", "")
    
    abn_nodes = assign_nodes + blocking_nodes + nonblocking_nodes
    for abn_node in abn_nodes:
        rvalue = getattr(abn_node, 'right')
        right_node = getattr(rvalue,'var')
        label_values = get_label_values(node_map[object.__repr__(right_node)])
        for label_value in label_values:
            if label_value in value_map_id:
                start_node_id = value_map_id[label_value]
                end_node_id = node_map[object.__repr__(abn_node)]
                create_relationship(start_node_id, end_node_id, "DDG", "")
    
    print("abn_nodes:", abn_nodes)

    print("nb_nodes:", nb_nodes)
    for i in range(len(nb_nodes)-1):
        create_relationship_by_ast_node(nb_nodes[i],nb_nodes[i+1], "DDG", "")

def VeriPG(file_name, in_driver):
    node_map = {}
    always_nodes = []
    if_nodes = []
    for_nodes = []
    assign_nodes = []
    blocking_nodes = []
    nonblocking_nodes = []
    declvar_nodes = []
    switch_nodes = []

    #调用pyverilog库的parse函数，解析verilog文件，返回AST树
    ast, _ = parse([file_name])

    # 连接数据库
    global driver
    driver = in_driver

    print("delete_all_nodes")
    delete_all_nodes()

    print("ast2neo4j")
    ast2neo4j(ast, create_node_by_astnode(ast))

    print("set_assign_relationship")
    set_assign_relationship()

    print("delete_node(Source)")
    delete_node('Source')

    print("cfg2neo4j")
    cfg2neo4j()

    print("ddg2neo4j")
    ddg2neo4j()

    nodes_count = get_nodes_count()
    relationships_count = get_relationships_count()
    return nodes_count, relationships_count

def astneo4j(file_name, in_driver):
    node_map = {}
    always_nodes = []
    if_nodes = []
    for_nodes = []
    assign_nodes = []
    blocking_nodes = []
    nonblocking_nodes = []
    declvar_nodes = []
    switch_nodes = []

    #调用pyverilog库的parse函数，解析verilog文件，返回AST树
    ast, _ = parse([file_name])

    # 连接数据库
    global driver
    driver = in_driver

    print("delete_all_nodes")
    delete_all_nodes()

    print("ast2neo4j")
    ast2neo4j(ast, create_node_by_astnode(ast))