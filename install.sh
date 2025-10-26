#!/bin/bash
# Install into ~/.local/bin
INSTALL_DIR="$HOME/.local/share/bin"
SCRIPT_NAME="cp_image.sh"

# Create INSTALL_DIR if it doesn't exist
mkdir -p "$INSTALL_DIR" 
# Remove existing symbolic link if it exists
if [ -L "$INSTALL_DIR/$SCRIPT_NAME" ]; then
    rm "$INSTALL_DIR/$SCRIPT_NAME"
fi

# Create symbolic link to Install_DIR
ln -sf "$(pwd)/$SCRIPT_NAME" "$INSTALL_DIR/$SCRIPT_NAME"
echo "Installed $SCRIPT_NAME to $INSTALL_DIR"
echo "You can now run it using: $SCRIPT_NAME"
# Make sure INSTALL_DIR is in PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo "Warning: $INSTALL_DIR is not in your PATH."
    echo "You may want to add the following line to your shell configuration file (e.g., ~/.bashrc or ~/.zshrc):"
    echo "export PATH=\"\$PATH:$INSTALL_DIR\""
fi  