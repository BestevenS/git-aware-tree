#!/bin/bash
# git-aware-tree - Generate project structure respecting .gitignore
# Copyright (c) 2025 Stefanos Chidiroglou
# Licensed under the MIT License

set -euo pipefail  # Strict mode

# Function to process the file list and generate a hierarchical structure
generate_tree() {
  local root_dir=$(basename "$PWD")
  echo "$root_dir" > structure.txt
  
  # Temporary files
  local file_list=$(mktemp)
  local dir_list=$(mktemp)
  local tree_file=$(mktemp)
  
  # Get all tracked files
  git ls-files > "$file_list"
  
  # Extract all directories from file paths and mark as directories
  cat "$file_list" | while read -r file; do
    # Skip files in the root directory
    if [[ "$file" != */* ]]; then
      continue
    fi
    
    # Extract directory parts
    local path=""
    local parts=(${file//\// })
    for ((i=0; i<${#parts[@]}-1; i++)); do
      if [[ -n "${parts[$i]}" ]]; then
        if [[ -n "$path" ]]; then
          path="$path/${parts[$i]}"
        else
          path="${parts[$i]}"
        fi
        echo "D|$path" >> "$dir_list"
      fi
    done
  done
  
  # Mark all files with F prefix
  cat "$file_list" | while read -r file; do
    echo "F|$file" >> "$dir_list"
  done
  
  # Sort the list uniquely
  sort -u "$dir_list" > "$dir_list.sorted"
  mv "$dir_list.sorted" "$dir_list"
  
  # Process the sorted list to create the tree structure
  local current_dir=""
  local current_depth=0
  
  # First process files in root directory
  grep "^F|[^/]*$" "$dir_list" | sort | while read -r line; do
    local file="${line#F|}"
    echo "    $file" >> "$tree_file"
  done
  
  # Process all directories and their files
  grep "^D|" "$dir_list" | sort | while read -r line; do
    local dir="${line#D|}"
    local depth=$(echo "$dir" | grep -o '/' | wc -l)
    local indent=$(printf '%*s' $(((depth+1)*4)) '')
    echo "${indent}$(basename "$dir")/" >> "$tree_file"
    
    # Find files directly in this directory (not in subdirectories)
    grep "^F|$dir/[^/]*$" "$dir_list" | sort | while read -r file_line; do
      local file="${file_line#F|}"
      local file_indent=$(printf '%*s' $(((depth+2)*4)) '')
      echo "${file_indent}$(basename "$file")" >> "$tree_file"
    done
  done
  
  # Concatenate the tree file to the output
  cat "$tree_file" >> structure.txt
  
  # Clean up
  rm -f "$file_list" "$dir_list" "$tree_file"
}

# Generate the tree structure
generate_tree

echo "✅ Project structure generated in structure.txt"