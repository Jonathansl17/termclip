#!/usr/bin/env bash
# =====================================================
#  termclip - Installation Script
#  Author: Jonathansl17
#  Description:
#    Installs termclip clipboard utilities (`c` and `v`)
#    for GNOME/Linux terminals, integrating Bash + Python.
# =====================================================

set -euo pipefail

# --- Configuration ---
BIN_DIR="$HOME/bin"
BASHRC="$HOME/.bashrc"
CONFIG_FILE="bashconfig.txt"
MARK_START="# === termclip configuration ==="
MARK_END="# === end termclip ==="

echo "Checking dependencies..."

# --- Step 0: Check & install dependencies ---
if ! python3 -c "import PyQt5" >/dev/null 2>&1; then
  echo "PyQt5 not found. Installing..."
  if command -v apt >/dev/null 2>&1; then
    sudo apt update -y
    sudo apt install -y python3-pyqt5
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y python3-qt5
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -Sy --noconfirm python-pyqt5
  else
    echo "Could not detect a supported package manager. Please install PyQt5 manually." >&2
  fi
else
  echo "PyQt5 already installed."
fi

# --- Step 1: Ensure ~/bin exists ---
mkdir -p "$BIN_DIR"
echo "Directory $BIN_DIR ready."

# --- Step 2: Copy scripts and create runnable aliases ---
cp -f c.py "$BIN_DIR/"
cp -f v.py "$BIN_DIR/"
chmod u+x "$BIN_DIR/c.py" "$BIN_DIR/v.py"

ln -sf "$BIN_DIR/c.py" "$BIN_DIR/c"
ln -sf "$BIN_DIR/v.py" "$BIN_DIR/v"
chmod u+x "$BIN_DIR/c" "$BIN_DIR/v"

echo "Scripts installed and commands 'c' and 'v' ready."

# --- Step 3: Add shell configuration ---
if ! grep -Fq "$MARK_START" "$BASHRC"; then
  {
    echo ""
    echo "$MARK_START"
    echo "# Terminal clipboard utilities (c, v)"
    echo "# Added automatically on $(date)"
    if ! grep -Fq 'export PATH="$HOME/bin:$PATH"' "$BASHRC"; then
      echo 'export PATH="$HOME/bin:$PATH"'
    fi
    if [ -f "$CONFIG_FILE" ]; then
      cat "$CONFIG_FILE"
    else
      cat <<'EOF'
# termclip fallback functions
c() { command -v c >/dev/null 2>&1 && c "$@" || "$HOME/bin/c" "$@"; }
v() { command -v v >/dev/null 2>&1 && v "$@" || "$HOME/bin/v"; }
EOF
    fi
    echo "$MARK_END"
  } >> "$BASHRC"
  echo "termclip configuration added to $BASHRC."
else
  echo "termclip configuration already exists in $BASHRC. Skipping."
fi

# --- Final message ---
echo ""
echo "termclip installation complete!"
echo "You can now use the following commands:"
echo "  c file1 file2 ...   → Copy files or folders to the clipboard"
echo "  v                   → Paste files from the clipboard"
echo ""
echo "Open a new terminal or run: source ~/.bashrc"
