import openai
import os
import json
import re

max_tokens = 16384
temperature = 0.5

constrain_prompt_file="prompt_constrain2.txt"
constrain_path_prompt_file="prompt_constrain_path.txt"


def load_template(template_path):
    with open(template_path, "r", encoding="utf-8") as file:
        return file.read()
    return ""

def generate_constrain_prompt(cwe_describe):
    prompt_tempate = load_template(constrain_prompt_file)
    prompt = prompt_tempate.format(cwe_describe=cwe_describe)
    return prompt

def generate_constrain_path_prompt(cwe_constrain):
    prompt_tempate = load_template(constrain_path_prompt_file)
    prompt = prompt_tempate.format(cwe_constrain=cwe_constrain)
    return prompt

def get_llm_response(prompt):
    response = openai.chat.completions.create(
        model=model_name,
        messages=[{"role": "user","content": prompt}],
        max_tokens=max_tokens,
        temperature=temperature,
    )
    return response.choices[0].message.content

def generate_constrain_path(cwe_describe):
    # 1. 根据CWE漏洞描述生成对应约束
    constrain_prompt = generate_constrain_prompt(cwe_describe)
    print("constrain prompt: \n",constrain_prompt)
    constrain_response = get_llm_response(constrain_prompt)
    print("constrain: \n",constrain_response)
    
    # 2. 将约束转换为VeriPG的约束路径
    constrain_path_promt = generate_constrain_path_prompt(constrain_response)
    print("constrain path prompt: \n",constrain_response)
    constrain_path_response = get_llm_response(constrain_path_promt)
    print("constrain path: \n",constrain_path_response)

    return constrain_path_response

if __name__ == "__main__":
    cweid = "1314"
    if os.path.exists("../../cwe_content.json"):
        with open("../../cwe_content.json", "r", encoding="utf-8") as file:
            cwe_content = json.load(file)[cweid]
            cwe_content = cwe_content.split("Demonstrative Examples")[0]
            # print(cwe_content)
    prompt = generate_constrain_prompt(cwe_content)
    print(prompt)
    print(get_llm_response(prompt))

# if __name__ == "__main__":
    
#     cweids = ["226","1231","1232","1234","1243","1244","1245","1255","1258","1262","1271","1280","1282","1298","1300","1314"]
#     if os.path.exists("../../cwe_content.json"):
#         with open("../../cwe_content.json", "r", encoding="utf-8") as file:
#             cwe_content = json.load(file)
#             for cweid in cweids:
#                 cwe_describe = cwe_content.get(cweid)
#                 constrain_path = generate_constrain_path(cwe_describe)
#                 print("Generated Constrain Path:")
#                 print(constrain_path)

# if __name__ == "__main__":
#     # cweids = ["226", "1231", "1232", "1234", "1243", "1244", "1245", "1255", "1258", "1262", "1271", "1280", "1282", "1298", "1300", "1314"]
#     cweids = ["226"]
#     cwe_results_path = "constrain_path.json"

#     # 加载现有的 cwe_results.json 文件
#     # if os.path.exists(cwe_results_path):
#     #     with open(cwe_results_path, "r", encoding="utf-8") as file:
#     #         cwe_results = json.load(file)
#     # else:
#     #     cwe_results = {}

#     cwe_results = {}

#     # 加载 cwe_content.json 文件
#     if os.path.exists("../../cwe_content.json"):
#         with open("../../cwe_content.json", "r", encoding="utf-8") as file:
#             cwe_content = json.load(file)

#             for cweid in cweids:

                

#                 # 如果 cweid 已经存在于 cwe_results 中，则跳过
#                 if cweid in cwe_results:
#                     print(f"Skipping cweid {cweid}, already exists in cwe_results.json")
#                     continue

#                 # 获取 cwe 描述
#                 cwe_describe = cwe_content.get(cweid)
#                 if not cwe_describe:
#                     print(f"Skipping cweid {cweid}, no description found in cwe_content.json")
#                     continue

#                 # 执行三次约束路径生成
#                 constrain_paths = []
#                 # for _ in range(3):
#                 constrain_path = generate_constrain_path(cwe_describe)
#                 constrain_path = re.findall(r"<path>(.*?)</path>", constrain_path, re.DOTALL)
#                 # print(constrain_path)
#                 constrain_paths.append(constrain_path)

#                 # 将结果存储到 cwe_results 中
#                 # cwe_results[cweid] = constrain_paths

#             # 将更新后的结果保存回 cwe_results.json
#             # with open(cwe_results_path, "w", encoding="utf-8") as file:
#             #     json.dump(cwe_results, file, indent=4, ensure_ascii=False)

#             # print("Updated cwe_results.json")