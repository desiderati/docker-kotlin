#!/bin/bash
#
# Copyright (c) 2025 - Felipe Desiderati
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
# associated documentation files (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial
# portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
# LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

DIR="$(dirname "${BASH_SOURCE[0]}")"
DIR="$(cd "$DIR" >/dev/null 2>&1 && pwd)"

echo "[$(date +%c)] Applying ACL fix for directory: $DIR/logs/..."
sudo setfacl -R -d -m u::rw- "$DIR"/logs/
sudo setfacl -R -m g::rw- "$DIR"/logs/
sudo setfacl -R -m o::r-- "$DIR"/logs/

echo "[$(date +%c)] Applying fix for application ownership..."
sudo find "$DIR" -exec chown "$UID":"$UID" {} +

echo "[$(date +%c)] Applying file access permissions fix..."
sudo find "$DIR" -type f -exec chmod u+rw,g+rw,o=r {} \;

echo "[$(date +%c)] Applying directory access permissions fix..."
sudo find "$DIR" -type d -exec chmod u=rwx,g=rwx,o=rx {} \;
sudo chmod 777 "$DIR"/temp/
