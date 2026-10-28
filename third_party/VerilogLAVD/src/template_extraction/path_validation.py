from autogen import ConversableAgent
from autogen import register_function
from fsm import FiniteStateMachine
from rag import TraversalFunctionDB
from typing import List

max_tokens = 16384

myfsm = None
tfDB = TraversalFunctionDB()

def paths_validate(traversal_primitives:List[str])-> str:
    global myfsm
    if myfsm is None:
        myfsm = FiniteStateMachine()

    return myfsm.paths_validation(traversal_primitives)

def path_validation(constrain_path):

    assistant = ConversableAgent(
        name="Assistant",
        system_message="""
你现在是最专业的硬件安全工程师，擅长Verilog代码的静态漏洞分析。
你需要根据包含VeriPG关键词节点的Verilog漏洞约束, 结合VeriPG的遍历原语构造出漏洞遍历模板，这个漏洞遍历模板将会用于在VeriPG中进行检索。
"""
        "Return 'TERMINATE' when the task is done.",
        llm_config={"temperature": 0 ,"config_list": [{"model": model, "api_key": api_key, "base_url": base_url}],"cache_seed": None, "max_tokens": max_tokens},
    )
    user_proxy = ConversableAgent(
        name="User",
        llm_config=False,
        is_termination_msg=lambda msg: msg.get("content") is not None and "TERMINATE" in msg["content"],
        human_input_mode="NEVER",
        code_execution_config={"work_dir": "coding", "use_docker": False},
    )

    register_function(
        paths_validate,  # The function to be registered as a tool.
        caller=assistant,  # The assistant agent can suggest calls to the calculator.
        executor=user_proxy,  # The user proxy agent can execute the calculator calls.
        name="path_validate",  # By default, the function name is used as the tool name.
        description="一个验证使用的遍历原语是否合法的python工具，输入参数traversal_primitives为多个VeriPG遍历原语的名称组成的数组，执行多步遍历原语的验证，返回验证结果和当前状态信息。",  # A description of the tool.
    )

    travesal_function=tfDB.query_function(constrain_path)

    with open("prompt_path_validation.txt", "r") as file:
        prompt = file.read()
        prompt = prompt.replace("{traversal_function}", travesal_function).replace("{constrain_path}", constrain_path)
        chat_result = user_proxy.initiate_chat(assistant, message=prompt)

    return chat_result.chat_history[-1].get("content", "")

import os,sys

def path_validation_prompt(constrain_path):

#     assistant = ConversableAgent(
#         name="Assistant",
#         system_message="""
# 你现在是最专业的硬件安全工程师，擅长Verilog代码的静态漏洞分析。
# 你需要根据包含VeriPG关键词节点的Verilog漏洞约束, 结合VeriPG的遍历原语构造出漏洞遍历模板，这个漏洞遍历模板将会用于在VeriPG中进行检索。
# """
#         "Return 'TERMINATE' when the task is done.",
#         llm_config={"temperature": 0 ,"config_list": [{"model": model, "api_key": api_key, "base_url": base_url}],"cache_seed": None, "max_tokens": max_tokens},
#     )
#     user_proxy = ConversableAgent(
#         name="User",
#         llm_config=False,
#         is_termination_msg=lambda msg: msg.get("content") is not None and "TERMINATE" in msg["content"],
#         human_input_mode="NEVER",
#         code_execution_config={"work_dir": "coding", "use_docker": False},
#     )

#     register_function(
#         paths_validate,  # The function to be registered as a tool.
#         caller=assistant,  # The assistant agent can suggest calls to the calculator.
#         executor=user_proxy,  # The user proxy agent can execute the calculator calls.
#         name="path_validate",  # By default, the function name is used as the tool name.
#         description="一个验证使用的遍历原语是否合法的python工具，输入参数traversal_primitives为多个VeriPG遍历原语的名称组成的数组，执行多步遍历原语的验证，返回验证结果和当前状态信息。",  # A description of the tool.
#     )

    travesal_function=tfDB.query_function(constrain_path)
    prompt_path_validation_file = os.path.abspath(os.path.join(os.path.dirname(__file__), 'prompt_path_validation.txt'))
    with open(prompt_path_validation_file, "r") as file:
        prompt = file.read()
        prompt = prompt.replace("{traversal_function}", travesal_function).replace("{constrain_path}", constrain_path)

    return prompt