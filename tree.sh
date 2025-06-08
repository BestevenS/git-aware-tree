#!/bin/bash
# git-aware-tree - Generate project structure respecting .gitignore
# Copyright (c) 2024 Stefanos Chidiroglou
# Licensed under the MIT License

set -euo pipefail  # Strict mode

TMP_FILELIST="$(mktemp)"
TMP_PATHLIST="$(mktemp)"
TMP_SORTED="$(mktemp)"

# Get list of tracked files
git ls-files > "$TMP_FILELIST"

# Expand folders from paths
awk -F/ '{
  path=""
  for(i=1;i<NF;i++){
    path=path $i "/"
    print path
  }
  print $0
}' "$TMP_FILELIST" | sort -u > "$TMP_PATHLIST"

# Custom sort: group by directory, then files first, then folders
# Add a sort key: depth|parent_dir|is_folder|basename|fullpath
awk '{
  full=$0
  is_folder = (full ~ /\/$/) ? 1 : 0
  n = split(full, parts, "/")
  depth = is_folder ? n - 1 : n
  parent = ""
  for(i=1; i<depth; i++) parent = parent parts[i] "/"
  base = parts[n]
  printf "%s|%s|%d|%s|%s\n", depth, parent, is_folder, base, full
}' "$TMP_PATHLIST" | sort -t'|' -k2,2 -k3,3n -k4,4 | cut -d'|' -f5 > "$TMP_SORTED"

# Print tree structure
echo "$(basename "$PWD")" > structure.txt
while IFS= read -r line; do
  if [[ "$line" == */ ]]; then
    depth=$(echo "$line" | tr -cd '/' | wc -c)
    indent=$(printf '%*s' $((depth * 4)) '')
    echo "${indent}$(basename "$line")/" >> structure.txt
  else
    depth=$(echo "$line" | tr -cd '/' | wc -c)
    indent=$(printf '%*s' $(((depth + 1) * 4)) '')
    echo "${indent}$(basename "$line")" >> structure.txt
  fi
done < "$TMP_SORTED"

# Clean up
rm -f "$TMP_FILELIST" "$TMP_PATHLIST" "$TMP_SORTED"

echo "✅ Project structure generated in structure.txt"
