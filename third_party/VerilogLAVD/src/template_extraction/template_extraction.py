from constrain_path import generate_constrain_path
from path_validation import path_validation, path_validation_prompt
import json
import re

def constrain_path_extraction(cweid):
    try:
        with open ("constrain_path.json", "r", encoding="utf-8") as file:
            existing_data = json.load(file)
    except (FileNotFoundError, json.JSONDecodeError):
        existing_data = {}

    if cweid not in existing_data:
        constrain_path = ""
        with open("../../cwe_content.json", "r", encoding="utf-8") as file:
            cwe_content = json.load(file)
            cwe_describe = cwe_content.get(cweid)
            constrain_path = generate_constrain_path(cwe_describe)

        constrain_paths = re.findall(r"<path>(.*?)</path>", constrain_path, re.DOTALL)
        existing_data[cweid] = constrain_paths
    
    with open ("constrain_path.json", "w", encoding="utf-8") as file:
        json.dump(existing_data, file, ensure_ascii=False, indent=4)

# def generate_vulnerability_template(cweid):
#     with open("constrain_path.json", "r", encoding="utf-8") as file:
#         existing_data = json.load(file)

#     if cweid in existing_data:
#         constrain_paths = existing_data[cweid]
#         vulnerability_templates=[]
#         for path in constrain_paths:
#             validation_result = path_validation(path)
#             vulnerability_template = re.findall(r"<template>(.*?)</template>", validation_result, re.DOTALL)
#             print(f"Validation result for CWE-{cweid}: {vulnerability_template[0]}")
#             vulnerability_templates.append(vulnerability_template[0] if vulnerability_template else "No template found")
        
#         output_data = {cweid: vulnerability_templates}
#         output_file = f"vulnerability_templates_{cweid}.json"
#         with open(output_file, "w", encoding="utf-8") as file:
#             json.dump(output_data, file, ensure_ascii=False, indent=4)
#     else:
#         print(f"No constrain paths found for CWE-{cweid}.")

def generate_vulnerability_template(cweid):
    # 尝试读取已有的 JSON 文件内容
    try:
        with open("vulnerability_templates.json", "r", encoding="utf-8") as file:
            all_templates = json.load(file)
    except (FileNotFoundError, json.JSONDecodeError):
        # 如果文件不存在或内容无效，初始化为空字典
        all_templates = {}
    
    if cweid in all_templates:
        print(f"Vulnerability templates for CWE-{cweid} already exist. Skipping generation.")
        return

    # 读取约束路径数据
    with open("constrain_path.json", "r", encoding="utf-8") as file:
        existing_data = json.load(file)

    if cweid in existing_data:
        constrain_paths = existing_data[cweid]
        vulnerability_templates = []
        for path in constrain_paths:
            validation_result = path_validation(path)
            vulnerability_template = re.findall(r"<template>(.*?)</template>", validation_result, re.DOTALL)
            # print(f"Validation result for CWE-{cweid}: {vulnerability_template[0]}")
            vulnerability_templates.append(vulnerability_template[0] if vulnerability_template else "No template found")
        
        # 更新当前 CWE 的模板到总字典中
        all_templates[cweid] = vulnerability_templates

        # 写回到 JSON 文件
        with open("vulnerability_templates.json", "w", encoding="utf-8") as file:
            json.dump(all_templates, file, ensure_ascii=False, indent=4)
            print(f"Vulnerability templates for CWE-{cweid} have been saved to vulnerability_templates.json.")
    else:
        print(f"No constrain paths found for CWE-{cweid}.")

# if __name__ == "__main__":
#     # cweids = ["226","1231","1232","1234","1243","1244","1245","1255","1258","1262","1271","1280","1282","1298","1300","1314"]
#     # cweids = ["1262","1271","1280","1282","1314"]
#     # cweids = ["1314"]
#     # for cweid in cweids:
#     #     print(f"Processing CWE ID: {cweid}")
#     #     # constrain_path_extraction(cweid)
#     #     generate_vulnerability_template(cweid)
#     with open ("constrain_path.json", "r", encoding="utf-8") as file:
#     # with open ("../../cwe_content.json", "r", encoding="utf-8") as file:
#         constrain_paths = json.load(file)
#         path = constrain_paths["1300"][0]
#         validation_result = path_validation(path)
#         vulnerability_template = re.findall(r"<template>(.*?)</template>", validation_result, re.DOTALL)
#         if len(vulnerability_template) != 0:
#             print(vulnerability_template[-1])

import os,sys
constrain_path_file = os.path.abspath(os.path.join(os.path.dirname(__file__), 'constrain_path.json'))

if __name__ == "__main__":
    idx = 0
    cweids = ["1234","1245","1262","1271","1280"]
    with open (constrain_path_file, "r", encoding="utf-8") as file:
        constrain_paths = json.load(file)
        path = constrain_paths[cweids[idx]][0]
        prompt = path_validation_prompt(path)
        print("-"*20)
        print(prompt)