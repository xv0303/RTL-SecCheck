# traversal_engine.py
import copy

class TraversalEngine:
    def __init__(self, session, function_registry):
        """
        graph: 图结构（可以是字典或其他容器）
        function_registry: {'FuncName': function} 的映射表
        """
        self.session = session#GraphDatabase.driver(uri, auth=(username, password))
        self.funcs = function_registry
        self.exec_counter = 0
        self.singleparam_func=[
            "Switch",
            "Variable"
        ]

    def execute(self, func_obj, current_node=None):
        print(f"Executing function: {func_obj['Func']}")
        func_name = func_obj['Func']
        params = copy.deepcopy(func_obj.get('Params', []))
        print(f"Params: {params}")
        filter_obj = func_obj.get('Filter')

        # 找到对应函数
        if func_name not in self.funcs:
            raise ValueError(f"Function {func_name} not registered.")
        
        # 如果参数中存在路径或数组
        if isinstance(params, list):
            # 如果参数是列表，可能包含路径或其他函数
            for i, param in enumerate(params):
                if isinstance(param, dict) and 'Func' in param:
                    # 如果参数是函数对象，执行函数
                    params[i] = self.execute(copy.deepcopy(param), current_node)
                elif isinstance(param, dict) and 'Path' in param:
                    # 如果参数是列表并且内容全是函数对象，可能是路径，执行路径
                    params[i] = self.execute_path(copy.deepcopy(param), current_node)

        print(f"Current node: {current_node}, Params: {params}")
        if current_node is not None:
            # 如果有当前节点，传递给函数
            params = current_node if current_node is list else [current_node] + params

        # 执行函数
        print("params:", params)
        if(func_name in self.singleparam_func):
            params = []
        result = self.funcs[func_name](self.session, *params)
        self.exec_counter += 1

        # 如果有Filter，应用过滤器
        if filter_obj and filter_obj != "None":
            result = self.apply_filter(result, filter_obj)
        
        return result

    def apply_filter(self, nodes, filter_obj):
        # 把nodes统一转换成list
        if not isinstance(nodes, list):
            nodes = [nodes] if nodes else []

        # 获取过滤器属性
        operator = filter_obj['Operator']
        conditions = filter_obj['Condition']

        filtered = []
        # 遍历所有节点，应用过滤器
        for node in nodes:
            condition_results = []

            # 遍历所有条件，执行
            for condition in conditions:
                # 如果条件是一个列表，表示路径，执行路径；否则就是函数，执行函数
                if 'Path' in condition:
                    result = self.execute_path(condition, node)
                else:
                    result = self.execute(condition, node)

                condition_results.append(result)

            if self.combine_condition_results(condition_results, operator):
                filtered.append(node)

        return filtered

    def execute_path(self, path, start_node):
        print(f"Executing path: {path}")
        nodes = [start_node]  # 初始化为包含起始节点的列表
        path_steps = path['Path']
        
        for step in path_steps:
            print(f"Step: {step}")
            next_nodes = []  # 用于存储下一步的节点
            
            for node in nodes:
                result = self.execute(step, node)
                
                # 如果结果不是数组，将其改为数组
                if not isinstance(result, list):
                    result = [result]
                
                # 如果结果是数组且数组内为布尔值，只要有一个为真就返回真
                if all(isinstance(item, bool) for item in result):
                    if any(result):
                        return True
                    else:
                        continue  # 跳过当前节点
                
                # 如果结果是数组且数组内为node的ID或变量名称，将其加入下一步的节点列表
                elif all(isinstance(item, (int, str)) for item in result):  # 假设node的ID是int或str
                    next_nodes.extend(result)
                
                else:
                    # 如果结果是其他类型，抛出异常或处理为False
                    print(f"Unexpected result type: {type(result)}")
                    next_nodes.append([])
                    # return False
            
            # 更新当前节点列表为下一步的节点列表
            nodes = next_nodes
        
        if len(nodes):
            # return True
            return nodes
        # 如果路径执行完毕且没有返回True，则返回False
        return False

    def combine_condition_results(self, results, operator):
        print(f"Combining condition results with operator {operator}: {results}")
        if operator == "AND":
            return all(results)
        elif operator == "OR":
            return any(results)
        else:
            raise ValueError(f"Unsupported operator: {operator}")
