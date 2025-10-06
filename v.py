#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os, sys, shutil
from urllib.parse import urlparse, unquote
from PyQt5.QtGui import QGuiApplication, QClipboard

def from_file_uri(uri: str) -> str:
    """Convierte un file:// URI en una ruta local."""
    return unquote(urlparse(uri).path)

# Init Qt
app = QGuiApplication([])
cb: QClipboard = QGuiApplication.clipboard()
mime = cb.mimeData()

# Check clipboard content
if not mime.hasFormat("x-special/gnome-copied-files"):

    #Exit if no files in clipboard
    sys.exit(1)

# Parse clipboard content
data = mime.data("x-special/gnome-copied-files").data().decode("utf-8").strip().split("\n")

# Get operation and files
operation = data[0].strip().lower()
files = [from_file_uri(uri) for uri in data[1:] if uri.startswith("file://")]

# Paste files to current directory
dest = os.getcwd()
pasted = []

for f in files:
    try:
        target = os.path.join(dest, os.path.basename(f))
        if operation == "copy":
            if os.path.isdir(f):
                shutil.copytree(f, target, dirs_exist_ok=True)
            else:
                shutil.copy2(f, target)
        elif operation == "cut":
            shutil.move(f, target)
        pasted.append(os.path.basename(f))
    except Exception:
        pass

#Return pasted files or exit with error
if pasted:
    print("\n".join(pasted))
    sys.exit(0)
else:
    sys.exit(1)
