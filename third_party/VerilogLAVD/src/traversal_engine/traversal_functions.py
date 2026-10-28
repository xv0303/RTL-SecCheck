from function_registry import register_func

node_names = {
    "If":"IfStatement",
    "For":"ForStatement",
    "<=":"NonblockingSubstitution",
    "=":"BlockingSubstitution",
    "Switch":"CaseStatement",
}

# 通用图遍历
@register_func(name="Node")
def GetNodeId(session, node_name):
    """
    获取指定名称的节点ElementId
    :param session: 数据库会话
    :param node_name: 节点名称
    :return: 节点ElementId列表
    """
    if node_name in node_names:
        node_name = node_names[node_name]
    query = f"""
        MATCH (n)
        WHERE n.name = $node_name
        RETURN DISTINCT elementId(n) AS node_id
    """
    result = session.run(query, node_name=node_name)
    node_ids = [record["node_id"] for record in result]
    return node_ids

@register_func(name="ASTOffspring")
def ASTOffspring(session, node_id, offspring_node_type):
    """
    获取指定节点的指定类型后代节点ElementId
    :param session: 数据库会话
    :param node_id: 节点ID
    :param offspring_node_type: 后代节点类型
    :return: 后代节点ElementId列表
    """
    if offspring_node_type in node_names:
        offspring_node_type = node_names[offspring_node_type]
    query = f"""
        MATCH (n)-[:AST*0..]->(m)
        WHERE elementId(n) = $node_id AND m.name = $offspring_node_type
        RETURN DISTINCT elementId(m) AS node_id
    """
    result = session.run(query, node_id=node_id, offspring_node_type=offspring_node_type)
    node_ids = [record["node_id"] for record in result]
    print("ASTOffspring: ", node_ids)
    return node_ids

@register_func(name="CFGOffspring")
def CFGOffspring(session, node_id, offspring_node_type):
    """
    获取指定节点的指定类型后代节点ElementId
    :param session: 数据库会话
    :param node_id: 节点ID
    :param offspring_node_type: 后代节点类型
    :return: 后代节点ElementId列表
    """
    if offspring_node_type in node_names:
        offspring_node_type = node_names[offspring_node_type]
    query = f"""
        MATCH (n)-[:CFG*0..]->(m)
        WHERE elementId(n) = $node_id AND m.name = $offspring_node_type
        RETURN DISTINCT elementId(m) AS node_id
    """
    # query = f"""
    #     MATCH (n)-[:CFG*0..]->(m)
    #     WHERE elementId(n) = {node_id} AND m.name = {offspring_node_type}
    #     RETURN DISTINCT elementId(m) AS node_id
    # """
    # print("CFGOffspring query: ")
    # print(query)
    # result = session.run(query)
    result = session.run(query, node_id=node_id, offspring_node_type=offspring_node_type)
    node_ids = [record["node_id"] for record in result]
    print("CFGOffspring: ", node_ids)
    return node_ids

@register_func(name="Equal")
def Equal(session, a, b):
    """
    判断ab是否相同
    :param a: 变量A
    :param b: 变量B
    :return: 判断结果
    """
    print("Equal:", a, b)
    return a == b

@register_func(name="NotEqual")
def NotEqual(session, a, b):
    """
    判断ab是否不相同
    :param a: 变量A
    :param b: 变量B
    :return: 判断结果
    """
    print("NotEqual:", a, b)
    return a != b

@register_func(name="And")
def And(session, a, b):
    return a and b

@register_func(name="Or")
def Or(session, a, b):
    return a or b

@register_func(name="In")
def In(session, v, l):
    """
    判断value是否在列表中
    :param value: 值
    :param list: 列表
    :return: 判断结果
    """
    if not isinstance(l, list):
        l = [l]
    print("In:", v, l)
    return v in l

