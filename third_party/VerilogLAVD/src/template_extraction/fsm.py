class FiniteStateMachine:
    def __init__(self):
        self.current_states = []
        self.transitions = {
            'DeclVars': {
                'AST': ['Input', 'Output', 'Reg', 'Wire'],
                'DDG': ['Always', 'If', 'For', 'Switch', '<=']
            },
            'Input': {
                'AST': ['Width']
            },
            'Output': {
                'AST': ['Width']
            },
            'Reg': {
                'AST': ['Width']
            },
            'Wire': {
                'AST': ['Width']
            },
            'Width': {
                'AST': ['IntConst']
            },
            'IntConst': {},
            'Assign': {
                'AST': ['Identifier', 'Land', 'Lor', 'Unot', 'IntConst']
            },
            'Entry': {
                'CFG': ['Always']
            },
            'Always': {
                'AST': ['SensList'],
                'CFG': ['If', '<=', '=']
            },
            'SensList': {
                'AST': ['Sens']
            },
            'Sens': {
                'AST': ['Identifier']
            },
            'Identifier': {},
            'If': {
                'AST': ['Land', 'Lor', 'Unot', 'Identifier', 'IntConst'],
                'CFG': ['If', 'For', 'Switch', '<=', '=']
            },
            'For':{
                'AST': ['Land', 'Lor', 'Unot', 'Identifier', 'IntConst'],
                'CFG': ['If', 'For', 'Switch', '<=', '=']
            },
            'Switch': {
                'AST': ['Land', 'Lor', 'Unot', 'Identifier', 'IntConst'],
                'CFG': ['Case', 'Default', 'If', 'For', 'Switch', '<=', '=']
            },
            'Case': {
                'AST': ['Land', 'Lor', 'Unot', 'Identifier', 'IntConst'],
                'CFG': ['If', 'For', 'Switch', '<=', '=']
            },
            '<=': {
                'AST': ['Identifier', 'Land', 'Lor', 'Unot', 'IntConst'],
                'CFG': ['If', 'For', 'Switch', '<=', '=']
            },
            '=': {
                'AST': ['Identifier', 'Land', 'Lor', 'Unot', 'IntConst'],
                'CFG': ['If', 'For', 'Switch', '<=', '=']
            },
            'Land': {
                'AST': ['Land', 'Lor', 'Unot', 'Identifier', 'IntConst']
            },
            'Lor': {
                'AST': ['Land', 'Lor', 'Unot', 'Identifier', 'IntConst']
            },
            'Unot': {
                'AST': ['Land', 'Lor', 'Unot', 'Identifier', 'IntConst']
            }
        }

        self.state_descriptions = {
            'DeclVars': '信号声明节点。可以通过AST边连接到Input、Output、Reg、Wire节点，可以通过DPG边连接到Always、If、<=节点。',
            'Input': '声明的输入信号节点，包含信号名称属性。可以通过AST边连接到Width节点。',
            'Output': '声明的输出信号节点，包含信号名称属性。可以通过AST边连接到Width节点。',
            'Reg': '声明的寄存器节点，包含信号名称属性。可以通过AST边连接到Width节点。',
            'Wire': '声明的线节点，包含信号名称属性。可以通过AST边连接到Width节点。',
            'Width': '描述信号长度的节点，长度大于1的信号才具备此子节点。可以通过AST边连接到IntConst节点。',
            'IntConst': '整数数值节点，包含具体整数数值属性。叶节点。',
            'Assign': '过程块外连续的赋值节点。可以通过AST边连接到左值的Identifier和右值的Land、Lor、Unot、Identifier、IntConst节点。',
            'Entry': '控制流入口节点，每个always过程块都有一个入口节点。直接可以通过CFG边连接到Always节点。',
            'Always': '过程块节点。可以通过AST边连接到SensList节点，可以通过CFG边连接到If、<=、=节点。',
            'SensList': 'Always敏感列表节点。可以通过AST边连接到Sens节点。',
            'Sens': '敏感信号节点，包含敏感信号触发沿属性，如posedge或negedge。可以通过AST边连接到Identifier节点。',
            'Identifier': '信号名称标识节点，包含信号名称属性。叶节点。',
            'If': '过程块内的分支节点。可以通过AST边连接到Land、Lor、Unot、Identifier、IntConst节点，可以通过CFG边连接到If、For、Switch、<=、=节点。',
            '<=': '过程块内的非阻塞赋值节点。可以通过AST边连接到左值的Identifier和右值的Land、Lor、Unot、Identifier、IntConst节点，可以通过CFG边连接到If、<=、=节点。',
            '=': '过程块内的阻塞赋值节点。可以通过AST边连接到左值的Identifier和右值的Land、Lor、Unot、Identifier、IntConst节点，可以通过CFG边连接到If、<=、=节点。',
            'Land': '逻辑“与”节点。可以通过AST边连接到Land、Lor、Unot、Identifier、IntConst节点。',
            'Lor': '逻辑"或"节点。可以通过AST边连接到Land、Lor、Unot、Identifier、IntConst节点。',
            'Unot': '逻辑"非"节点。可以通过AST边连接到Land、Lor、Unot、Identifier、IntConst节点。',
            'For': '过程块内的循环节点。可以通过AST边连接到Land、Lor、Unot节点，可以通过CFG边连接到If、For、Switch、<=、=节点。',
            'Switch': '过程块内的多分支选择节点。可以通过AST边连接到Land、Lor、Unot节点，可以通过CFG边连接到Case、Default、If、For、Switch、<=、=节点。',
            'Case': 'Switch节点下的单个分支节点。可以通过AST边连接到Land、Lor、Unot节点，可以通过CFG边连接到If、For、Switch、<=、=节点。',
            'Default': 'Switch节点下的默认分支节点。可以通过AST边连接到Land、Lor、Unot节点，可以通过CFG边连接到If、For、Switch、<=、=节点。',
        }

        self.function_descriptions = {
            "Node": "获取任意指定类型的节点Id，输入为任意节点的类型，输出为对应类型节点Id的列表。",
            "ASTOffspring": "获取指定节点的指定类型后代节点Id，输入为节点ID和后代节点类型，输出为后代节点Id的列表。",
            "CFGOffspring": "获取指定节点的指定类型后代节点Id，输入为节点ID和后代节点类型，输出为后代节点Id的列表。",
            "Equal": "判断两个变量是否相同，输入为变量A和变量B，输出为布尔值。",
            "Exist": "判断列表是否存在，输入为节点ID列表，输出为布尔值。",
            "Count": "计算列表的长度，输入为节点ID列表，输出为长度值。",
            "Has": "判断列表是否包含指定值，输入为列表和值，输出为布尔值。",
            "Always": "获取所有的Always节点，输出为Always节点Id的列表。",
            "If": "获取所有的If节点，输出为If节点Id的列表。",
            "For": "获取所有的For节点，输出为For节点Id的列表。",
            "Blocking": "获取所有的BlockingSubstitution赋值节点,输出为BlockingSubstitution节点Id的列表。",
            "Nonblocking": "获取所有的NonblockingSubstitution赋值节点输出为NonblockingSubstitution节点Id的列表",
            "Assign": "获取所有的Assign赋值节点，输出为Assign赋值节点Id的列表。",
            "Switch": "获取所有的Switch节点，输出为Switch节点Id的列表。",
            "Variable": "获取所有声明信号的名称，输出为声明信号名称的列表。",
            "SensVar": "获取指定Always节点的敏感变量，输入为Always节点ID，输出为敏感变量的列表。",
            "SensEdge": "获取指定Always节点的敏感变量的敏感边，输入为Always节点ID，输出为敏感变量与敏感边的字典。例如({\"clk\": \"posedge\", \"rst\": \"negedge\"})",
            "ConditionVar": "获取指定If节点的条件变量，输入为If节点ID，输出为条件变量的列表。",
            "BranchWhenVarTrue": "获取条件变量为真的分支，输入为If节点ID和条件变量，输出为条件变量为真的分支节点的列表。",
            "GetBranch": "获取指定If节点的True或False分支，输入为If节点ID和分支条件（\"true\"或\"false\"），输出为所有可能分支的节点ID的列表。",
            "LoopWhenVarTrue": "获取条件变量为真的循环，输入为For节点ID和条件变量，输出为条件变量为真的循环节点ID的列表。",
            "LoopStatement": "获取指定For节点的循环语句，输入为For节点ID，输出为循环语句节点ID的列表。",
            "DriverVar": "获取指定赋值类节点的驱动变量(被赋值变量)，输入为赋值节点ID，输出为驱动变量(被赋值变量)的名称。",
            "LoadVar": "获取指定赋值类节点的加载变量(赋值变量)，输入为赋值节点ID，输出为加载变量(赋值变量)的列表。",
            "LoadValue": "获取指定赋值类节点的加载值(赋值的值)，输入为赋值节点ID，输出为加载值(赋值的值)的列表。",
            "ChildAST": "获取指定赋值类节点的AST子树，输入为赋值节点ID和子树方向（\"left\"或\"right\"），输出为子树节点ID。",
            "LeftAST": "获取指定赋值类节点的AST左子树，输入为赋值节点ID，输出为左子树节点ID。",
            "RightAST": "获取指定赋值类节点的AST右子树，输入为赋值节点ID，输出为右子树节点ID。",
            "Case": "获取指定Switch节点的Case节点，输入为Switch节点ID，输出为Case节点ID的列表。",
            "CaseCount": "获取指定Switch节点的Case节点数量，输入为Switch节点ID，输出为Case节点的数量。",
            "TestExpression": "获取指定Switch节点的测试表达式，输入为Switch节点ID，输出为测试表达式的名称。",
            "Default": "获取指定Switch节点的默认表达式，输入为Switch节点ID，输出为默认表达式。",
            "DriverStatement": "获取指定驱动变量的赋值语句，输入为驱动变量名称，输出为赋值语句节点ID的列表。",
            "LoadStatement": "获取指定加载变量的赋值语句，输入为加载变量名称，输出为赋值语句节点ID的列表。",
            "Dimension": "获取指定变量的维度，输入为变量名称，输出为变量的维度值。",
            "Length": "获取指定变量的总bit数，输入为变量名称，输出为变量的总长度。",
            "StateSum": "获取指定变量的状态总数，输入为变量名称，输出为变量的状态总数。"
        }

        self.nontransition_functions = [
            'Equal', 'Exist','Count'
        ]

        self.start_functions=[
            'Always','If','For','Blocking','Nonblocking','Assign','Switch'
        ]

        self.transition_functions = {
            'Node':{
                'Start':[],
                'End':['Always', 'If', 'For', 'Switch', '<=', '=', 'Land', 'Lor', 'Unot', 'Identifier','SensList', 'Sens', 'Input', 'Output', 'Reg', 'Wire', 'Width', 'IntConst'],
                'OutputType': 'Node',
            },
            'Variable': {
                'Start':[],
                'End':['Var'],
                'OutputType': 'VarList',
            },
            'Has':{
                'Start':['Var'],
                'End':['Bool'],
                'OutputType': 'Bool',
            },
            'Dimension':{
                'Start':['Var'],
                'End':['Value'],
                'OutputType': 'Num',
            },
            'Length':{
                'Start':['Var'],
                'End':['Value'],
                'OutputType': 'Num',
            },
            'StateSum':{
                'Start':['Var'],
                'End':['Value'],
                'OutputType': 'Num',
            },
            'SensVar':{
                'Start':['Always'],
                'End':['Var'],
                'OutputType': 'VarList',
            },
            'SensEdge':{
                'start':['Always'],
                'End':['Var'],
                'OutputType': 'EdgeDict',
            },
            'ConditionVar':{
                'Start':['If', 'For'],
                'End':['Var'],
                'OutputType': 'VarList',
            },
            'BranchWhenVarTrue':{
                'Start':['If'],
                'End':['If', 'For', 'Switch', '<=', '='],
                'OutputType': 'Node',
            },
            'GetBranch':{
                'Start':['If'],
                'End':['If', 'For', 'Switch', '<=', '='],
                'OutputType': 'Node',
            },
            'TrueBranch':{
                'Start':['If'],
                'End':['If', 'For', 'Switch', '<=', '='],
                'OutputType': 'Node',
            },
            'FalseBranch':{
                'Start':['If'],
                'End':['If', 'For', 'Switch', '<=', '='],
                'OutputType': 'Node',
            },
            'LoopWhenVarTrue':{
                'Start':['For'],
                'End':['If', 'For', 'Switch', '<=', '='],
                'OutputType': 'Node',
            },
            'LoopStatement':{
                'Start':['For'],
                'End':['If', 'For', 'Switch', '<=', '='],
                'OutputType': 'Node',
            },
            'DriverVar':{
                'Start':['<=', '=', 'Assign'],
                'End':['Var'],
                'OutputType': 'Var',
            },
            'LoadVar':{
                'Start':['<=', '=', 'Assign'],
                'End':['Var'],
                'OutputType': 'VarList',
            },
            'LoadValue':{
                'Start':['<=', '=', 'Assign'],
                'End':['Value'],
                'OutputType': 'ValList',
            },
            'ChildAST':{
                'Start':['<=', '=', 'Assign'],
                'End':['Identifier', 'Land', 'Lor', 'Unot', 'IntConst'],
                'OutputType':'Node'
            },
            'LeftAST':{
                'Start':['<=', '=', 'Assign'],
                'End':['Identifier', 'Land', 'Lor', 'Unot', 'IntConst'],
                'OutputType':'Node'
            },
            'RightAST':{
                'Start':['<=', '=', 'Assign'],
                'End':['Identifier', 'Land', 'Lor', 'Unot', 'IntConst'],
                'OutputType':'Node'
            },
            'Case':{
                'Start':['Switch'],
                'End':['Case'],
                'OutputType':'Node'
            },
            'CaseCount':{
                'Start':['Switch'],
                'End':['Value'],
                'OutputType':'Num'
            },
            'TestExpression':{
                'Start':['Switch'],
                'End':['Var'],
                'OutputType':'Var'
            },
            'Default':{
                'Start':['Switch'],
                'End':['Default'],
                'OutputType':'Node'
            },
            'DriverStatement':{
                'Start':['Var'],
                'End':['<=', '=', 'Assign'],
                'OutputType':'Node'
            },
            'LoadStatement':{
                'Start':['Var'],
                'End':['<=', '=', 'Assign'],
                'OutputType':'Node'
            },
        }

        self.Offspring_transitions = {
            'DeclVars': {
                'AST': ['Input', 'Output', 'Reg', 'Wire', 'Width', 'IntConst'],
                'CFG': [],
                'DDG': ['Always', 'If', 'For', 'Switch', '<=', '=']
            },
            'Input': {
                'AST': ['Width', 'IntConst'],
                'CFG': [],
                'DDG': []
            },
            'Output': {
                'AST': ['Width', 'IntConst'],
                'CFG': [],
                'DDG': []
            },
            'Reg': {
                'AST': ['Width', 'IntConst'],
                'CFG': [],
                'DDG': []
            },
            'Wire': {
                'AST': ['Width', 'IntConst'],
                'CFG': [],
                'DDG': []
            },
            'Width': {
                'AST': ['IntConst'],
                'CFG': [],
                'DDG': []
            },
            'IntConst': {
                'AST': [],
                'CFG': [],
                'DDG': []
            },
            'Assign': {
                'AST': ['Identifier', 'Land', 'Lor', 'Unot', 'IntConst'],
                'CFG': [],
                'DDG': ['Assign']
            },
            'Always': {
                'AST': ['SensList', 'Sens', 'Identifier'],
                'CFG': ['If', 'For', 'Switch','Case', 'Default', '<=', '='],
                'DDG': []
            },
            'SensList': {
                'AST': ['Sens', 'Identifier'],
                'CFG': [],
                'DDG': []
            },
            'Sens': {
                'AST': ['Identifier'],
                'CFG': [],
                'DDG': []
            },
            'Identifier': {
                'AST': [],
                'CFG': [],
                'DDG': []
            },
            'If': {
                'AST': ['Land', 'Lor', 'Unot', 'Identifier', 'IntConst'],
                'CFG': ['If', 'For', 'Switch', 'Case', 'Default', '<=', '='],
                'DDG': []
            },
            'For':{
                'AST': ['Land', 'Lor', 'Unot', 'Identifier', 'IntConst'],
                'CFG': ['If', 'For', 'Switch', 'Case', 'Default', '<=', '='],
                'DDG':[]
            },
            'Switch': {
                'AST': ['Land', 'Lor', 'Unot', 'Identifier', 'IntConst'],
                'CFG': ['Case', 'Default', 'If', 'For', 'Switch', '<=', '='],
                'DDG':[]
            },
            'Case': {
                'AST': ['Land', 'Lor', 'Unot', 'Identifier', 'IntConst'],
                'CFG': ['If', 'For', 'Switch','Case', 'Default', '<=', '='],
                'DDG':[]
            },
            '<=': {
                'AST': ['Identifier', 'Land', 'Lor', 'Unot', 'IntConst'],
                'CFG': ['If', 'For', 'Switch','Case', 'Default', '<=', '='],
                'DDG':['<=', '=']
            },
            '=': {
                'AST': ['Identifier', 'Land', 'Lor', 'Unot', 'IntConst'],
                'CFG': ['If', 'For', 'Switch','Case', 'Default', '<=', '='],
                'DDG':['<=', '=']
            },
            'Land': {
                'AST': ['Land', 'Lor', 'Unot', 'Identifier', 'IntConst'],
                'CFG':[],
                'DDG':[]
            },
            'Lor': {
                'AST': ['Land', 'Lor', 'Unot', 'Identifier', 'IntConst'],
                'CFG':[],
                'DDG':[]
            },
            'Unot': {
                'AST': ['Land', 'Lor', 'Unot', 'Identifier', 'IntConst'],
                'CFG':[],
                'DDG':[]
            }
        }

    def get_state_info(self):
        """获取当前状态的描述信息"""
        if self.current_states is None:
            return "当前未设置任何状态"
        
        msg = ""
        for state in self.current_states:
            msg += f"当前可能节点 [{state}]: {self.state_descriptions.get(state, '未知状态')}\n"
        return msg

    def set_state(self, state):
        """设置当前状态，并输出状态信息"""
        if state in self.transitions:
            self.current_state = state
            print(self.get_state_info())  # 新增：设置状态时自动输出
            return True
        else:
            print(f"错误：无效状态 {state}")
            return False
    
    def can_transition(self, edge_type, next_state):
        """检查是否可以进行转移"""
        if self.current_state is None:
            return False
        current_trans = self.transitions.get(self.current_state, {})
        allowed_states = current_trans.get(edge_type, [])
        return next_state in allowed_states

    def do_transition(self, edge_type, next_state):
        """执行状态转移，转移成功后输出新状态信息"""
        if self.can_transition(edge_type, next_state):
            self.current_state = next_state
            print(self.get_state_info())  # 新增：转移成功后自动输出
            return True
        else:
            print(f"错误：无法通过 {edge_type} 边从 {self.current_state} 转移到 {next_state}")
            return False
        
    def path_validatation(self, transition_function):
        next_states = []
        if transition_function in self.transition_functions:
            # 输入为状态转移函数

            current_function = self.transition_functions[transition_function]

            # 判断状态转移函数的起始是否有要求
            if current_function['Start'] != []:
                for current_state in self.current_states:
                # 检查当前状态是否在起始状态列表中
                    if current_state in current_function['Start']:
                        next_states.extend(current_function['End'])
            else:
                # 如果没有起始状态要求，则直接执行转移
                next_states = current_function['End']
            next_states = list(set(next_states))
            if len(next_states) == 0:
                return f"可能的当前状态：{self.current_states}。遍历原语{transition_function}验证失败：原因为没有可用的转移状态。使用的遍历详情: {self.function_descriptions[transition_function]}"
            else:
                self.current_states = next_states
                return f"可能的当前状态：{next_states}。遍历原语{transition_function}验证成功。"
        else:
            if transition_function == 'ASTOffspring':
                for current_state in self.current_states:
                    next_states.extend(self.Offspring_transitions.get(current_state, {}).get('AST', []))
                next_states = list(set(next_states))
            elif transition_function == 'CFGOffspring':
                for current_state in self.current_states:
                    next_states.extend(self.Offspring_transitions.get(current_state, {}).get('CFG', []))
                next_states = list(set(next_states))
            elif transition_function in self.start_functions:
                next_states.append(transition_function)
                if next_states == 'Blocking':
                    next_states = ['=']
                if next_states == 'Nonblocking':
                    next_states = ['<=']
            elif transition_function in self.nontransition_functions:
                next_states = self.current_states
            else:
                return f"遍历原语验证失败：{transition_function}是错误的转移方法"

            if len(next_states) == 0:
                return f"可能的当前状态：{self.current_states}。遍历原语{transition_function}验证失败：原因为没有可用的转移状态。使用的遍历详情: {self.function_descriptions[transition_function]}"
            else:
                self.current_states = next_states
                return f"可能的当前状态：{next_states}。遍历原语{transition_function}验证成功。"
        
    def paths_validation(self, traversal_primitives):
        """验证一系列遍历原语"""
        results = ""
        self.current_states=[]
        for primitive in traversal_primitives:
            result = self.path_validatation(primitive)
            results+=result+"\n"
        return results

if __name__ == "__main__":
    # 初始化状态机
    fsm = FiniteStateMachine()

    result = fsm.paths_validation(["Node", "ASTOffspring", "CFGOffspring", "Equal", "Equal"])

    print(result)