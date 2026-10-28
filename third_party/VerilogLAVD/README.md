# VerilogLAVD: LLM-Aided Pattern Generation for Verilog CWE Detection

Welcome to **VerilogLAVD**, a project dedicated to leveraging large language models (LLMs) to generate patterns for detecting Common Weakness Enumerations (CWEs) in Verilog and SystemVerilog code. This repository serves as a critical tool to enhance hardware security and software quality in chip and system designs.

---

## 📋 Table of Contents

- [VerilogLAVD: LLM-Aided Pattern Generation for Verilog CWE Detection](#veriloglavd-llm-aided-pattern-generation-for-verilog-cwe-detection)
  - [📋 Table of Contents](#-table-of-contents)
  - [📖 Introduction](#-introduction)
  - [✨ Features](#-features)
  - [🚀 Getting Started](#-getting-started)
  - [📁 Folder Structure](#-folder-structure)
  - [⚙️ How It Works](#️-how-it-works)
  - [📦 Dependencies](#-dependencies)
  - [💻 Usage](#-usage)
  - [🤝 Contributing](#-contributing)
  - [📜 License](#-license)
  - [📧 Contact](#-contact)

---

## 📖 Introduction

The **VerilogLAVD** project is designed to address security and quality concerns in hardware-based projects by automatically identifying and analyzing weaknesses in Verilog and SystemVerilog code. By incorporating insights from large language models, the repository integrates advanced methods to generate CWE-specific detection patterns.

The primary objectives of VerilogLAVD include:
- Simplifying the process of detecting CWEs in Verilog.
- Improving the overall safety standards of hardware design.
- Empowering developers with tools for automated, pattern-based vulnerability identification using graph-based analysis.

---

## ✨ Features

- **CWE Detection:** Supports analysis for a broad range of CWEs in Verilog-based designs using graph patterns.
- **Graph-Based Analysis:** Constructs property graphs from Verilog code and performs traversals to detect vulnerabilities.
- **Extensible Architecture:** Designed to allow easy addition of new patterns or rules.

---

## 🚀 Getting Started

To get started with VerilogLAVD:
1. Clone this repository:
   ```bash
   git clone https://github.com/Chip-Security-Lab/VerilogLAVD.git
   cd VerilogLAVD
   ```
2. Install necessary dependencies (see [Dependencies](#dependencies)).
3. Set up Neo4j database.
4. Run the experiments or use the modules for CWE detection.

---

## 📁 Folder Structure

Here is an overview of the key folders and files in the repository:

```plaintext
VerilogLAVD/
├── README.md              # This file
├── datasets.zip           # Dataset files (compressed)
└── src/
    ├── template_extraction/  # Modules for generating constraint paths and vulnerability templates using LLM
    │   ├── __init__.py
    │   ├── constrain_path.py
    │   ├── fsm.py
    │   ├── path_validation.py
    │   └── template_extraction.py
    └── traversal_engine/     # Graph traversal engine for CWE detection
        ├── __init__.py
        ├── experiment_realworld.ipynb
        ├── function_registry.py
        ├── traversal_engine.py
        ├── traversal_functions.py
        └── veripg_construct.py
```

---

## ⚙️ How It Works

1. **Pattern Generation:**
   - Uses LLM to generate constraint paths and vulnerability templates for specific CWEs based on CWE descriptions.

2. **Graph Construction:**
   - Parses Verilog code using PyVerilog to build an abstract syntax tree (AST).
   - Constructs a property graph in Neo4j database representing the code structure.

3. **Detection:**
   - Applies generated patterns as graph queries using the traversal engine.
   - Executes traversals on the property graph to identify potential vulnerabilities.

4. **Extensibility:**
   - New CWE patterns can be added by generating new templates and integrating them into the traversal queries.

---

## 📦 Dependencies

- Python 3.12+
- Neo4j (graph database)
- PyVerilog (for Verilog parsing)
- Other Python packages: neo4j-driver, tqdm, pandas, etc.

Install Python dependencies:
```bash
pip install pyverilog neo4j tqdm pandas autogen
```

Set up Neo4j:
- Install Neo4j Community Edition.
- Start the database and note the URI, username, and password.

---

## 💻 Usage

1. **Template Extraction:**
   - Run `template_extraction.py` to generate vulnerability templates for CWEs.

2. **Graph Construction:**
   - Use `veripg_construct.py` to build program graphs from Verilog files.

3. **Detection:**
   - Use `traversal_engine.py` with generated patterns to detect vulnerabilities.
   - Refer to `experiment_realworld.ipynb` for example usage.

---

## 🤝 Contributing

Contributions are welcome! If you'd like to help improve **VerilogLAVD**, please fork the repository, create a feature branch, and submit a pull request. For major changes, please open an issue first for discussion.

---

## 📜 License

This project is licensed under the [MIT License](LICENSE). Feel free to use, modify, and distribute this software while keeping the license notice intact.

---

## 📧 Contact

For questions, issues, or suggestions, feel free to create a GitHub issue or contact the development team at [Chip-Security-Lab](https://github.com/Chip-Security-Lab).