@register_func(name="Merge")
def Merge(session, l1, l2):
    """
    合并两个列表
    :param l1: 列表1
    :param l2: 列表2
    :return: 合并后的列表
    """
    print("Merge:", l1, l2)
    return list(set(l1 + l2))

@register_func(name="Exist")
def Exist(session, list):
    """
    判断列表是否存在
    :param list: 列表
    :return: 判断结果
    """
    print("Exist:", list)
    return len(list) != 0

@register_func(name="NotExist")
def NotExist(session, list):
    """
    判断列表是否不存在
    :param list: 列表
    :return: 判断结果
    """
    print("NotExist:", list)
    if len(list) == 0 or len(list)!=0 and list[0]==None:
        return True
    return False

@register_func(name="Count")
def Count(session, list):
    """
    计算列表长度
    :param list: 列表
    :return: 长度
    """
    return len(list)

@register_func(name="Has")
def Has(session, l, value):
    """
    判断列表内容是否包含value
    :param l: 列表
    :param value: 值
    :return: 判断结果
    """
    if not isinstance(l, list):
        l = [l]
    for item in l:
        if value in item:
            print("Has:", l, value, True)
            return True
    print("Has:", l, value, False)
    return False

@register_func(name="NotHas")
def NotHas(session, l, value):
    """
    判断列表内容是否不包含value
    :param l: 列表
    :param value: 值
    :return: 判断结果
    """
    if l is not list:
        l = [l]
    for item in l:
        if value in item:
            print("NotHas:", l, value, False)
            return False
    print("NotHas:", l, value, True)
    return True

@register_func(name="Always")
def Always(session):
    """
    获取所有的Always节点
    :param session: 数据库会话
    :return: Always节点ElementId列表
    """
    return GetNodeId(session, "Always")

@register_func(name="If")
def If(session):
    """
    获取所有的If节点
    :param session: 数据库会话
    :return: If节点ElementId列表
    """
    result = GetNodeId(session, "IfStatement")
    print("If:", result)
    return result

@register_func(name="For")
def For(session):
    """
    获取所有的For节点
    :param session: 数据库会话
    :return: For节点ElementId列表
    """
    result = GetNodeId(session, "ForStatement")
    print("For:", result)
    return result

@register_func(name="Blocking")
def Blocking(session):
    """
    获取所有的Blocking节点
    :param session: 数据库会话
    :return: Blocking节点ElementId列表
    """
    return GetNodeId(session, "BlockingSubstitution")

@register_func(name="Nonblocking")
def Nonblocking(session):
    """
    获取所有的Nonblocking节点
    :param session: 数据库会话
    :return: Nonblocking节点ElementId列表
    """
    return GetNodeId(session, "NonblockingSubstitution")

@register_func(name="Assign")
def Assign(session):
    """
    获取所有的Assign节点
    :param session: 数据库会话
    :return: Assign节点ElementId列表
    """
    return GetNodeId(session, "Assign")

@register_func(name="Switch")
def Switch(session):
    """
    获取所有的Switch节点
    :param session: 数据库会话
    :return: Switch节点ElementId列表
    """
    return GetNodeId(session, "CaseStatement")

@register_func(name="Variable")
def Variable(session):
    """
    获取所有的声明信号的名称
    :param session: 数据库会话
    :return: 声明信号的名称列表
    """
    query = """
        MATCH (m)
        WHERE m.name = 'Input' OR m.name = 'Output' OR m.name = 'Wire' OR m.name = 'Reg' OR m.name = 'Logic'
        RETURN DISTINCT m.label AS label_value
    """
    result = session.run(query)
    values = [record["label_value"] for record in result]
    return values

@register_func(name="SensVar")
def SensVar(session, id):
    """
    获取所有的敏感变量
    :param session: 数据库会话
    :param id: Always节点ID
    :return: 敏感变量列表
    """
    query = f"""
        MATCH (n)
        WHERE elementId(n) = $id
        MATCH path = (n)-[:AST*0..]->(m)
        UNWIND nodes(path) AS node
        WHERE node.label IS NOT NULL
        RETURN DISTINCT node.label AS label_value
    """
    result = session.run(query, id=id)
    values = [record["label_value"] for record in result]
    return values

