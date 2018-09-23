# vim: set sw=4 ts=4 sts=4 et tw=78 foldmarker=@{,@} foldlevel=0 foldmethod=marker:

import snake
from snake import command, expand

@snake.key_map("<leader>p")
def run_code():
    command('!bash -c "gcc {0} -o {1} && ./{1}"'.format(expand("%"),
                                                        expand("%<")),
            capture=True)
