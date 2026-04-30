#!/usr/bin/env bash
# =====================================================
#  termclip - Installation Script
#  Author: Jonathansl17
#  Description:
#    Installs termclip clipboard utilities (`c`, `cc`, `cpwd`, `v`)
#    as standalone scripts in ~/bin (no bash functions required).
# =====================================================

set -euo pipefail

# --- Configuration ---
BIN_DIR="$HOME/bin"
BASHRC="$HOME/.bashrc"
MARK_START="# === termclip configuration ==="
MARK_END="# === end termclip ==="
TERMCLIP_REF="${TERMCLIP_REF:-master}"
RAW_BASE="https://raw.githubusercontent.com/Jonathansl17/termclip/$TERMCLIP_REF"

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

# --- Step 3: Fetch python backends if missing ---
if [ ! -f "c.py" ] || [ ! -f "cpwd.py" ]; then
  WORKDIR="$(mktemp -d)"
  trap 'rm -rf "$WORKDIR"' EXIT
  echo "Running in standalone mode, using $WORKDIR"
  cd "$WORKDIR"
fi

for f in c.py v.py cc.py cpwd.py; do
  fetch_if_missing "$f"
done

cp -f c.py    "$BIN_DIR/"
cp -f v.py    "$BIN_DIR/"
cp -f cc.py   "$BIN_DIR/"
cp -f cpwd.py "$BIN_DIR/"
chmod u+x "$BIN_DIR/c.py" "$BIN_DIR/v.py" "$BIN_DIR/cc.py" "$BIN_DIR/cpwd.py"

# --- Step 4: Remove any old symlinks left from previous installs ---
for legacy in c v cc cpwd; do
  if [ -L "$BIN_DIR/$legacy" ]; then
    rm -f "$BIN_DIR/$legacy"
  fi
done

# --- Step 5: Generate wrapper scripts (replace bash functions) ---
cat > "$BIN_DIR/c" <<'EOF'
#!/usr/bin/env bash
if [ $# -lt 1 ]; then
    echo "Usage: c file1 file2 ..."
    exit 1
fi
pkill -f "$HOME/bin/c.py" 2>/dev/null
"$HOME/bin/c.py" "$@" >/dev/null 2>&1 & disown
echo "Files copied to clipboard:"
for f in "$@"; do
    echo "   $f"
done
EOF

cat > "$BIN_DIR/cc" <<'EOF'
#!/usr/bin/env bash
if [ $# -lt 1 ]; then
    echo "Usage: cc file"
    exit 1
fi
pkill -f "$HOME/bin/cc.py" 2>/dev/null
"$HOME/bin/cc.py" "$1" >/dev/null 2>&1 & disown
echo "Content copied to clipboard from:"
echo "   $1"
EOF

cat > "$BIN_DIR/cpwd" <<'EOF'
#!/usr/bin/env bash
target="${1:-$(pwd)}"
pkill -f "$HOME/bin/cpwd.py" 2>/dev/null
"$HOME/bin/cpwd.py" "$target" >/dev/null 2>&1 & disown
echo "Path copied to clipboard:"
echo "   $target"
EOF

cat > "$BIN_DIR/v" <<'EOF'
#!/usr/bin/env bash
output=$("$HOME/bin/v.py" "$@")
if [ $? -ne 0 ]; then
    echo "No files found in clipboard."
    exit 1
fi
echo "Files pasted from clipboard:"
for f in $output; do
    echo "   $f"
done
EOF

chmod u+x "$BIN_DIR/c" "$BIN_DIR/cc" "$BIN_DIR/cpwd" "$BIN_DIR/v"

echo "Scripts installed/updated. Commands 'c', 'cc', 'cpwd' and 'v' ready."

# --- Step 6: Ensure ~/bin is in PATH (no bash functions appended) ---
if grep -Fq "$MARK_START" "$BASHRC"; then
  sed -i "/$MARK_START/,/$MARK_END/d" "$BASHRC"
  sed -i -e :a -e '/^$/{$d;N;ba' -e '}' "$BASHRC"
  echo "Existing termclip block removed from $BASHRC (will be refreshed)."
fi

{
  echo ""
  echo "$MARK_START"
  echo "# Ensure ~/bin is on PATH so termclip scripts are found."
  cat <<'EOF'
case ":$PATH:" in
  *":$HOME/bin:"*) ;;
  *) export PATH="$HOME/bin:$PATH" ;;
esac
EOF
  echo "$MARK_END"
} >> "$BASHRC"
echo "PATH guard written to $BASHRC."

# --- Final message ---
echo ""
echo "termclip installation complete!"
echo "Commands available:"
echo "  c file1 file2 ...   → Copy files or folders to clipboard"
echo "  cc file             → Copy text content of a file to clipboard"
echo "  cpwd [path]         → Copy current (or given) path to clipboard"
echo "  v                   → Paste files from clipboard"
echo ""
echo "Open a new terminal or run: source ~/.bashrc"
