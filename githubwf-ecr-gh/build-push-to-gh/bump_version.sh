#!/bin/bash

# Check if VERSION-GH file exists
if [ ! -f VERSION-GH ]; then
  echo "2.2.21" > VERSION-GH
fi

current_version=$(cat VERSION-GH)

IFS='.' read -r -a version_parts <<< "$current_version"
version_parts[2]=$((version_parts[2] + 1))
new_version="${version_parts[0]}.${version_parts[1]}.${version_parts[2]}"

# Write the new version back to the VERSION-GH file
echo $new_version > VERSION-GH

# Update WorkflowTemplate.yaml with the new version
sed -i "s/value: \"[0-9.]*\"/value: \"$new_version\"/g" build-push-to-gh/WorkflowTemplate.yaml

echo $new_version
