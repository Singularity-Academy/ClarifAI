#!/bin/bash

# ANSI color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get absolute path of workspace
WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo -e "${GREEN}Go Project Cleanup Script${NC}"
echo "=========================="
echo

# List of directories to clean (with absolute paths)
CLEAN_DIRS=(
    # Go build cache and binaries
    "$WORKSPACE_DIR/backend/go"
    # Go module cache
    "$WORKSPACE_DIR/backend/pkg/mod"
    # Go build cache
    "$WORKSPACE_DIR/backend/pkg/build"
    # Common Go temporary directories
    "$WORKSPACE_DIR/backend/pkg/sumdb"
    # Local build outputs
    "$WORKSPACE_DIR/backend/bin"
    # Test cache
    "$WORKSPACE_DIR/backend/pkg/test"
)

# Additional file patterns to clean (with absolute paths)
CLEAN_PATTERNS=(
    "$WORKSPACE_DIR/backend/**/*.test"
    "$WORKSPACE_DIR/backend/**/*.exe"
    "$WORKSPACE_DIR/backend/**/*.o"
    "$WORKSPACE_DIR/backend/**/*.a"
    "$WORKSPACE_DIR/backend/**/_obj"
    "$WORKSPACE_DIR/backend/**/_test"
    "$WORKSPACE_DIR/backend/**/*.out"
)

# Function to format size
format_size() {
    local size="$1"
    if ! [[ "$size" =~ ^[0-9]+$ ]]; then
        echo "0 bytes"
        return
    fi
    
    if [ "$size" -ge 1073741824 ]; then
        echo "$(( size / 1073741824 )) GB"
    elif [ "$size" -ge 1048576 ]; then
        echo "$(( size / 1048576 )) MB"
    elif [ "$size" -ge 1024 ]; then
        echo "$(( size / 1024 )) KB"
    else
        echo "$size bytes"
    fi
}

# Calculate total size before cleanup
total_size=0
found_files=false

# Check directories
for dir in "${CLEAN_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        # Try both BSD (macOS) and GNU (Linux) versions of du
        size=$(du -sk "$dir" 2>/dev/null | cut -f1)
        if [ -z "$size" ]; then
            size=$(du -sb "$dir" 2>/dev/null | cut -f1)
        fi
        
        if [[ "$size" =~ ^[0-9]+$ ]]; then
            # Convert KB to bytes if using -sk
            if [ "$(du --version 2>/dev/null | grep -c GNU)" -eq 0 ]; then
                size=$((size * 1024))
            fi
            total_size=$((total_size + size))
            echo -e "${YELLOW}Found directory${NC} $dir ($(format_size $size))"
            found_files=true
        else
            # Try alternate method using find
            size=$(find "$dir" -type f -ls 2>/dev/null | awk '{total += $7} END {print total}')
            if [[ "$size" =~ ^[0-9]+$ ]]; then
                total_size=$((total_size + size))
                echo -e "${YELLOW}Found directory${NC} $dir ($(format_size $size))"
                found_files=true
            fi
        fi
    fi
done

# Check file patterns
for pattern in "${CLEAN_PATTERNS[@]}"; do
    find_output=$(find "$WORKSPACE_DIR" -path "$pattern" -print0 2>/dev/null)
    if [ -n "$find_output" ]; then
        while IFS= read -r -d '' file; do
            if [ -f "$file" ]; then
                size=$(stat -f %z "$file" 2>/dev/null || stat -c %s "$file" 2>/dev/null)
                if [[ "$size" =~ ^[0-9]+$ ]]; then
                    total_size=$((total_size + size))
                    echo -e "${YELLOW}Found file${NC} $file ($(format_size $size))"
                    found_files=true
                fi
            fi
        done < <(echo "$find_output")
    fi
done

if [ "$found_files" = false ]; then
    echo -e "\n${GREEN}No Go temporary files found to clean up.${NC}"
    exit 0
fi

echo -e "\nTotal space used: ${YELLOW}$(format_size $total_size)${NC}"

# Ask for confirmation
read -p $'\nDo you want to remove these files and directories? (y/N) ' -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "\n${YELLOW}Cleaning up Go temporary files...${NC}"
    
    # Remove directories
    for dir in "${CLEAN_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            if rm -rf "$dir"; then
                echo -e "✓ Removed directory: ${GREEN}$dir${NC}"
            else
                echo -e "✗ Failed to remove directory: ${RED}$dir${NC}"
            fi
        fi
    done

    # Remove files matching patterns
    for pattern in "${CLEAN_PATTERNS[@]}"; do
        while IFS= read -r -d '' file; do
            if [ -f "$file" ]; then
                if rm -f "$file"; then
                    echo -e "✓ Removed file: ${GREEN}$file${NC}"
                else
                    echo -e "✗ Failed to remove file: ${RED}$file${NC}"
                fi
            fi
        done < <(find "$WORKSPACE_DIR" -path "$pattern" -print0 2>/dev/null)
    done
    
    echo -e "\n${GREEN}Cleanup completed!${NC}"
    echo "You can restore these files by:"
    echo "1. Running './scripts/setup_go.sh' to reinstall Go"
    echo "2. Running 'go mod download' to restore dependencies"
    echo "3. Running 'go build' to rebuild any necessary binaries"
else
    echo -e "\n${YELLOW}Operation cancelled by user.${NC}"
fi 