@register_func(name="SensEdge")
def SensEdge(session, id):
    """
    获取所有敏感变量的敏感边
    :param session: 数据库会话
    :param id: Always节点ID
    :return: 敏感变量与敏感边的字典
    """
    posedge_ids = ASTOffspring(session, id, "posedge")
    negedge_ids = ASTOffspring(session, id, "negedge")

    query = f"""
        MATCH (n)
        WHERE elementId(n) = $edge_id
        MATCH (n)-[:AST*0..]->(m)
        WHERE m.label IS NOT NULL
        RETURN DISTINCT m.label AS label_value
    """
    posedge_dict = {}
    negedge_dict = {}
    if len(posedge_ids) != 0:
        result = session.run(query, edge_id=posedge_ids[0])
        posedge_dict = [{record["label_value"]: 'posedge'} for record in result]
    if len(negedge_ids) != 0:
        result = session.run(query, edge_id=negedge_ids[0])
        negedge_dict = [{record["label_value"]: 'negedge'} for record in result]
    return posedge_dict + negedge_dict

@register_func(name="ConditionVar")
def ConditionVar(session, id):
    """
    获取条件变量
    :param session: 数据库会话
    :param id: If节点ID
    :return: 条件变量列表
    """
    query = f"""
        MATCH (n)
        WHERE elementId(n) = $id
        MATCH path = (n)-[:AST*0..]->(m)
        WHERE m.name = 'Identifier'
        RETURN DISTINCT m.label AS label_value
    """
    result = session.run(query, id=id)
    values = [record["label_value"] for record in result]
    return values

@register_func(name="BranchWhenVarTrue")
def BranchWhenVarTrue(session, id, var):
    """
    获取条件变量为真的分支
    :param session: 数据库会话
    :param id: If节点ID
    :param var: 条件变量
    :return: 条件变量为真的分支列表
    """
    query = f"""
        MATCH path = (n:IfStatement)-[r:AST*]->(m)
        WHERE elementId(n) = $id AND m.label CONTAINS $var
        RETURN 
            size([nn IN nodes(path) WHERE nn.name CONTAINS 'not']) AS notNodeCount,
            path IS NOT NULL AS pathExists
    """
    result = session.run(query, id=id, var=var)
    record = result.single()
    if not record:
        print("BranchWhenVarTrue:", False, 0)
        return []
    exists = record["pathExists"]
    not_count = record["notNodeCount"]
    print("BranchWhenVarTrue:", exists, not_count)
    if exists:
        flag = True if not_count % 2 == 0 else False
        branches = GetBranch(session, id, 'true' if flag else 'false')
        return branches
    else:
        return []

@register_func(name="GetBranch")
def GetBranch(session, id, condition):
    """
    获取指定If节点的分支
    :param session: 数据库会话
    :param id: If节点ID
    :param condition: 分支条件
    :return: 分支节点列表
    """
    query = f"""
        MATCH (n)-[r:CFG]->(m)
        WHERE elementId(n) = $id AND r.condition = $condition
        RETURN DISTINCT elementId(m) AS node_id
    """
    result = session.run(query, id=id, condition=condition)
    node_ids = [record["node_id"] for record in result]
    print("GetBranch:", node_ids)
    return node_ids if len(node_ids) else [[]]

# @register_func(name="TrueBranch")
# def TrueBranch(session, id):
#     """
#     获取条件为真的分支
#     :param session: 数据库会话
#     :param id: If节点ID
#     :return: 条件为真的执行的分支语句节点列表
#     """
#     return GetBranch(session, id, 'true')

# @register_func(name="FalseBranch")
# def FalseBranch(session, id):
#     """
#     获取条件为假的分支
#     :param session: 数据库会话
#     :param id: If节点ID
#     :return: 条件为假的执行的分支语句节点列表
#     """
#     return GetBranch(session, id, 'false')

