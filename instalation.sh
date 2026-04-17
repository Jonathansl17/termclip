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
TERMCLIP_REF="${TERMCLIP_REF:-main}"
RAW_BASE="https://raw.githubusercontent.com/Jonathansl17/termclip/$TERMCLIP_REF"

# Fetch a repo file into the current directory if it isn't already here.
# Lets the installer run standalone via `curl | bash` without cloning.
fetch_if_missing() {
  local name="$1"
  if [ ! -f "$name" ]; then
    echo "Downloading $name from $TERMCLIP_REF..."
    if command -v curl >/dev/null 2>&1; then
      curl -fsSL "$RAW_BASE/$name" -o "$name"
    elif command -v wget >/dev/null 2>&1; then
      wget -q "$RAW_BASE/$name" -O "$name"
    else
      echo "Neither curl nor wget available to download $name." >&2
      exit 1
    fi
  fi
}

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

# --- Step 2: Stop any previous instances so updates take effect ---
pkill -f "$BIN_DIR/c.py"    2>/dev/null || true
pkill -f "$BIN_DIR/cc.py"   2>/dev/null || true
pkill -f "$BIN_DIR/cpwd.py" 2>/dev/null || true

# --- Step 3: Copy scripts and create runnable aliases ---
# If running without a clone (curl | bash), the required files are missing
# from the current directory. Fall back to a temp workspace and download.
if [ ! -f "c.py" ] || [ ! -f "cpwd.py" ]; then
  WORKDIR="$(mktemp -d)"
  trap 'rm -rf "$WORKDIR"' EXIT
  echo "Running in standalone mode, using $WORKDIR"
  cd "$WORKDIR"
fi

for f in c.py v.py cc.py cpwd.py bashconfig.txt; do
  fetch_if_missing "$f"
done

cp -f c.py "$BIN_DIR/"
cp -f v.py "$BIN_DIR/"
cp -f cc.py "$BIN_DIR/"
cp -f cpwd.py "$BIN_DIR/"
chmod u+x "$BIN_DIR/c.py" "$BIN_DIR/v.py" "$BIN_DIR/cc.py" "$BIN_DIR/cpwd.py"

ln -sf "$BIN_DIR/c.py" "$BIN_DIR/c"
ln -sf "$BIN_DIR/v.py" "$BIN_DIR/v"
ln -sf "$BIN_DIR/cc.py" "$BIN_DIR/cc"
ln -sf "$BIN_DIR/cpwd.py" "$BIN_DIR/cpwd"
chmod u+x "$BIN_DIR/c" "$BIN_DIR/v" "$BIN_DIR/cc" "$BIN_DIR/cpwd"

echo "Scripts installed/updated. Commands 'c', 'cc', 'cpwd' and 'v' ready."

# --- Step 4: Add or refresh shell configuration ---
if grep -Fq "$MARK_START" "$BASHRC"; then
  # Remove the existing termclip block so we can replace it with the latest version
  sed -i "/$MARK_START/,/$MARK_END/d" "$BASHRC"
  # Drop the trailing blank line left behind, if any
  sed -i -e :a -e '/^$/{$d;N;ba' -e '}' "$BASHRC"
  echo "Existing termclip configuration removed from $BASHRC (will be refreshed)."
fi

{
  echo ""
  echo "$MARK_START"
  echo "# Terminal clipboard utilities (c, v, cc)"
  echo "# Added automatically on $(date)"
  if ! grep -Fq 'export PATH="$HOME/bin:$PATH"' "$BASHRC"; then
    echo 'export PATH="$HOME/bin:$PATH"'
  fi
  if [ -f "$CONFIG_FILE" ]; then
    cat "$CONFIG_FILE"
  else
    cat <<'EOF'
# termclip fallback functions
c()    { command -v c    >/dev/null 2>&1 && c    "$@" || "$HOME/bin/c"    "$@"; }
v()    { command -v v    >/dev/null 2>&1 && v    "$@" || "$HOME/bin/v";         }
cc()   { command -v cc   >/dev/null 2>&1 && cc   "$@" || "$HOME/bin/cc"   "$@"; }
cpwd() { command -v cpwd >/dev/null 2>&1 && cpwd "$@" || "$HOME/bin/cpwd" "$@"; }
EOF
  fi
  echo "$MARK_END"
} >> "$BASHRC"
echo "termclip configuration written to $BASHRC."

# --- Final message ---
echo ""
echo "termclip installation complete!"
echo "You can now use the following commands:"
echo "  c file1 file2 ...   → Copy files or folders to the clipboard"
echo "  cc file             → Copy the text content of a file to the clipboard"
echo "  cpwd [path]         → Copy the current (or given) path to the clipboard"
echo "  v                   → Paste files from the clipboard"
echo ""
echo "Open a new terminal or run: source ~/.bashrc"
