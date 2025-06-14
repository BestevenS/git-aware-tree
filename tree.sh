#!/usr/bin/env bash
# git-aware-tree - Generate project structure respecting .gitignore
# Copyright (c) 2025 Stefanos Chidiroglou
# Licensed under the MIT License

set -euo pipefail  # Exit on error, unset vars, and pipeline failures

output_file="structure.txt"  # Output file for the directory structure
max_depth=10                 # Maximum recursion depth

# Log info messages to stderr
log_info() {
  echo "[INFO] $1" >&2
}

# Log error messages to stderr
log_error() {
  echo "[ERROR] $1" >&2
}

# Ensure the script is run inside a Git repository
ensure_git_repo() {
  if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    log_error "This script must be run inside a Git repository."
    exit 1
  fi
}

# Safely list directory contents, ignoring errors (e.g., permissions)
list_directory() {
  local dir="$1"
  ls -A "$dir" 2>/dev/null || true
}

# Recursively process directories and write structure to output file
process_directory() {
  local dir_path="$1"         # Current directory path
  local indent="$2"           # Indentation string for pretty print
  local current_depth="$3"    # Current depth level

  if [ "$current_depth" -gt "$max_depth" ]; then return 0; fi

  log_info "Processing directory: $dir_path (depth: $current_depth)"

  local files=()
  local dirs=()

  # Read directory entries
  while IFS= read -r item; do
    [ -z "$item" ] && continue
    local full_path="$dir_path/$item"

    # Skip known irrelevant files
    case "$item" in
      .git|.gitignore|structure.txt) continue ;;
    esac

    # Skip if ignored by .gitignore
    if git check-ignore -q "$full_path"; then
      log_info "Ignored by .gitignore: $full_path"
      continue
    fi

    # Classify as directory or file
    if [ -d "$full_path" ]; then
      dirs+=("$item")
    else
      files+=("$item")
    fi
  done < <(list_directory "$dir_path")

  # Sort and print files
  if [ "${#files[@]}" -gt 0 ]; then
    IFS=$'\n' sorted_files=($(printf "%s\n" "${files[@]}" | sort))
    for file in "${sorted_files[@]}"; do
      echo "${indent}${file}" >> "$output_file"
    done
  fi

  # Sort and recurse into subdirectories
  if [ "${#dirs[@]}" -gt 0 ]; then
    IFS=$'\n' sorted_dirs=($(printf "%s\n" "${dirs[@]}" | sort))
    for dir in "${sorted_dirs[@]}"; do
      echo "${indent}${dir}/" >> "$output_file"
      process_directory "$dir_path/$dir" "${indent}    " $((current_depth + 1))
    done
  fi
}

# Entry point
main() {
  ensure_git_repo
  log_info "Starting tree structure generation"

  # Initialize output file with root directory name
  echo "$(basename "$PWD")" > "$output_file"
  log_info "Created $output_file with root directory"

  # Start recursive directory traversal
  process_directory "." "    " 1

  log_info "Tree structure generation completed"
  echo "✅ Project structure generated in $output_file"
}

main