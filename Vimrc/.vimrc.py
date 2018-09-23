# vim: set sw=4 ts=4 sts=4 et tw=78 foldmarker=@{,@} foldlevel=0 foldmethod=marker:

import os
import sys
import re
import snake
from snake import command, expand

# Useful Global variables
HOME = os.path.join(os.getenv("HOME")

# Build a project
@snake.key_map("<leader>bs")
def build_project():
    user_input_file = HOME, "vim_userinputs.conf")

    with open(user_input_file, 'r') as fileobj:
        for line in fileobj:
            if line.strip().startswith("BuildProjectCMD"):
                cmd = line.split('=')[1].strip()
                break

    command(cmd)
