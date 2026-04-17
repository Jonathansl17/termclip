# termclip 🧷  
**Terminal Clipboard Utilities for GNOME/Linux**

`termclip` is a lightweight set of Bash + Python utilities that bring GNOME clipboard integration directly to your terminal.  
It lets you **copy and paste files or folders** from the command line — just like you would in your file manager.

---

## 🚀 Features

- 🧩 Copy files or folders to the system clipboard (`c`)
- 📝 Copy the text content of a file to the clipboard (`cc`)
- 📍 Copy the current working directory path to the clipboard (`cpwd`)
- 📎 Paste files from the clipboard into the current directory (`v`)
- 🐧 100% compatible with GNOME / Nautilus
- 💻 Works entirely from the terminal (no GUI required)
- ⚙️ Built with **Bash + PyQt5**

---

## 📦 Installation

### One-liner (recommended)
```bash
curl -fsSL https://raw.githubusercontent.com/Jonathansl17/termclip/master/instalation.sh | bash
```

Pin a specific version:
```bash
curl -fsSL https://raw.githubusercontent.com/Jonathansl17/termclip/v1.1.1/instalation.sh | TERMCLIP_REF=v1.1.1 bash
```

### Or clone the repository
```bash
git clone https://github.com/Jonathansl17/termclip
cd termclip
./instalation.sh
```

Running the installer again also works as an **update**: it refreshes the
scripts in `~/bin`, stops any running instances and rewrites the termclip
block in your `~/.bashrc`.

---

## 🧪 Usage

### `c` — copy files/folders to the clipboard
Copies one or more files/folders to the system clipboard **as files**,
just like hitting *Copy* in Nautilus.

```bash
c hello.txt
c file1.txt file2.png some-folder/
```

Paste them with `v` in another directory, or with `Ctrl+V` inside Nautilus.

### `cc` — copy the text content of a file to the clipboard
Reads a file as UTF-8 text and puts its **content** in the clipboard.
Trailing whitespace and newlines are stripped, so pasting into a shell
does not auto-execute the command.

```bash
cc comando.txt
```

Paste it with **`Ctrl+V`** in any editor, browser or text field, or with
**`Ctrl+Shift+V`** inside a terminal.

> `cc` is different from `c`: `c` copies the *file itself*, `cc` copies
> the *text inside the file*.

### `cpwd` — copy the current path to the clipboard
Copies the current working directory (or a given path) to the clipboard
as plain text. Useful for quickly sharing a path or pasting it in another
terminal / editor.

```bash
cpwd              # copies $(pwd)
cpwd /etc/nginx   # copies the given path
```

### `v` — paste files from the clipboard
Pastes files previously copied with `c` (or from Nautilus) into the
current directory. If a file with the same name already exists, a unique
name is generated (`file_copy.txt`, `file_copy2.txt`, ...).

```bash
v
```

`v` only works with files in the clipboard — it will not paste plain
text copied with `cc`.
