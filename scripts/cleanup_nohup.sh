#!/bin/bash

# ANSI color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print script header
echo -e "${GREEN}Nohup.out Cleanup Script${NC}"
echo "=============================="
echo

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo -e "${RED}Error: Not in a git repository${NC}"
    echo "Please run this script from within a git repository"
    exit 1
fi

# Get the repository root directory
REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT" || exit 1

echo -e "${YELLOW}Searching for nohup.out files...${NC}"
echo

# Find all nohup.out files, excluding certain directories
NOHUP_FILES=$(find . -type f -name "nohup.out" \
    ! -path "*/node_modules/*" \
    ! -path "*/.git/*" \
    ! -path "*/venv/*" \
    ! -path "*/__pycache__/*" \
    ! -path "*/vendor/*")

# Count found files
FILE_COUNT=$(echo "$NOHUP_FILES" | grep -c "^" || true)

if [ "$FILE_COUNT" -eq 0 ]; then
    echo -e "${GREEN}No nohup.out files found.${NC}"
    exit 0
fi

echo -e "Found ${YELLOW}$FILE_COUNT${NC} nohup.out file(s):"
echo "$NOHUP_FILES" | sed 's/^/- /'
echo

# Ask for confirmation
read -p "Do you want to remove these files? (y/N) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo
    echo -e "${YELLOW}Removing files...${NC}"
    
    # Remove each file and show status
    while IFS= read -r file; do
        if [ -f "$file" ]; then
            if rm "$file"; then
                echo -e "✓ Removed: ${GREEN}$file${NC}"
            else
                echo -e "✗ Failed to remove: ${RED}$file${NC}"
            fi
        fi
    done <<< "$NOHUP_FILES"
    
    echo
    echo -e "${GREEN}Cleanup completed!${NC}"
else
    echo
    echo -e "${YELLOW}Operation cancelled by user.${NC}"
fi 