# def ConditionVar(id):
#     """
#     获取条件变量
#     :param id: For节点ID
#     :return: 条件变量列表
#     """
#     return ConditionVar(id)
@register_func(name="LoopWhenVarTrue")
def LoopWhenVarTrue(session, id, var):
    """
    获取条件变量为真的循环
    :param session: 数据库会话
    :param id: For节点ID
    :param var: 条件变量
    :return: 条件变量为真的循环列表
    """
    pass

@register_func(name="LoopStatement")
def LoopStatement(session, id):
    """
    获取循环语句
    :param session: 数据库会话
    :param id: For节点ID
    :return: 循环语句列表
    """
    return GetBranch(session, id, 'true')

@register_func(name="DriverVar")
def DriverVar(session, id):
    """
    获取驱动变量
    :param session: 数据库会话
    :param id: 赋值节点(Nonblocking/Blocking/Assign)ID
    :return: 驱动变量列表
    """
    query = f"""
        MATCH (n)-[r:AST]->(m)
        WHERE elementId(n) = $id AND r.condition = 'left'
        MATCH (m)-[:AST*0..]->(m2)
        WHERE m2.name = 'Identifier'
        RETURN DISTINCT m2.label AS label_value
    """
    result = session.run(query, id=id)
    values = [record["label_value"] for record in result]
    print("DriverVar:", values)
    # print("DriverVar:", values[0] if len(values) else None)
    return values[0] if len(values) else []

@register_func(name="LoadVar")
def LoadVar(session, id):
    """
    获取加载变量
    :param session: 数据库会话
    :param id: 赋值节点(Nonblocking/Blocking/Assign)ID
    :return: 加载变量列表
    """
    query = f"""
        MATCH (n)-[r:AST]->(m)
        WHERE elementId(n) = $id AND r.condition = 'right'
        MATCH (m)-[:AST*0..]->(m2)
        WHERE m2.name = 'Identifier'
        RETURN DISTINCT m2.label AS label_value
    """
    result = session.run(query, id=id)
    values = [record["label_value"] for record in result]
    return values if len(values) else []

@register_func(name="LoadValue")
def LoadValue(session, id):
    """
    获取加载值
    :param session: 数据库会话
    :param id: 赋值节点(Nonblocking/Blocking/Assign)ID
    :return: 加载值列表
    """
    query = f"""
        MATCH (n)-[r:AST]->(m)
        WHERE elementId(n) = $id AND r.condition = 'right'
        MATCH (m)-[:AST*0..]->(m2)
        WHERE m2.name = 'IntConst'
        RETURN DISTINCT m2.value AS label_value
    """
    result = session.run(query, id=id)
    values = [record["label_value"] for record in result]
    return values[0] if len(values) else []

@register_func(name="ChildAST")
def ChildAST(session, id, direction):
    """
    获取AST子树
    :param session: 数据库会话
    :param id: 赋值节点(Nonblocking/Blocking/Assign)ID
    :param direction: 子树方向(left/right)
    :return: 子树节点
    """
    query = f"""
        MATCH (n)
        WHERE elementId(n) = $id
        MATCH (n)-[r:AST]->(m)
        WHERE r.condition = $direction
        RETURN elementId(m) AS node_id
    """
    result = session.run(query, id=id, direction=direction)
    node_ids = [record["node_id"] for record in result]
    return node_ids[0] if len(node_ids) else None

@register_func(name="LeftAST")
def LeftAST(session, id):
    """
    获取AST左子树
    :param session: 数据库会话
    :param id: 赋值节点(Nonblocking/Blocking/Assign)ID
    :return: 左子树节点
    """
    return ChildAST(session, id, 'left')

