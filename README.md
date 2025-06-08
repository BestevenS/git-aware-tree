[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

# git-aware-tree

Local Bash script by **[Stefanos Chidiroglou](https://github.com/BestevenS)**

A minimal shell script that generates a clean folder structure tree of your project, **respecting `.gitignore` rules** with improved sorting (directories first, then files).

## 🌟 Features

- 🧠 Respects `.gitignore` automatically
- 🗂️ Sorts directories first, then files (alphabetically)
- 🪵 Generates clean tree-like view with proper indentation
- ⚡ Lightweight - pure Bash + Git
- 🧼 No external dependencies (no `tree`, no `npm`)
- 📁 Outputs to `structure.txt`

## 🚀 Usage

```bash
# 1. Make the script executable
chmod +x tree.sh

# 2. Run the script
./tree.sh

# 3. Check the generated structure
cat structure.txt

# 4. Requirements
    - Git (must be installed and available in PATH)
    - Bash 4.0+

# 5. License
    This project is licensed under the MIT License - see the LICENSE file for details.