@register_func(name="RightAST")
def RightAST(session, id):
    """
    获取AST右子树
    :param session: 数据库会话
    :param id: 赋值节点(Nonblocking/Blocking/Assign)ID
    :return: 右子树节点
    """
    return ChildAST(session, id, 'right')

@register_func(name="Case")
def Case(session, id):
    """
    获取非default的Case节点
    :param session: 数据库会话
    :param id: Switch节点ID
    :return: Case节点列表
    """
    query = f"""
        MATCH (n)
        WHERE elementId(n) = $id
        MATCH path = (n)-[:CFG*0..]->(m)
        WHERE m.name = 'Case' AND (m)-[:AST]->()
        RETURN DISTINCT elementId(m) AS node_id
    """
    result = session.run(query, id=id)
    node_ids = [record["node_id"] for record in result]
    return node_ids

@register_func(name="CaseCount")
def CaseCount(session, id):
    """
    获取Case节点数量
    :param session: 数据库会话
    :param id: Switch节点ID
    :return: Case节点数量
    """
    return len(Case(session, id))

@register_func(name="TestExpression")
def TestExpression(session, id):
    """
    获取Switch节点的测试表达式
    :param session: 数据库会话
    :param id: Switch节点ID
    :return: 测试表达式列表
    """
    query = f"""
        MATCH (n)
        WHERE elementId(n) = $id
        MATCH path = (n)-[:AST*0..]->(m)
        WHERE m.name = 'Identifier'
        RETURN DISTINCT m.label AS label_value
    """
    result = session.run(query, id=id)
    values = [record["label_value"] for record in result]
    return values[0] if len(values) else None

@register_func(name="Default")
def Default(session, id):
    """
    获取默认的表达式
    :param session: 数据库会话
    :param id: Switch节点ID
    :return: 默认表达式
    """
    query = f"""
        MATCH (n)-[r:CFG]->(m)
        WHERE elementid(n) = $id AND m.name = "Case"
        MATCH (m)
        WHERE not (m)-[:AST]->()
        RETURN elementid(m) as node_id
    """
    result = session.run(query, id=id)
    values = [record["node_id"] for record in result]
    return values[0] if len(values) else None


@register_func(name="DriverStatement")
def DriverStatement(session, variable_name, node_type):
    """
    获取驱动变量的赋值语句
    :param session: 数据库会话
    :param variable_name: 驱动变量名称
    :return: 赋值语句列表
    """
    if node_type in node_names:
        node_type = node_names[node_type]
    if node_type == "BlockingSubstitution":
        assign_node_ids = Blocking(session)
    elif node_type == "NonblockingSubstitution":
        assign_node_ids = Nonblocking(session)
    elif node_type == "Assign":
        assign_node_ids = Assign(session)
    else:
        assign_node_ids = Assign(session) + Blocking(session) + Nonblocking(session)

    print("DriverStatement Before:",variable_name, node_type, assign_node_ids)
    node_ids = []
    for node_id in assign_node_ids:
        driver_variable = DriverVar(session, node_id)
        if driver_variable == variable_name:
            node_ids.append(node_id)
    print("DriverStatement After:",variable_name, node_type, node_ids)
    return node_ids

@register_func(name="LoadStatement")
def LoadStatement(session, variable_name, node_type):
    """
    获取装载变量的赋值语句
    :param session: 数据库会话
    :param variable_name: 驱动变量名称
    :return: 赋值语句列表
    """
    query = f"""
        MATCH path = (n)-[:AST*0..]->(m)
        WHERE n.name = 'Decl' AND m.label = $variable_name
        MATCH (n)-[:DDG]->(m2)
        WHERE m2.name = $node_type
        RETURN DISTINCT elementId(m2) AS node_id
    """ 
    if node_type in node_names:
        node_type = node_names[node_type]
    result = session.run(query, variable_name=variable_name, node_type=node_type)
    node_ids = [record["node_id"] for record in result]
    return node_ids

@register_func(name="Dimension")
def Dimension(session, variable_name):
    """
    获取变量的维度
    :param session: 数据库会话
    :param variable_name: 变量名称
    :return: 变量维度列表
    """
    query = f"""
        MATCH path = (n)-[:AST*0..]->(m)
        WHERE n.name = 'Decl' AND m.label = $variable_name
        MATCH (m)-[:AST]->(dim)
        WHERE dim.name = 'Dims'
        MATCH (dim)-[:AST]->(width)
        RETURN count(width) AS dim_num
    """
    result = session.run(query, variable_name=variable_name)
    values = [int(record["dim_num"]) for record in result]
    return (values[0] if len(values) else 0) + 1

@register_func(name="Length")
def Length(session, variable_name):
    """
    获取变量的总bit数
    :param session: 数据库会话
    :param variable_name: 变量名称
    :return: 变量总长度
    """
    sum = 1
    query = f"""
        MATCH path = (n)-[:AST*0..]->(m)
        WHERE n.name = 'Decl' AND m.label = $variable_name
        MATCH (m)-[:AST]->(width)
        WHERE width.name = 'Width'
        MATCH (width)-[:AST]->(const)
        WHERE const.name = 'IntConst'
        RETURN const.value AS const_value
    """
    result = session.run(query, variable_name=variable_name)
    values = [int(record["const_value"]) for record in result]
    if not values:
        return sum
    else:
        sum *= max(values) - min(values) + 1

    if Dimension(session, variable_name) == 1:
        return sum
    
    query2 = f"""
        MATCH path = (n)-[:AST*0..]->(m)
        WHERE n.name = 'Decl' AND m.label = $variable_name
        MATCH (m)-[:AST]->(dim)
        WHERE dim.name = 'Dims'
        MATCH (dim)-[:AST]->(width)
        WHERE width.name = 'Width'
        RETURN DISTINCT elementId(width) AS node_id
    """
    result = session.run(query2, variable_name=variable_name)
    width_ids = [record["node_id"] for record in result]

    for width_id in width_ids:
        query3 = f"""
            MATCH (width)-[:AST]->(const)
            WHERE elementId(width) = $width_id AND const.name = 'IntConst'
            RETURN const.value AS const_value
        """
        result = session.run(query3, width_id=width_id)
        values = [int(record["const_value"]) for record in result]
        if not values:
            return sum
        else:
            sum *= max(values) - min(values) + 1

    return sum

@register_func(name="StateSum")
def StateSum(session, variable_name):
    """
    获取变量的状态总数
    :param session: 数据库会话
    :param variable_name: 变量名称
    :return: 变量状态总数
    """
    return 2 ** Length(session, variable_name)

@register_func(name="CaseCountNotEqualStateNum")
def CaseCountNotEqualStateNum(session, id):
    """
    判断Case数量是否等于状态总数
    :param session: 数据库会话
    :param id: Switch节点ID
    :return: True/False
    """
    case_count = CaseCount(session, id)
    state_sum = StateSum(session, TestExpression(session, id))
    print("case_count:", case_count,", state_sum:", state_sum)
    return case_count != state_sum

@register_func(name="LoadBeforeDriver")
def LoadBeforeDriver(session, variable_name):
    query = f"""
        MATCH path = (n)-[r1:AST*0..]->(m)
        WHERE n.name = 'Decl' AND m.label = $variable_name
        MATCH (n)-[r2:DDG]->(m2)
        WHERE m2.name = 'BlockingSubstitution'
        MATCH (m2)-[r3:DDG]->(m3)-[r4:AST]->(m4)
        WHERE m3.name = 'BlockingSubstitution' AND r4.condition='left' AND m4.label = $variable_name
        RETURN DISTINCT elementId(m2) AS node_id
    """
    print("LoadBeforeDriver: ", variable_name)
    result = session.run(query, variable_name=variable_name)
    node_ids = [record["node_id"] for record in result]
    return node_ids[0] if len(node_ids) else None