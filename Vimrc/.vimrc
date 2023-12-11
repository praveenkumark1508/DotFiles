﻿" vim: set sw=4 ts=4 sts=4 et tw=78 foldmarker=@{,@} foldlevel=0 foldmethod=marker:

" NOTE: EXECUTABLE DEPENDENCY
" ctags, cscope, find, [ag or ack-grep or ack], python3

" options @{

    " Python develop environment setting
        let g:pkk_python_setting = []

    " Prevent automatically changing to open file directory
        let g:pkk_no_autochdir = 1

    " Disable views
        let g:pkk_no_views = 1

    " Prefered Syntax checker
        let g:pkk_syntax_checker = 'None'

    " Disable wrap relative motion for start/end line motions
    "   let g:pkk_no_wrapRelMotion = 1

    " Clear search highlighting
    "   let g:pkk_clear_search_highlight = 1

    " Disable neosnippet expansion
    " This maps over <C-k> and does some Supertab
    " emulation with snippets
    "   let g:pkk_no_neosnippet_expand = 1

    " Use powerline
    "   let g:pkk_use_powerline = 1

    " Enable powerline symbols
       "let g:airline_powerline_fonts = 0

    " vim files directory
    "   let g:pkk_consolidated_directory = <full path to desired directory>
       let g:pkk_consolidated_directory = $HOME . '/.vim/databases/'

    " This makes the completion popup strictly passive.
    " Keypresses acts normally. <ESC> takes you of insert mode, words don't
    " automatically complete, pressing <CR> inserts a newline, etc. Iff the
    " menu is open, tab will cycle through it. If a snippet is selected, <C-k>
    " expands it and jumps between fields.
    "   let g:pkk_noninvasive_completion = 1

    " Don't turn conceallevel or concealcursor
    "   let g:pkk_no_conceal = 1

    " For some colorschemes, autocolor will not work (eg: 'desert', 'ir_black')
    " Indent guides will attempt to set your colors smartly. If you
    " want to control them yourself, do it here.
    "   let g:indent_guides_auto_colors = 0
    "   autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd  guibg=#212121 ctermbg=233
    "   autocmd VimEnter,Colorscheme * :hi IndentGuidesEven guibg=#404040 ctermbg=234

    " Leave the default font and size in GVim
    "   let g:pkk_no_big_font = 1

    " Disable  omni complete
    "   let g:pkk_no_omni_complete = 1

    " Don't create default mappings for multicursors
    " See :help multiple-cursors-mappings
    "   let g:multi_cursor_use_default_mapping=0
    "   let g:multi_cursor_next_key='<C-n>'
    "   let g:multi_cursor_prev_key='<C-p>'
    "   let g:multi_cursor_skip_key='<C-x>'
    "   let g:multi_cursor_quit_key='<Esc>'
    " Require a special keypress to enter multiple cursors mode
    "   let g:multi_cursor_start_key='+'

" @}

" Basics @{

    " Identify platform @{
        silent function! OSX()
            return has('macunix')
        endfunction
        silent function! LINUX()
            return has('unix') && !has('macunix') && !has('win32unix')
        endfunction
        silent function! WINDOWS()
            return  (has('win32') || has('win64'))
        endfunction
    " @}

    " Set leader @{
        let g:mapleader = ' '
        let g:maplocalleader = '_'
    " @}

    " Windows Compatible @{
        " On Windows, also use '.vim' instead of 'vimfiles'; this makes synchronization
        " across (heterogeneous) systems easier.
        if has('win32') || has('win64')
          set runtimepath=$HOME/.vim,$VIM/vimfiles,$VIMRUNTIME,$VIM/vimfiles/after,$HOME/.vim/after

          " Be nice and check for multi_byte even if the config requires
          " multi_byte support most of the time
          if has('multi_byte')
            " Windows cmd.exe still uses cp850. If Windows ever moved to
            " Powershell as the primary terminal, this would be utf-8
            set termencoding=cp850
            setglobal fileencoding=utf-8
            " Windows has traditionally used cp1252, so it's probably wise to
            " fallback into cp1252 instead of eg. iso-8859-15.
            " Newer Windows files might contain utf-8 or utf-16 LE so we might
            " want to try them first.
            set fileencodings=ucs-bom,utf-8,utf-16le,cp1252,iso-8859-15
          endif
        endif
    " @}

    " Arrow Key Fix @{
        if &term[:4] ==# 'xterm' || &term[:5] ==# 'screen' || &term[:3] ==# 'rxvt'
            inoremap <silent> <C-[>OC <RIGHT>
        endif
    " @}

    " Setup Bundle Support @{
        set nocompatible        " Must be first line
        " The next three lines ensure that the ~/.vim/bundle/ system works
        filetype off
        set rtp+=~/.vim/bundle/Vundle.vim
        call vundle#rc()
    " @}

    " Add an UnBundle command @{
    function! UnBundle(arg, ...)
      let l:bundle = vundle#config#init_bundle(a:arg, a:000)
      call filter(g:vundle#bundles, 'v:val["name_spec"] != "' . a:arg . '"')
    endfunction

    command! -nargs=+ UnBundle call UnBundle(<args>)
    " @}

    " Detecting Filetypes @{
        augroup pkk_augroup
            autocmd!
            autocmd BufNewFile,BufRead *.html.twig set filetype=html.twig
            autocmd BufNewFile,BufRead *.coffee set filetype=coffee

            au! BufNewFile,BufRead *.arxml setf xml
            au! BufRead,BufNewFile *.txtfmt    setfiletype txtfmt

            " automatically detect messages.log files and highlight them
            au BufNewfile,BufRead messages* set filetype=dtv_logs_highlights
            au BufNewfile,BufRead logsense*[^py] set filetype=dtv_logs_highlights
            au BufNewfile,BufRead syslog* set filetype=messages
        augroup END
    " @}

    " Find project root directory @{
        "  Gets the directory for the file in the current window
        "  Or the current working dir if there isn't one for the window.
        "  Use tr to allow that other OS paths, too
        function! GetFileDir()
            if winbufnr(0) == -1
                let l:unislash = getcwd()
            else
                let l:unislash = fnamemodify(bufname(winbufnr(0)), ':p:h')
            endif
                return tr(l:unislash, '\', '/')
        endfunc

        " Starting with the current working dir, it walks up the parent folders
        " until it finds the file, or it hits the stop dir.
        " If it doesn't find it, it returns "Nothing"
        function! Find_in_parent(f_name, start_dir, stop_dir)
            let l:here = a:start_dir
            while ( strlen( l:here) > 0 )
                if filereadable( l:here . '/' . a:f_name ) || isdirectory(( l:here . '/' . a:f_name ))
                return l:here
                endif
                let l:fr = match(l:here, '/[^/]*$')
                if l:fr == -1
                break
                endif
                let l:here = strpart(l:here, 0, l:fr)
                if l:here == a:stop_dir
                break
                endif
            endwhile
            return 'Nothing'
        endfunc

        function! FindProjectRoot()
            let l:root_indicators = ['cscope.out', '.project', 'generatedFiles', '_builds', 'build.xml', 'readme.md', '.git', '.svn', 'certs', '.root', 'test']
            for l:indicator in l:root_indicators
                let l:root_dir = Find_in_parent(l:indicator,GetFileDir(),$HOME)
                if l:root_dir !=# 'Nothing'
                    return l:root_dir
                endif
            endfor
            return GetFileDir()
        endfunc
        augroup pkk_augroup
            autocmd FileType * let b:projectroot_dir = FindProjectRoot()
        augroup END
    " @}

    " Function to display folded text @{
        function! NeatFoldText()
            let l:indent = repeat(' ', indent(v:foldstart))
            let l:line2 = ''
            if &filetype ==# 'xml'
                let l:temp = substitute(getline(v:foldstart + 1), '\s\+', '', 'g')
                if strpart(l:temp, 1, 10) ==# 'SHORT-NAME'
                    let l:line2 = '-> ' . substitute(l:temp, '<[^>]*>', '', 'g') . ' '
                endif
            endif
            let l:line = l:indent . substitute(getline(v:foldstart), '\(\S\)\@<=\(\s\{4}\s*\|\t\)\| *{.*[^}]*$\|^\s\+', '', 'g') . ' ' . l:line2
            let l:lines_count = v:foldend - v:foldstart + 1
            let l:lines_count_text = '| ' . printf('%10s', l:lines_count . ' lines') . ' |'
            let l:foldchar = matchstr(&fillchars, 'fold:\zs.')
            let l:foldtextstart = strpart(l:line, 0, (winwidth(0)*2)/3)
            let l:foldtextend = l:lines_count_text . repeat(l:foldchar, 8)
            let l:foldtextlength = strlen(substitute(l:foldtextstart . l:foldtextend, '.', 'x', 'g')) + &foldcolumn
            return l:foldtextstart . repeat(l:foldchar, winwidth(0)- l:foldtextlength) . l:foldtextend
        endfunction
    " @}

    " Initialize directories @{
        function! InitializeDirectories()
            let l:parent = $HOME
            let l:prefix = '.vim'
            let l:dir_list = {
                        \ 'backup': 'backupdir',
                        \ 'views': 'viewdir',
                        \ 'swap': 'directory' }

            if has('persistent_undo')
                let l:dir_list['undo'] = 'undodir'
            endif

            " To specify a different directory in which to place the vimbackup,
            " vimviews, vimundo, and vimswap files/directories, add the following
            "   eg: let g:pkk_consolidated_directory = $HOME . '/.vim/'
            if exists('g:pkk_consolidated_directory')
                let l:common_dir = g:pkk_consolidated_directory . l:prefix
            else
                let l:common_dir = l:parent . l:prefix
            endif

            if !isdirectory(g:pkk_consolidated_directory)
                call mkdir(g:pkk_consolidated_directory)
            endif

            for [l:dirname, l:settingname] in items(l:dir_list)
                let l:directory = l:common_dir . l:dirname . '/'
                if exists('*mkdir')
                    if !isdirectory(l:directory)
                        call mkdir(l:directory)
                    endif
                endif
                if !isdirectory(l:directory)
                    echo 'Warning: Unable to create backup directory: ' . l:directory
                    echo 'Try: mkdir -p ' . l:directory
                else
                    let l:directory = substitute(l:directory, ' ', "\\\\ ", 'g')
                    exec 'set ' . l:settingname . '=' . l:directory
                endif
            endfor
        endfunction
        call InitializeDirectories()
    " @}

    " Shell command @{
        function! s:RunShellCommand(cmdline)
            botright new

            setlocal buftype=nofile
            setlocal bufhidden=delete
            setlocal nobuflisted
            setlocal noswapfile
            setlocal nowrap
            setlocal filetype=shell
            setlocal syntax=shell

            call setline(1, a:cmdline)
            call setline(2, substitute(a:cmdline, '.', '=', 'g'))
            execute 'silent $read !' . escape(a:cmdline, '%#')
            setlocal nomodifiable
            1
        endfunction

        command! -complete=file -nargs=+ Shell call s:RunShellCommand(<q-args>)
        " e.g. Grep current file for <search_term>: Shell grep -Hn <search_term> %
    " @}

" @}

" Bundles @{
    " list only the plugin groups you will use
    if !exists('g:pkk_bundle_groups')
        let g:pkk_bundle_groups=[]
        "let g:pkk_bundle_groups=['general', 'writing', 'programming', 'ultisnips', 'c', 'python', 'html',]
    endif

    " Deps @{
        Bundle 'gmarik/vundle'
        Bundle 'MarcWeber/vim-addon-mw-utils'
        Bundle 'tomtom/tlib_vim'
        if executable('ag')
            Bundle 'mileszs/ack.vim'
            let g:ackprg = 'ag --nogroup --nocolor --column --smart-case'
        elseif executable('ack-grep')
            let g:ackprg='ack-grep -H --nocolor --nogroup --column'
            Bundle 'mileszs/ack.vim'
        elseif executable('ack')
            Bundle 'mileszs/ack.vim'
        endif
    " @}

    " General @{
        if count(g:pkk_bundle_groups, 'general')
            " Plugin 'tpope/vim-dispatch'             " run tasks in background
            Plugin 'amoffat/snake'              " Write vim plugins in python
            Plugin 'skywind3000/asyncrun.vim'             " run tasks in background

            Bundle 'ctrlpvim/ctrlp.vim'
            Bundle 'tacahiroy/ctrlp-funky'

            Plugin 'ntpeters/vim-better-whitespace'
            Plugin 'tpope/vim-unimpaired'
            Plugin 'henrik/vim-indexed-search'            " Search results counter
            Plugin 'ervandew/supertab'
            Bundle 'jiangmiao/auto-pairs'
            Bundle 'tpope/vim-surround'
            Bundle 'kshenoy/vim-signature'
            Bundle 'tmhedberg/matchit'
            Bundle 'easymotion/vim-easymotion'
            Plugin 'rhysd/accelerated-jk'
            Plugin 't9md/vim-quickhl'

            Bundle 'scrooloose/nerdtree'
            Bundle 'jistr/vim-nerdtree-tabs'
            Plugin 'mtth/scratch.vim'
            Plugin 'romainl/vim-qf'  " Tame quickfix window
            Bundle 'mbbill/undotree'

            if (has('python') || has('python3')) && exists('g:pkk_use_powerline')
                Bundle 'Lokaltog/powerline', {'rtp':'/powerline/bindings/vim'}
            else
                Bundle 'vim-airline/vim-airline'
                Bundle 'vim-airline/vim-airline-themes'
            endif
            Bundle 'powerline/fonts'
            Bundle 'flazz/vim-colorschemes'
            "Plugin 'rafi/awesome-vim-colorschemes'
            " Bundle 'altercation/vim-colors-solarized'

            if !exists('g:pkk_no_views')
                Bundle 'vim-scripts/restore_view.vim'
            endif
            Bundle 'vim-scripts/sessionman.vim'
            Bundle 'mhinz/vim-signify'
            Bundle 'tpope/vim-abolish'
            Bundle 'osyo-manga/vim-over'
            Bundle 'kana/vim-textobj-user'
            Plugin 'kana/vim-operator-user'
            Plugin 'kana/vim-textobj-indent' " selecting similar indent blocks

            Bundle 'gcmt/wildfire.vim'
            Plugin 'itchyny/vim-cursorword'
            Bundle 'tpope/vim-repeat'
            Bundle 'rhysd/conflict-marker.vim'
            Bundle 'terryma/vim-multiple-cursors'
        endif
    " @}

    " Writing @{
        if count(g:pkk_bundle_groups, 'writing')
            " Plugin 'Txtfmt-The-Vim-Highlighter'     " Text highliter and formatter
            Bundle 'reedes/vim-litecorrect'
            Bundle 'reedes/vim-textobj-sentence'
            Bundle 'reedes/vim-textobj-quote'
            Bundle 'reedes/vim-wordy'
        endif
    " @}

    " Programming @{
        " General @{
            if count(g:pkk_bundle_groups, 'programming')
                " Pick one of the checksyntax, jslint, or syntastic
                Bundle 'nathanaelkane/vim-indent-guides'
                Plugin 'vim-scripts/autoload_cscope.vim'
                Plugin 'ctags.vim'                      " Use ctags
                if g:pkk_syntax_checker ==# 'ale'
                    Plugin 'w0rp/ale'
                elseif g:pkk_syntax_checker ==# 'syntastic'
                    Plugin 'vim-syntastic/syntastic'
                elseif g:pkk_syntax_checker ==# 'neomake'
                    Plugin 'neomake/neomake'
                    Plugin 'maralla/validator.vim'  " Linting on the fly
                endif
                Bundle 'tpope/vim-fugitive'
                Bundle 'mattn/webapi-vim'
                Bundle 'mattn/gist-vim'
                Bundle 'scrooloose/nerdcommenter'
                Bundle 'tpope/vim-commentary'
                Bundle 'godlygeek/tabular'
                Bundle 'luochen1990/rainbow'
                Plugin 'idanarye/vim-vebugger' " Debugging in vim
                Plugin 'Shougo/vimproc.vim' " Interactive command execution in vim
                "Plugin 'bash-support.vim'      " support for writing bash scripts

                if executable('ctags')
                    Bundle 'majutsushi/tagbar'
                endif
            endif
        " @}

        " Snippets & AutoComplete @{
            if count(g:pkk_bundle_groups, 'deoplete')
                Plugin 'Shougo/deoplete.nvim'
                Plugin 'roxma/vim-hug-neovim-rpc'
                Plugin 'zchee/deoplete-clang'
                Plugin 'roxma/nvim-yarp'
            elseif count(g:pkk_bundle_groups, 'snipmate')
                Bundle 'garbas/vim-snipmate'
                Bundle 'honza/vim-snippets'
                " Source support_function.vim to support vim-snippets.
                if filereadable(expand('~/.vim/bundle/vim-snippets/snippets/support_functions.vim'))
                    source ~/.vim/bundle/vim-snippets/snippets/support_functions.vim
                endif
            elseif count(g:pkk_bundle_groups, 'ultisnips')
                Bundle 'SirVer/ultisnips'
                Bundle 'honza/vim-snippets'
            elseif count(g:pkk_bundle_groups, 'youcompleteme')
                Bundle 'Valloric/YouCompleteMe'
                Bundle 'SirVer/ultisnips'
                Bundle 'honza/vim-snippets'
            elseif count(g:pkk_bundle_groups, 'neocomplcache')
                Bundle 'Shougo/neocomplcache'
                Bundle 'Shougo/neosnippet'
                Bundle 'Shougo/neosnippet-snippets'
                Bundle 'honza/vim-snippets'
            elseif count(g:pkk_bundle_groups, 'neocomplete')
                Bundle 'Shougo/neocomplete.vim.git'
                Bundle 'Shougo/neosnippet'
                Bundle 'Shougo/neosnippet-snippets'
                Bundle 'honza/vim-snippets'
            endif
        " @}

        " C/CPP @{
            if count(g:pkk_bundle_groups, 'c')
                Plugin 'rhysd/vim-clang-format'
                Plugin 'hari-rangarajan/CCTree'
                Plugin 'Rip-Rip/clang_complete'
                " Plugin 'LucHermitte/VimFold4C'
                "Plugin 'c.vim'                 " C - language support
            endif
        " @}

        " Python @{
            if count(g:pkk_bundle_groups, 'python')
                if count(g:pkk_python_setting, 'jedi')
                    Plugin 'davidhalter/jedi-vim'
                endif
                if count(g:pkk_python_setting, 'pymode')
                    Plugin 'klen/python-mode'
                endif
                " Plugin 'python-rope/ropevim'
                Plugin 'python_match.vim' " Jump to if else end, for break,
                Plugin 'joonty/vdebug'
                Plugin 'yssource/python.vim' " Provides some utility select, move and modify code.
                Plugin 'tmhedberg/SimpylFold'
            endif
        " @}

        " Other Languages @{
            " HTML @{
                if count(g:pkk_bundle_groups, 'html')
                    Bundle 'hail2u/vim-css3-syntax'
                    " Plugin 'chrisbra/Colorizer'
                    Plugin 'othree/xml.vim'
                    Bundle 'tpope/vim-haml'
                    " Bundle 'mattn/emmet-vim'  " editing html files
                endif
            " @}

            " Ruby @{
                if count(g:pkk_bundle_groups, 'ruby')
                    Bundle 'tpope/vim-cucumber'
                    Bundle 'tpope/vim-rails'
                    let g:rubycomplete_buffer_loading = 1
                    let g:rubycomplete_classes_in_global = 1
                    let g:rubycomplete_rails = 1
                endif
            " @}

            " Javascript @{
                if count(g:pkk_bundle_groups, 'javascript')
                    Bundle 'elzr/vim-json'
                    Bundle 'groenewege/vim-less'
                    Bundle 'pangloss/vim-javascript'
                    Bundle 'briancollins/vim-jst'
                    Bundle 'kchmck/vim-coffee-script'
                endif
            " @}

            " PHP @{
                if count(g:pkk_bundle_groups, 'php')
                    Bundle 'vim-scripts/PIV'
                    Bundle 'arnaud-lb/vim-php-namespace'
                    Bundle 'beyondwords/vim-twig'
                endif
            " @}

            " Scala @{
                if count(g:pkk_bundle_groups, 'scala')
                    Bundle 'derekwyatt/vim-scala'
                    Bundle 'derekwyatt/vim-sbt'
                    Bundle 'xptemplate'
                endif
            " @}

            " Haskell @{
                if count(g:pkk_bundle_groups, 'haskell')
                    Bundle 'travitch/hasksyn'
                    Bundle 'dag/vim2hs'
                    Bundle 'Twinside/vim-haskellConceal'
                    Bundle 'Twinside/vim-haskellFold'
                    Bundle 'lukerandall/haskellmode-vim'
                    Bundle 'eagletmt/neco-ghc'
                    Bundle 'eagletmt/ghcmod-vim'
                    Bundle 'Shougo/vimproc.vim'
                    Bundle 'adinapoli/cumino'
                    Bundle 'bitc/vim-hdevtools'
                endif
            " @}

            " Puppet @{
                if count(g:pkk_bundle_groups, 'puppet')
                    Bundle 'rodjek/vim-puppet'
                endif
            " @}

            " Go Lang @{
                if count(g:pkk_bundle_groups, 'go')
                    Bundle 'Blackrush/vim-gocode'
                    Bundle 'fatih/vim-go'
                endif
            " @}

            " Elixir @{
                if count(g:pkk_bundle_groups, 'elixir')
                    Bundle 'elixir-lang/vim-elixir'
                    Bundle 'carlosgaldino/elixir-snippets'
                    Bundle 'mattreduce/vim-mix'
                endif
            " @}
        " @}
    " @}

    " Misc @{
        if count(g:pkk_bundle_groups, 'misc')
            Bundle 'tpope/vim-markdown'
            Bundle 'greyblake/vim-preview'  "Preview for markdow language
        endif
    " @}

    " Linux specific @{
        if LINUX()
            Plugin 'christoomey/vim-tmux-navigator'
        endif
    " @}
" @}

" Plugins settings @{

    " General @{
        " quickhl @{
            nmap <Space>h <Plug>(quickhl-manual-this)
            xmap <Space>h <Plug>(quickhl-manual-this)

            nmap <Space>w <Plug>(quickhl-manual-this-whole-word)
            xmap <Space>w <Plug>(quickhl-manual-this-whole-word)

            nmap <Space>c <Plug>(quickhl-manual-clear)
            vmap <Space>c <Plug>(quickhl-manual-clear)

            nmap <Space>H <Plug>(quickhl-manual-reset)
            xmap <Space>H <Plug>(quickhl-manual-reset)

            nmap <Space>j <Plug>(quickhl-cword-toggle)
            nmap <Space>] <Plug>(quickhl-tag-toggle)
            map M <Plug>(operator-quickhl-manual-this-motion)
        " @}
        " TextObj Sentence @{
            if count(g:pkk_bundle_groups, 'writing')
                augroup textobj_sentence
                autocmd!
                autocmd FileType markdown call textobj#sentence#init()
                autocmd FileType textile call textobj#sentence#init()
                autocmd FileType text call textobj#sentence#init()
                augroup END
            endif
        " @}
        " TextObj Quote @{
            if count(g:pkk_bundle_groups, 'writing')
                augroup textobj_quote
                    autocmd!
                    autocmd FileType markdown call textobj#quote#init()
                    autocmd FileType textile call textobj#quote#init()
                    autocmd FileType text call textobj#quote#init({'educate': 0})
                augroup END
            endif
        " @}
        " vim-better-whitespaces @{
            nnoremap <leader>tw :ToggleWhitespace<CR>
            nnoremap <leader>ws :StripWhitespace<CR>

            let g:better_whitespace_filetypes_blacklist=['c', 'cpp', 'h', 'hpp', 'xml', 'arxml', 'diff', 'gitcommit', 'unite', 'qf', 'help', 'markdown']
        " @}
        " matchit @{
            if isdirectory(expand('~/.vim/bundle/matchit.zip'))
                let b:match_ignorecase = 1
            endif
        " @}
        " Tabularize @{
            if isdirectory(expand('~/.vim/bundle/tabular'))
                nmap <Leader>a& :Tabularize /&<CR>
                vmap <Leader>a& :Tabularize /&<CR>
                nmap <Leader>a= :Tabularize /^[^=]*\zs=<CR>
                vmap <Leader>a= :Tabularize /^[^=]*\zs=<CR>
                nmap <Leader>a=> :Tabularize /=><CR>
                vmap <Leader>a=> :Tabularize /=><CR>
                nmap <Leader>a: :Tabularize /:<CR>
                vmap <Leader>a: :Tabularize /:<CR>
                nmap <Leader>a:: :Tabularize /:\zs<CR>
                vmap <Leader>a:: :Tabularize /:\zs<CR>
                nmap <Leader>a, :Tabularize /,<CR>
                vmap <Leader>a, :Tabularize /,<CR>
                nmap <Leader>a,, :Tabularize /,\zs<CR>
                vmap <Leader>a,, :Tabularize /,\zs<CR>
                nmap <Leader>a<Bar> :Tabularize /<Bar><CR>
                vmap <Leader>a<Bar> :Tabularize /<Bar><CR>
            endif
        " @}
        " Session List @{
            set sessionoptions=blank,buffers,curdir,folds,tabpages,winsize
            if isdirectory(expand('~/.vim/bundle/sessionman.vim/'))
                nmap <leader>sl :SessionList<CR>
                nmap <leader>ss :SessionSave<CR>
                nmap <leader>sc :SessionClose<CR>
            endif
        " @}
        " UndoTree @{
            if isdirectory(expand('~/.vim/bundle/undotree/'))
                nnoremap <Leader>u :UndotreeToggle<CR>
                " If undotree is opened, it is likely one wants to interact with it.
                let g:undotree_SetFocusWhenToggle=1
            endif
        " @}
        " quick-scope @{
            " Trigger a highlight in the appropriate direction when pressing these keys:
            let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']

            " Trigger a highlight only when pressing f and F.
            let g:qs_highlight_on_keys = ['f', 'F']

            let g:qs_first_occurrence_highlight_color = 155       " terminal vim

            let g:qs_second_occurrence_highlight_color = 81         " terminal vim
        " @}
        " Indexed Search @{
            let g:indexed_search_dont_move = 1
            let g:indexed_search_line_info = 1
        " @}
        " ScratchBuffer @{
            if WINDOWS()
                let g:scratch_persistence_file = 'C:/Users/okr5kor/.vim/databases/scratch_buffer.txt'
            else
                let g:scratch_persistence_file = '/home/praveen/.vim/databases/scratch_buffer.txt'
            endif
            let g:scratch_autohide = 1
            let g:scratch_insert_autohide = 1
        " @}
        " Supertab @{
            let g:SuperTabDefaultCompletionType = 'context'
            let g:SuperTabContextDefaultCompletionType = '<c-n>'
        " @}
        " Vim-qf @{
            let g:qf_loclist_window_bottom=0
            let g:qf_window_bottom = 1
            let g:qf_mapping_ack_style = 1
            let g:qf_auto_resize = 1
            let g:qf_max_height = 10
            let g:qf_auto_quit = 0
            let g:qf_nowrap = 0

            let g:qf_statusline = {}
            let g:qf_statusline.before = '%<\ '
            let g:qf_statusline.after = '\ %f%=%l\/%-6L\ \ \ \ \ '

            nmap <leader>ll <Plug>qf_loc_stay_toggle
            nmap <leader>qf <Plug>qf_qf_stay_toggle
        " @}
        " Accelerated-jk @{
            "nmap j <Plug>(accelerated_jk_gj)
            "nmap k <Plug>(accelerated_jk_gk)
        " @}
        " AsyncRun @{
            let g:asyncrun_rootmarks = ['cscope.out', '.project', '.root', 'build.xml', 'generatedFiles', '_build']
            augroup asyncrun_settings_au
                autocmd!
                autocmd User AsyncRunStart call asyncrun#quickfix_toggle(8, 1)
            augroup END

            " NRCS2 project specific
            nnoremap <leader>bs :!start cmd /c cd <C-R>=b:projectroot_dir<CR> && C:/Users/okr5kor/Documents/My_Scripts/build_Premium_A2.bat && python3 C:/Users/okr5kor/Documents/My_Scripts/CopySandboxToTestPC.py<CR>
            nnoremap <leader>bl :!start cmd /c <C-R>=b:projectroot_dir . '/generatedFiles/build_log/cpj_dai_nrc2_d3/int_d3/Premium_A2_build_log.htm'<CR><CR>
            " nnoremap <leader>bs :exec "AsyncRun ".
            "             \ '-cwd='.fnameescape(b:projectroot_dir).' '.
            "             \ 'C:/Users/okr5kor/Documents/My_Scripts/build_Premium_A2.bat && python3 C:/Users/okr5kor/Documents/My_Scripts/CopySandboxToTestPC.py'<CR>
            " nnoremap <leader>bl :AsyncRun <C-R>=b:projectroot_dir . "/generatedFiles/build_log/cpj_dai_nrc2_d3/int_d3/Premium_A2_build_log.htm"<cr><cr>
        " @}
        " ctrlp @{
            if isdirectory(expand('~/.vim/bundle/ctrlp.vim/'))
                if executable('ag')
                    let s:ctrlp_fallback = 'ag %s --nocolor -l -g ""'
                elseif executable('ack-grep')
                    let s:ctrlp_fallback = 'ack-grep %s --nocolor -f'
                elseif executable('ack')
                    let s:ctrlp_fallback = 'ack %s --nocolor -f'
                " On Windows use "dir" as fallback command.
                elseif WINDOWS()
                    let s:ctrlp_fallback = 'dir %s /-n /b /s /a-d'
                else
                    let s:ctrlp_fallback = 'find %s -type f'
                endif

                nnoremap <silent> <leader>m :CtrlPMRU<CR>
                let g:ctrlp_custom_ignore = {
                    \ 'dir':  '\.git$\|\.hg$\|\.svn$\|_builds$',
                    \ 'file': '\.exe$\|\.so$\|\.dll$\|\.pyc$' }

                if LINUX()
                    let g:ctrlp_root_markers = ['.git', '.svn', '.bzr', '_darcs']
                elseif WINDOWS()
                    let g:ctrlp_root_markers = ['generatedFiles', '_builds']    " For NRCS2 project
                endif

                let g:ctrlp_working_path_mode = 'ra'
                let g:ctrlp_show_hidden = 1
                let g:ctrlp_cache_dir = $HOME.'/.vim/.cache/ctrlp'
                let g:ctrlp_max_files=0
                let g:ctrlp_max_depth=40
                let g:ctrlp_match_window = 'bottom,order:btt,min:1,max:30,results:30'

                "if exists("g:ctrlp_user_command")
                    "unlet g:ctrlp_user_command
                "endif
                "let g:ctrlp_user_command = {
                    "\ 'types': {
                        "\ 1: ['.git', 'cd %s && git ls-files . --cached --exclude-standard --others'],
                        "\ 2: ['.hg', 'hg --cwd %s locate -I .'],
                    "\ },
                    "\ 'fallback': s:ctrlp_fallback
                "\ }

                if isdirectory(expand('~/.vim/bundle/ctrlp-funky/'))
                    " CtrlP extensions
                    let g:ctrlp_extensions = ['funky']

                    "funky
                    nnoremap <Leader>fu :CtrlPFunky<Cr>
                endif
            endif
        "@}
        " vim-airline @{
            if !exists('g:pkk_use_powerline') && exists('g:airline_powerline_fonts')
                " Enable Tabline and Disable bufferline
                let g:airline#extensions#tabline#enabled = 1
                let g:airline#extensions#tabline#show_buffers = 0
                let g:airline#extensions#tabline#show_splits = 0
                let g:airline#extensions#tabline#show_tabs = 1
                let g:airline#extensions#tabline#show_tab_type = 0
                let g:airline#extensions#tabline#close_symbol = '×'
                let g:airline#extensions#tabline#show_close_button = 0

                " Tabline settings
                let g:airline_skip_empty_sections = 1
                let g:airline#extensions#tabline#tab_nr_type = 1 " tab number
                let g:airline#extensions#tabline#show_tab_nr = 1
                let g:airline#extensions#tabline#keymap_ignored_filetypes = ['vimfiler', 'nerdtree']
                let g:airline#extensions#tabline#fnamemod = ':t:.'

                " Statusline settings
                function! AirlineInit()
                    let g:airline_section_a = airline#section#create(['mode'])
                    let g:airline_section_b = airline#section#create(['branch'])
                    let g:airline_section_c = airline#section#create(['%-0.15{getcwd()}'])
                    let g:airline_section_x = airline#section#create(['ffenc'])
                    let g:airline_section_y = airline#section#create(['filetype'])
                endfunction
                augroup pkk_augroup
                    autocmd VimEnter * call AirlineInit()
                augroup END

                " See `:echo g:airline_theme_map` for some more choices
                " Default in terminal vim is 'dark'
                if isdirectory(expand('~/.vim/bundle/vim-airline-themes/'))
                    if !exists('g:airline_powerline_fonts')
                        " Use the default set of separators with a few customizations
                        let g:airline_left_sep='›'  " Slightly fancier than '>'
                        let g:airline_right_sep='‹' " Slightly fancier than '<'
                    endif

                    let g:airline_theme = 'powerlineish'
                    let g:airline_theme_patch_func = 'AirlineThemePatch'
                    function! AirlineThemePatch(palette)
                        " Theme Patching
                        " Colour palette
                        "          [GUI-FG,  GUI-BG, CTERM-FG, CTERM-BG]
                        let s:BB = ['#ffffff', '#585858', '231', '240'] " Branch and file format blocks
                        let s:N1 = ['#000000', '#afd700', '16', '148'] " Outside blocks in normal mode
                        let s:N2 = ['#808080', '#303030', '244', '236'] " Middle block

                        for l:colors in values(a:palette.inactive)
                        if &background ==# 'light'
                            let l:colors[3] = 235
                        elseif &background ==# 'dark'
                            let l:colors[3] = 250
                        endif
                        endfor
                        let a:palette.normal = airline#themes#generate_color_map(s:N1, s:BB, s:N2)
                        let a:palette.normal.airline_warning = ['#000000', '#d78700', 0, 172]
                        let a:palette.normal.airline_error = ['#000000', '#d70000', 0, 160]
                    endfunction
                endif
            endif
        " @}
        " NERDCommenter @{
            let g:NERDShutUp=1

            " Add spaces after comment delimiters by default
            let g:NERDSpaceDelims = 1

            " Use compact syntax for prettified multi-line comments
            let g:NERDCompactSexyComs = 1

            " Align line-wise comment delimiters flush left instead of following code indentation
            let g:NERDDefaultAlign = 'left'

            " Add your own custom formats or override the defaults
            let g:NERDCustomDelimiters = { 'c': { 'left': '/**','right': '*/' } }

            " Allow commenting and inverting empty lines (useful when commenting a region)
            let g:NERDCommentEmptyLines = 0

            " Enable trimming of trailing whitespace when uncommenting
            let g:NERDTrimTrailingWhitespace = 1
        " @}
        " NerdTree @{
            if isdirectory(expand('~/.vim/bundle/nerdtree'))
                map <C-e> <plug>NERDTreeMirrorToggle<CR>
                nmap <leader>nt :NERDTreeFind<CR>

                let g:NERDTreeShowBookmarks=1
                let g:NERDTreeRespectWildIgnore=1
                let g:NERDTreeIgnore=['\.py[cd]$', '\~$', '\.swo$', '\.swp$', '^\.git$', '^\.hg$', '^\.svn$', '\.bzr$']
                let g:NERDTreeChDirMode=0
                let g:NERDTreeMouseMode=2
                " let NERDTreeShowHidden=1
                let g:NERDTreeWinPos='left'
                let g:NERDTreeWinSize=30
                let g:NERDTreeCascadeSingleChildDir=1
                let g:NERDTreeCascadeOpenSingleChildDir=1
                let g:NERDTreeAutoDeleteBuffer=1
                let g:NERDTreeSortOrder=['\.c$', '\.cpp$', '\.h$', '\.hpp$', '\.py$', '\.pyw$', '\.vim$', '*']
                let g:nerdtree_tabs_open_on_gui_startup=1
                let g:nerdtree_tabs_open_on_console_startup=1
                let g:nerdtree_tabs_no_startup_for_diff=1
                let g:nerdtree_tabs_autoclose=1
                let g:nerdtree_tabs_meaningful_tab_names=1
                let g:nerdtree_tabs_open_on_new_tab=1
                let g:nerdtree_tabs_synchronize_view=1

                let g:NERDTreeMapOpenVSplit='v'
                let g:NERDTreeMapOpenSplit='s'
            endif
        " @}
        " TagBar @{
            if isdirectory(expand('~/.vim/bundle/tagbar/'))
                if !&diff
                    augroup pkk_augroup
                        autocmd FileType * nested :call tagbar#autoopen(0)
                        " autocmd BufEnter * nested :call tagbar#autoopen(0)
                    augroup END
                endif
                nnoremap <silent> <leader>tt :TagbarToggle<CR>
                let g:tagbar_width = 30
            endif
        "@}
    " @}

    " Programming @{
        " General @{
            " YouCompleteMe @{
                if count(g:pkk_bundle_groups, 'youcompleteme')
                    let g:acp_enableAtStartup = 0

                    " enable completion from tags
                    let g:ycm_collect_identifiers_from_tags_files = 1

                    let g:ycm_autoclose_preview_window_after_completion=1

                    " remap Ultisnips for compatibility for YCM
                    let g:UltiSnipsExpandTrigger = '<C-j>'
                    let g:UltiSnipsJumpForwardTrigger = '<C-j>'
                    let g:UltiSnipsJumpBackwardTrigger = '<C-k>'
                    let g:UltiSnipsEditSplit='vertical' " If you want :UltiSnipsEdit to split your window.

                    " Enable omni completion.
                    augroup pkk_augroup
                        autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
                        autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
                        autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
                        autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
                        autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags
                        autocmd FileType ruby setlocal omnifunc=rubycomplete#Complete
                        autocmd FileType haskell setlocal omnifunc=necoghc#omnifunc
                    augroup END

                    " Haskell post write lint and check with ghcmod
                    " $ `cabal install ghcmod` if missing and ensure
                    " ~/.cabal/bin is in your $PATH.
                    if !executable('ghcmod')
                        augroup pkk_augroup
                            autocmd BufWritePost *.hs GhcModCheckAndLintAsync
                        augroup END
                    endif

                    " For snippet_complete marker.
                    if !exists('g:pkk_no_conceal')
                        if has('conceal')
                            set conceallevel=2 concealcursor=i
                        endif
                    endif

                    augroup pkk_augroup
                        au FileType python map <C-]>  :YcmCompleter GoToDefinitionElseDeclaration<CR>
                    augroup END

                    " Disable the neosnippet preview candidate window
                    " When enabled, there can be too much visual noise
                    " especially when splits are used.
                    set completeopt-=preview
                endif
            " @}
            " neocomplete @{
                if count(g:pkk_bundle_groups, 'neocomplete')
                    let g:acp_enableAtStartup = 0
                    let g:neocomplete#enable_at_startup = 1
                    let g:neocomplete#enable_smart_case = 1
                    let g:neocomplete#enable_auto_delimiter = 1
                    let g:neocomplete#max_list = 15
                    let g:neocomplete#force_overwrite_completefunc = 1


                    " Define dictionary.
                    let g:neocomplete#sources#dictionary#dictionaries = {
                                \ 'default' : '',
                                \ 'vimshell' : $HOME.'/.vimshell_hist',
                                \ 'scheme' : $HOME.'/.gosh_completions'
                                \ }

                    " Define keyword.
                    if !exists('g:neocomplete#keyword_patterns')
                        let g:neocomplete#keyword_patterns = {}
                    endif
                    let g:neocomplete#keyword_patterns['default'] = '\h\w*'

                    " Plugin key-mappings @{
                        " These two lines conflict with the default digraph mapping of <C-K>
                        if !exists('g:pkk_no_neosnippet_expand')
                            imap <C-k> <Plug>(neosnippet_expand_or_jump)
                            smap <C-k> <Plug>(neosnippet_expand_or_jump)
                        endif
                        if exists('g:pkk_noninvasive_completion')
                            inoremap <CR> <CR>
                            " <ESC> takes you out of insert mode
                            inoremap <expr> <Esc>   pumvisible() ? "\<C-y>\<Esc>" : "\<Esc>"
                            " <CR> accepts first, then sends the <CR>
                            inoremap <expr> <CR>    pumvisible() ? "\<C-y>\<CR>" : "\<CR>"
                            " <Down> and <Up> cycle like <Tab> and <S-Tab>
                            inoremap <expr> <Down>  pumvisible() ? "\<C-n>" : "\<Down>"
                            inoremap <expr> <Up>    pumvisible() ? "\<C-p>" : "\<Up>"
                            " Jump up and down the list
                            inoremap <expr> <C-d>   pumvisible() ? "\<PageDown>\<C-p>\<C-n>" : "\<C-d>"
                            inoremap <expr> <C-u>   pumvisible() ? "\<PageUp>\<C-p>\<C-n>" : "\<C-u>"
                        else
                            " <C-k> Complete Snippet
                            " <C-k> Jump to next snippet point
                            imap <silent><expr><C-k> neosnippet#expandable() ?
                                        \ "\<Plug>(neosnippet_expand_or_jump)" : (pumvisible() ?
                                        \ "\<C-e>" : "\<Plug>(neosnippet_expand_or_jump)")
                            smap <TAB> <Right><Plug>(neosnippet_jump_or_expand)

                            inoremap <expr><C-g> neocomplete#undo_completion()
                            inoremap <expr><C-l> neocomplete#complete_common_string()
                            "inoremap <expr><CR> neocomplete#complete_common_string()

                            " <CR>: close popup
                            " <s-CR>: close popup and save indent.
                            inoremap <expr><s-CR> pumvisible() ? neocomplete#smart_close_popup()."\<CR>" : "\<CR>"

                            function! CleverCr()
                                if pumvisible()
                                    if neosnippet#expandable()
                                        let l:exp = "\<Plug>(neosnippet_expand)"
                                        return l:exp . neocomplete#smart_close_popup()
                                    else
                                        return neocomplete#smart_close_popup()
                                    endif
                                else
                                    return "\<CR>"
                                endif
                            endfunction

                            " <CR> close popup and save indent or expand snippet
                            imap <expr> <CR> CleverCr()
                            " <C-h>, <BS>: close popup and delete backword char.
                            inoremap <expr><BS> neocomplete#smart_close_popup()."\<C-h>"
                            inoremap <expr><C-y> neocomplete#smart_close_popup()
                        endif
                        " <TAB>: completion.
                        inoremap <expr><TAB> pumvisible() ? "\<C-n>" : "\<TAB>"
                        inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<TAB>"

                        " Courtesy of Matteo Cavalleri

                        function! CleverTab()
                            if pumvisible()
                                return "\<C-n>"
                            endif
                            let l:substr = strpart(getline('.'), 0, col('.') - 1)
                            let l:substr = matchstr(l:substr, '[^ \t]*$')
                            if strlen(l:substr) == 0
                                " nothing to match on empty string
                                return "\<Tab>"
                            else
                                " existing text matching
                                if neosnippet#expandable_or_jumpable()
                                    return "\<Plug>(neosnippet_expand_or_jump)"
                                else
                                    return neocomplete#start_manual_complete()
                                endif
                            endif
                        endfunction

                        imap <expr> <Tab> CleverTab()
                    " @}

                    " Enable heavy omni completion.
                    if !exists('g:neocomplete#sources#omni#input_patterns')
                        let g:neocomplete#sources#omni#input_patterns = {}
                    endif
                    let g:neocomplete#sources#omni#input_patterns.php = '[^. \t]->\h\w*\|\h\w*::'
                    let g:neocomplete#sources#omni#input_patterns.perl = '\h\w*->\h\w*\|\h\w*::'
                    let g:neocomplete#sources#omni#input_patterns.c = '[^.[:digit:] *\t]\%(\.\|->\)'
                    let g:neocomplete#sources#omni#input_patterns.cpp = '[^.[:digit:] *\t]\%(\.\|->\)\|\h\w*::'
                    let g:neocomplete#sources#omni#input_patterns.ruby = '[^. *\t]\.\h\w*\|\h\w*::'
            " @}
            " neocomplcache @{
                elseif count(g:pkk_bundle_groups, 'neocomplcache')
                    let g:acp_enableAtStartup = 0
                    let g:neocomplcache_enable_at_startup = 1
                    let g:neocomplcache_enable_camel_case_completion = 1
                    let g:neocomplcache_enable_smart_case = 1
                    let g:neocomplcache_enable_underbar_completion = 1
                    let g:neocomplcache_enable_auto_delimiter = 1
                    let g:neocomplcache_max_list = 15
                    let g:neocomplcache_force_overwrite_completefunc = 1

                    " Define dictionary.
                    let g:neocomplcache_dictionary_filetype_lists = {
                                \ 'default' : '',
                                \ 'vimshell' : $HOME.'/.vimshell_hist',
                                \ 'scheme' : $HOME.'/.gosh_completions'
                                \ }

                    " Define keyword.
                    if !exists('g:neocomplcache_keyword_patterns')
                        let g:neocomplcache_keyword_patterns = {}
                    endif
                    let g:neocomplcache_keyword_patterns._ = '\h\w*'

                    " Plugin key-mappings @{
                        " These two lines conflict with the default digraph mapping of <C-K>
                        imap <C-k> <Plug>(neosnippet_expand_or_jump)
                        smap <C-k> <Plug>(neosnippet_expand_or_jump)
                        if exists('g:pkk_noninvasive_completion')
                            inoremap <CR> <CR>
                            " <ESC> takes you out of insert mode
                            inoremap <expr> <Esc>   pumvisible() ? "\<C-y>\<Esc>" : "\<Esc>"
                            " <CR> accepts first, then sends the <CR>
                            inoremap <expr> <CR>    pumvisible() ? "\<C-y>\<CR>" : "\<CR>"
                            " <Down> and <Up> cycle like <Tab> and <S-Tab>
                            inoremap <expr> <Down>  pumvisible() ? "\<C-n>" : "\<Down>"
                            inoremap <expr> <Up>    pumvisible() ? "\<C-p>" : "\<Up>"
                            " Jump up and down the list
                            inoremap <expr> <C-d>   pumvisible() ? "\<PageDown>\<C-p>\<C-n>" : "\<C-d>"
                            inoremap <expr> <C-u>   pumvisible() ? "\<PageUp>\<C-p>\<C-n>" : "\<C-u>"
                        else
                            imap <silent><expr><C-k> neosnippet#expandable() ?
                                        \ "\<Plug>(neosnippet_expand_or_jump)" : (pumvisible() ?
                                        \ "\<C-e>" : "\<Plug>(neosnippet_expand_or_jump)")
                            smap <TAB> <Right><Plug>(neosnippet_jump_or_expand)

                            inoremap <expr><C-g> neocomplcache#undo_completion()
                            inoremap <expr><C-l> neocomplcache#complete_common_string()
                            "inoremap <expr><CR> neocomplcache#complete_common_string()

                            function! CleverCr()
                                if pumvisible()
                                    if neosnippet#expandable()
                                        let l:exp = "\<Plug>(neosnippet_expand)"
                                        return l:exp . neocomplcache#close_popup()
                                    else
                                        return neocomplcache#close_popup()
                                    endif
                                else
                                    return "\<CR>"
                                endif
                            endfunction

                            " <CR> close popup and save indent or expand snippet
                            imap <expr> <CR> CleverCr()

                            " <CR>: close popup
                            " <s-CR>: close popup and save indent.
                            inoremap <expr><s-CR> pumvisible() ? neocomplcache#close_popup()."\<CR>" : "\<CR>"
                            "inoremap <expr><CR> pumvisible() ? neocomplcache#close_popup() : "\<CR>"

                            " <C-h>, <BS>: close popup and delete backword char.
                            inoremap <expr><BS> neocomplcache#smart_close_popup()."\<C-h>"
                            inoremap <expr><C-y> neocomplcache#close_popup()
                        endif
                        " <TAB>: completion.
                        inoremap <expr><TAB> pumvisible() ? "\<C-n>" : "\<TAB>"
                        inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<TAB>"
                    " @}

                    " Enable omni completion.
                    augroup pkk_augroup
                        autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
                        autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
                        autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
                        autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
                        autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags
                        autocmd FileType ruby setlocal omnifunc=rubycomplete#Complete
                        autocmd FileType haskell setlocal omnifunc=necoghc#omnifunc
                    augroup END

                    " Enable heavy omni completion.
                    if !exists('g:neocomplcache_omni_patterns')
                        let g:neocomplcache_omni_patterns = {}
                    endif
                    let g:neocomplcache_omni_patterns.php = '[^. \t]->\h\w*\|\h\w*::'
                    let g:neocomplcache_omni_patterns.perl = '\h\w*->\h\w*\|\h\w*::'
                    let g:neocomplcache_omni_patterns.c = '[^.[:digit:] *\t]\%(\.\|->\)'
                    let g:neocomplcache_omni_patterns.cpp = '[^.[:digit:] *\t]\%(\.\|->\)\|\h\w*::'
                    let g:neocomplcache_omni_patterns.ruby = '[^. *\t]\.\h\w*\|\h\w*::'
                    let g:neocomplcache_omni_patterns.go = '\h\w*\.\?'
            " @}
            " Snippets for neocomplcache and neocomplete @{
                if count(g:pkk_bundle_groups, 'neocomplcache') ||
                            \ count(g:pkk_bundle_groups, 'neocomplete')

                    " Use honza's snippets.
                    let g:neosnippet#snippets_directory='~/.vim/bundle/vim-snippets/snippets'

                    " Enable neosnippet snipmate compatibility mode
                    let g:neosnippet#enable_snipmate_compatibility = 1

                    " For snippet_complete marker.
                    if !exists('g:pkk_no_conceal')
                        if has('conceal')
                            set conceallevel=2 concealcursor=i
                        endif
                    endif

                    " Enable neosnippets when using go
                    let g:go_snippet_engine = 'neosnippet'

                    " Disable the neosnippet preview candidate window
                    " When enabled, there can be too much visual noise
                    " especially when splits are used.
                    set completeopt-=preview
                endif
            " @}
            " OmniComplete @{
                elseif !exists('g:pkk_no_omni_complete')
                    " Enable omni-completion.
                    augroup pkk_augroup
                        autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
                        autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
                        autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
                        autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
                        autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags
                        autocmd FileType ruby setlocal omnifunc=rubycomplete#Complete
                        autocmd FileType haskell setlocal omnifunc=necoghc#omnifunc
                    augroup END
                endif

                if !exists('g:pkk_no_omni_complete')
                    if has('autocmd') && exists('+omnifunc')
                        autocmd Filetype *
                            \if &omnifunc == "" |
                            \setlocal omnifunc=syntaxcomplete#Complete |
                            \endif
                    endif

                    hi Pmenu  guifg=#000000 guibg=#F8F8F8 ctermfg=black ctermbg=Lightgray
                    hi PmenuSbar  guifg=#8A95A7 guibg=#F8F8F8 gui=NONE ctermfg=darkcyan ctermbg=lightgray cterm=NONE
                    hi PmenuThumb  guifg=#F8F8F8 guibg=#8A95A7 gui=NONE ctermfg=lightgray ctermbg=darkcyan cterm=NONE

                    " Some convenient mappings
                    "inoremap <expr> <Esc>      pumvisible() ? "\<C-e>" : "\<Esc>"
                    if exists('g:pkk_map_cr_omni_complete')
                        inoremap <expr> <CR>     pumvisible() ? "\<C-y>" : "\<CR>"
                    endif
                    inoremap <expr> <Down>     pumvisible() ? "\<C-n>" : "\<Down>"
                    inoremap <expr> <Up>       pumvisible() ? "\<C-p>" : "\<Up>"
                    inoremap <expr> <C-d>      pumvisible() ? "\<PageDown>\<C-p>\<C-n>" : "\<C-d>"
                    inoremap <expr> <C-u>      pumvisible() ? "\<PageUp>\<C-p>\<C-n>" : "\<C-u>"

                    " Automatically open and close the popup menu / preview window
                    au CursorMovedI,InsertLeave * if pumvisible() == 0|silent! pclose|endif
                    set completeopt=menu,preview,longest
                endif
            " @}
            " Matchit @{
                " enable matchit plugin which extends usage of % operator to match
                " more words ex. if/end def/end html tags etc.
                runtime macros/matchit.vim
            " @}

            " ALE @{
                if g:pkk_syntax_checker ==# 'ale'
                    let g:ale_fixers = {
                                \   'python': ['add_blank_lines_for_python_control_statements', 'autopep8', 'isort', 'yapf'],
                                \   'c': ['clang-format', 'clang-tidy'],
                                \   'cpp': ['clang-format', 'clang-tidy'],
                                \   'vim': ['vint'],
                                \}

                    let g:ale_linters = {
                                \   'python': ['pylint', 'flake8'],
                                \   'c': ['clang'],
                                \   'cpp': ['clang'],
                                \   'vim': ['vint'],
                                \}

                    let g:ale_c_clang_executable = 'clang'
                    let g:ale_cpp_clang_executable = 'clang'
                    augroup pkk_augroup
                        au FileType * let g:ale_c_clang_options = printf('
                                    \ -I /usr/src/linux-headers-4.10.0-32/arch/x86/include
                                    \ -I /usr/src/linux-headers-4.10.0-32/include
                                    \ -I C:\\Program\ Files\ \(x86\)\\Windows\ Kits\\10\\Include\\10.0.17134.0\\ucrt
                                    \ -I %s
                                    \ -I %s/generatedFiles/Premium_A2/include
                                    \ -I %s/generatedFiles/Premium_A2/private_include
                                    \ -I %s/generatedFiles/Premium_A2/domain_inc/cubas
                                    \ -I %s/generatedFiles/Premium_A2/domain_inc/evm
                                    \ -I %s/generatedFiles/Premium_A2/domain_inc/pdm
                                    \ ', b:projectroot_dir, b:projectroot_dir, b:projectroot_dir, b:projectroot_dir, b:projectroot_dir, b:projectroot_dir)

                        au FileType * let g:ale_cpp_clang_options = printf('
                                    \ -std=c++11
                                    \ %s
                                    \ ', g:ale_c_clang_options)
                    augroup END

                    let g:ale_python_pylint_executable = 'python3'
                    let g:ale_python_pylint_options = '-m pylint'
                    let g:ale_python_pylint_use_global = 0 " The virtualenv detection needs to be disabled.

                    let g:ale_python_flake8_executable = 'python3'
                    let g:ale_python_flake8_options = '-m flake8 --max-complexity 10 --ignore=F841'
                    let g:ale_python_flake8_use_global = 0

                    let g:ale_completion_enabled = 1

                    let g:ale_sign_column_always = 1
                    let g:airline#extensions#ale#enabled = 1
                    let g:ale_echo_msg_error_str = 'E'
                    let g:ale_echo_msg_warning_str = 'W'
                    let g:ale_echo_msg_format = '[%linter%]: (%code%) %s [%severity%]'

                    let g:ale_lint_on_text_changed = 'always'
                    let g:ale_lint_on_enter = 1

                    let g:ale_open_list = 0
                    let g:ale_keep_list_window_open = 0
                endif
            " @}
            " Neomake @{
                if g:pkk_syntax_checker ==# 'neomake'
                    let g:neomake_cpp_enabled_makers = ['clang']
                    let g:neomake_cpp_clang_maker = {
                                \ 'args': [ '-I', '/usr/src/linux-headers-4.10.0-32/include',
                                \ '-I', '/usr/src/linux-headers-4.10.0-32/arch/x86/include',
                                \ ],
                                \ }

                    let g:neomake_c_enabled_makers = ['clang']
                    let g:neomake_c_clang_maker = g:neomake_cpp_clang_maker

                    let g:neomake_python_enabled_makers = ['pylint', 'flake8']
                    let g:neomake_cpp_clang_maker = {
                                \ 'args': [ '--max-complexity', '10', ]
                                \ }

                    let g:neomake_vim_enabled_makers = ['vint']

                    let g:neomake_open_list = 2

                    call neomake#configure#automake({
                                \ 'BufWritePost': {'delay': 0},
                                \ 'BufWinEnter': {},
                                \ }, 500)

                    augroup my_neomake_signs
                        au!
                        autocmd ColorScheme *
                            \ hi NeomakeErrorSign ctermfg=darkred |
                            \ hi NeomakeWarningSign ctermfg=202
                    augroup END
                endif
            " @}
            " Validator @{
                if g:pkk_syntax_checker ==# 'neomake'
                    let g:validator_python_checkers = ['pylint', 'flake8']
                    let g:validator_cpp_checkers = ['clang']
                    let g:validator_c_checkers = ['clang']
                    let g:validator_vim_checkers = ['vint']

                    " let g:validator_error_msg_format = "[ ● %d/%d issues ]"
                    let g:validator_filetype_map = {'python.django': 'python'}
                    let g:validator_auto_open_quickfix = 0
                    let g:validator_no_loclist = 1
                    let g:validator_permament_sign = 1
                endif
            " @}
            " Syntastic  @{
                if g:pkk_syntax_checker ==# 'syntastic'
                    set statusline+=%#warningmsg#
                    set statusline+=%{SyntasticStatuslineFlag()}
                    set statusline+=%*

                    let g:syntastic_c_include_dirs = [ '../include', 'include', '../inc', '/usr/src/linux-headers-4.10.0-32/include/', '/usr/src/linux-headers-4.10.0-32-generic/include/' ]
                    let g:syntastic_cpp_include_dirs = [ '../include', 'include', '../inc', '/usr/src/linux-headers-4.10.0-32/include/', '/usr/src/linux-headers-4.10.0-32-generic/include/' ]
                    let g:syntastic_cpp_compiler_options = '-std=c++11 -Wall -Wextra -Wpedantic'
                    let g:syntastic_always_populate_loc_list = 1
                    let g:syntastic_auto_loc_list = 1
                    let g:syntastic_check_on_open = 0
                    let g:syntastic_check_on_wq = 0
                    " let g:syntastic_enable_elixir_checker = 1
                    " let g:syntastic_elixir_checkers = ["elixir"]

                    function! SyntasticCheckHook(errors)
                        if !empty(a:errors)
                            let g:syntastic_loc_list_height = min([len(a:errors), 10])+1
                        endif
                    endfunction
                endif
            " @}

            " Snippets @{
                " Setting the author var
                let g:snips_author = 'Praveen Kumar K'
                let g:snips_email = 'praveenkumark1508@gmail.com'
                let g:snips_github = 'https://github.com/praveenkumark1508'
            " @}
            " Ultisnips @{
                let g:UltiSnipsExpandTrigger='<tab>'
                " let g:UltiSnipsJumpForwardTrigger='<tab>'
                " let g:UltiSnipsJumpBackwardTrigger='<s-tab>'
                let g:UltiSnipsSnippetDirectories = ['~/.vim/UltiSnips', 'UltiSnips']
            " @}

            " VDebugger @{
                augroup pkk_augroup
                    au FileType python nnoremap <F5> :VBGstartPDB3 % <CR>
                    au FileType c,cpp nnoremap <F5> :VBGstartGDB a.out<CR>
                augroup END

                nnoremap <F2> :VBGstepIn<CR>
                nnoremap <F3> :VBGstepOver<CR>
                nnoremap <F4> :VBGstepOut<CR>

                nnoremap <F6> :VBGtoggleBreakpointThisLine<CR>
                nnoremap <F7> :VBGcontinue<CR>

                nnoremap <F9> :VBGeval
                nnoremap <F10> :VBGevalWordUnderCursor<CR>
            " @}
            " Fugitive @{
                if isdirectory(expand('~/.vim/bundle/vim-fugitive/'))
                    nnoremap <silent> <leader>gs :Gstatus<CR>
                    nnoremap <silent> <leader>gd :Gdiff<CR>
                    nnoremap <silent> <leader>gc :Gcommit<CR>
                    nnoremap <silent> <leader>gb :Gblame<CR>
                    nnoremap <silent> <leader>gl :Glog<CR>
                    nnoremap <silent> <leader>gp :Git push<CR>
                    nnoremap <silent> <leader>gr :Gread<CR>
                    nnoremap <silent> <leader>gw :Gwrite<CR>
                    nnoremap <silent> <leader>ge :Gedit<CR>
                    " Mnemonic _i_nteractive
                    nnoremap <silent> <leader>gi :Git add -p %<CR>
                    nnoremap <silent> <leader>gg :SignifyToggle<CR>
                endif
            "@}
            " indent_guides @{
                if isdirectory(expand('~/.vim/bundle/vim-indent-guides/'))
                    let g:indent_guides_enable_on_vim_startup = 1
                    let g:indent_guides_start_level = 2
                    let g:indent_guides_guide_size = 1
                    let g:indent_guides_autocmds_enabled = 0
                    let g:indent_guides_indent_levels = 15
                    let g:indent_guides_tab_guides = 0
                    let g:custom_exclude = [ 'help', 'denite', 'codi'  ]

                    if has('gui_running')
                        let g:indent_guides_auto_colors = 1
                        let g:indent_guides_color_change_percent = 3
                    else
                        let g:indent_guides_auto_colors = 0
                        if &background ==# 'dark'
                            hi IndentGuidesOdd  ctermbg=236
                            hi IndentGuidesEven ctermbg=237
                        else
                            hi IndentGuidesOdd  ctermbg=254
                            hi IndentGuidesEven ctermbg=253
                        endif
                    endif
                endif
            " @}
            " RainbowParentheses @{
                if isdirectory(expand('~/.vim/bundle/rainbow/'))
                    let g:rainbow_active = 1 "0 if you want to enable it later via :RainbowToggle

                    nnoremap <leader>rp :RainbowToggle<CR>       " Toggle it on/off

                    let g:rainbow_conf = {
                        \	'guifgs': ['#005faf', 'red', '#008700', '#d75f00', 'darkred', '#808000'],
                        \	'ctermfgs': ['25', 'red', '28', '166', 'darkred', '3'],
                        \	'operators': '_,_',
                        \	'parentheses': ['start=/(/ end=/)/ fold', 'start=/\[/ end=/\]/ fold', 'start=/{/ end=/}/ fold'],
                        \	'separately': {
                        \		'*': {},
                        \		'tex': {
                        \			'parentheses': ['start=/(/ end=/)/', 'start=/\[/ end=/\]/'],
                        \		},
                        \		'lisp': {
                        \			'guifgs': ['royalblue3', 'darkorange3', 'seagreen3', 'firebrick', 'darkorchid3'],
                        \		},
                        \		'vim': {
                        \			'parentheses': ['start=/(/ end=/)/', 'start=/\[/ end=/\]/', 'start=/{/ end=/}/ fold', 'start=/(/ end=/)/ containedin=vimFuncBody', 'start=/\[/ end=/\]/ containedin=vimFuncBody', 'start=/{/ end=/}/ fold containedin=vimFuncBody'],
                        \		},
                        \		'html': {
                        \			'parentheses': ['start=/\v\<((area|base|br|col|embed|hr|img|input|keygen|link|menuitem|meta|param|source|track|wbr)[ >])@!\z([-_:a-zA-Z0-9]+)(\s+[-_:a-zA-Z0-9]+(\=("[^"]*"|'."'".'[^'."'".']*'."'".'|[^ '."'".'"><=`]*))?)*\>/ end=#</\z1># fold'],
                        \		},
                        \		'css': 0,
                        \	}
                        \}
                endif
            " @}
        " @}
        " C/CPP @{
            " Ctags @{
                set tags=./tags;/,~/.vimtags

                " Make tags placed in .git/tags file available in all levels of a repository
                let g:gitroot = substitute(system('git rev-parse --show-toplevel'), '[\n\r]', '', 'g')
                if g:gitroot !=# ''
                    let &tags = &tags . ',' . g:gitroot . '/.git/tags'
                endif
            " @}
            " Cscope @{
                set cscopetag       " Use both cscope and ctag tagfiles

                " The following maps all invoke one of the following cscope search types:
                "   's'   symbol: find all references to the token under cursor
                "   'g'   global: find global definition(s) of the token under cursor
                "   'c'   calls:  find all calls to the function name under cursor
                "   't'   text:   find all instances of the text under cursor
                "   'e'   egrep:  egrep search for the word under cursor
                "   'f'   file:   open the filename under cursor
                "   'i'   includes: find files that include the filename under cursor
                "   'd'   called: find functions that function under cursor calls

                " To do the first type of search, hit 'CTRL-\', followed by one of the
                " cscope search types above (s,g,c,t,e,f,i,d).  The result of your cscope
                " search will be displayed in the current window.  You can use CTRL-T to
                " go back to where you were before the search.
                silent! map <unique> <C-\>s :cs find s <C-R>=expand("<cword>")<CR><CR>
                silent! map <unique> <C-\>g :cs find g <C-R>=expand("<cword>")<CR><CR>
                silent! map <unique> <C-\>d :cs find d <C-R>=expand("<cword>")<CR><CR>
                silent! map <unique> <C-\>c :cs find c <C-R>=expand("<cword>")<CR><CR>
                silent! map <unique> <C-\>t :cs find t <C-R>=expand("<cword>")<CR><CR>
                silent! map <unique> <C-\>e :cs find e <C-R>=expand("<cword>")<CR><CR>
                silent! map <unique> <C-\>f :cs find f <C-R>=expand("<cword>")<CR><CR>
                silent! map <unique> <C-\>i :cs find i <C-R>=expand("<cword>")<CR><CR>

                " Using 'CTRL-spacebar' (intepreted as CTRL-@ by vim) then a search type
                " makes the vim window split horizontally, with search result displayed in
                " the new window.
                nmap <C-@>s :scs find s <C-R>=expand("<cword>")<CR><CR>
                nmap <C-@>g :scs find g <C-R>=expand("<cword>")<CR><CR>
                nmap <C-@>c :scs find c <C-R>=expand("<cword>")<CR><CR>
                nmap <C-@>t :scs find t <C-R>=expand("<cword>")<CR><CR>
                nmap <C-@>e :scs find e <C-R>=expand("<cword>")<CR><CR>
                nmap <C-@>f :scs find f <C-R>=expand("<cfile>")<CR><CR>
                nmap <C-@>i :scs find i <C-R>=expand("<cfile>")<CR><CR>
                nmap <C-@>d :scs find d <C-R>=expand("<cword>")<CR><CR>

                " Hitting CTRL-space *twice* before the search type does a vertical
                " split instead of a horizontal one (vim 6 and up only)
                nmap <C-@><C-@>s :vert scs find s <C-R>=expand("<cword>")<CR><CR>
                nmap <C-@><C-@>g :vert scs find g <C-R>=expand("<cword>")<CR><CR>
                nmap <C-@><C-@>c :vert scs find c <C-R>=expand("<cword>")<CR><CR>
                nmap <C-@><C-@>t :vert scs find t <C-R>=expand("<cword>")<CR><CR>
                nmap <C-@><C-@>e :vert scs find e <C-R>=expand("<cword>")<CR><CR>
                nmap <C-@><C-@>f :vert scs find f <C-R>=expand("<cfile>")<CR><CR>
                nmap <C-@><C-@>i :vert scs find i <C-R>=expand("<cfile>")<CR><CR>
                nmap <C-@><C-@>d :vert scs find d <C-R>=expand("<cword>")<CR><CR>

            " @}
            " Clang-Format @{
                let g:clang_format#command = 'clang-format' " Path to the executable
                let g:clang_format#code_style = 'google'
                let g:clang_format#style_options = {
                            \ 'AccessModifierOffset' : 0,
                            \ 'AlignConsecutiveAssignments': 'true',
                            \ 'AllowShortFunctionsOnASingleLine': 'false',
                            \ 'AllowShortIfStatementsOnASingleLine' : 'false',
                            \ 'AllowShortLoopsOnASingleLine': 'false',
                            \ 'BreakBeforeBraces': 'Allman',
                            \ 'ColumnLimit' : 120,
                            \ 'IndentWidth': 4,
                            \ 'IndentPPDirectives': 'AfterHash',
                            \ 'NamespaceIndentation': 'All',
                            \ 'Standard' : 'C++11',
                            \ 'TabWidth': 4,
                            \ }

                let g:clang_format#auto_format = 0  " Format on save
                nmap <Leader>C :ClangFormatAutoToggle<CR> " Toggle auto formatting:

                augroup pkk_augroup
                    " map to <Leader>cf in C++ code
                    autocmd FileType c,cpp,objc nnoremap <buffer><Leader>cf :<C-u>ClangFormat<CR> Go<esc>
                    autocmd FileType c,cpp,objc vnoremap <buffer><Leader>cf :ClangFormat<CR>
                    " if you install vim-operator-user
                    autocmd FileType c,cpp,objc map <buffer><Leader>x <Plug>(operator-clang-format)
                augroup END
            " @}
            " Clang-Complete @{
                " path to directory where library can be found
                if LINUX()
                    let g:clang_library_path='/usr/lib/llvm-5.0/lib/libclang-5.0.so.1' " Path to libclang.so.5.0
                else
                    let g:clang_library_path = 'C:/Program Files/LLVM/bin'
                endif
            " @}
            " VimFold4C @{
                let g:fold_options = {
                            \ 'show_if_and_else': 1,
                            \ 'strip_template_arguments': 1,
                            \ 'strip_namespaces': 1,
                            \ 'max_foldline_length': 'win'
                            \ }
            " @}
        " @}
        " Python @{
            " PyMode @{
                if count(g:pkk_python_setting, 'pymode')
                    if !has('python') && !has('python3')
                        let g:pymode = 0
                    else
                        let g:pymode = 1
                    endif

                    let g:pymode_lint = 0
                    let g:pymode_syntax_slow_sync = 0
                    let g:pymode_rope_regenerate_on_write = 0
                    let g:pymode_rope_autoimport = 0
                    let g:pymode_folding = 0

                    " Disable if Jedi is there
                    let g:is_jedi = !count(g:pkk_python_setting, 'jedi')
                    let g:pymode_doc = g:is_jedi
                    let g:pymode_rope_completion = g:is_jedi
                    let g:pymode_rope_complete_on_dot = g:is_jedi
                    let g:pymode_rope = 1

                    let g:pymode_motion = 1
                    let g:pymode_doc_bind = 'K'
                    let g:pymode_run = 1
                    let g:pymode_run_bind = '<leader>r'
                    let g:pymode_rope_show_doc_bind = '<C-c>d'
                    let g:pymode_rope_completion_bind = '<C-Space>'
                    let g:pymode_rope_autoimport_bind = '<C-c>ra'
                    let g:pymode_rope_goto_definition_bind = '<C-]>'
                    let g:pymode_rope_goto_definition_cmd = 'new'
                    let g:pymode_rope_rename_bind = '<C-c>rr'
                    let g:pymode_rope_rename_module_bind = '<C-c>r1r'
                    let g:pymode_rope_organize_imports_bind = '<C-c>ro'
                    let g:pymode_rope_module_to_package_bind = '<C-c>r1p'
                    let g:pymode_rope_extract_method_bind = '<C-c>rm'
                    let g:pymode_rope_extract_variable_bind = '<C-c>rl'
                    let g:pymode_rope_use_function_bind = '<C-c>ru'
                    let g:pymode_rope_move_bind = '<C-c>rv'
                    let g:pymode_rope_change_signature_bind = '<C-c>rs'
                    let g:pymode_syntax = 1
                    let g:pymode_syntax_all = 1
                    let g:pymode_indent = 1

                    let g:pymode_trim_whitespaces = 1
                    let g:pymode_options = 0
                    let g:pymode_options_colorcolumn = 1 " Display a verticle line at 80 character

                    "Set pymode to use python3 interpreter
                    let g:pymode_python = 'python3'
                    " let g:pymode_virtualenv_path = '/home/praveen/anaconda3/'

                    "Setup pymode |quickfix| window
                    let g:pymode_quickfix_minheight = 3
                    let g:pymode_quickfix_maxheight = 6

                    "Enable breakpoint
                    let g:pymode_breakpoint = 1
                    let g:pymode_breakpoint_bind = '<leader>b'
                    let g:pymode_breakpoint_cmd = 'import ipdb; ipdb.set_trace()'
                endif

                "insert pdb set_trace
                "nnoremap <leader>b Oimport ipdb; ipdb.set_trace()<Esc>
            " @}
            " Jedi-vim @{
                let g:jedi#show_call_signatures = '2'

                let g:jedi#goto_command = '<leader>d'
                let g:jedi#goto_assignments_command = '<leader>g'
                let g:jedi#goto_definitions_command = ''
                let g:jedi#usages_command = '<leader>us'

                let g:jedi#documentation_command = 'M'
                let g:jedi#completions_command = '<C-Space>'
                let g:jedi#rename_command = '<leader>rn'
            " @}
            " Rope-Vim @{
                let g:ropevim_vim_completion=1
                let g:ropevim_extended_complete=1
                let g:ropevim_autoimport_modules = ['os', 'shutil']
                let g:ropevim_codeassist_maxfixes = 50
                let g:ropevim_enable_shortcuts = 1
                let g:ropevim_guess_project = 1

                let g:ropevim_enable_autoimport = 1
                let g:ropevim_autoimport_underlineds = 1
                let g:ropevim_goto_def_newwin = 'tabnew'
            " @}
            " simplyFold @{
                let g:SimpylFold_docstring_preview=1
                let g:SimpylFold_fold_docstring=0
                let b:SimpylFold_fold_docstring=0
                let g:SimpylFold_fold_import=1
                let b:SimpylFold_fold_import=1
            " @}
        " @}
        " Other Languages @{
            " PIV @{
                if isdirectory(expand('~/.vim/bundle/PIV'))
                    let g:DisableAutoPHPFolding = 0
                    let g:PIVAutoClose = 0
                endif
            " @}
            " GoLang @{
                if count(g:pkk_bundle_groups, 'go')
                    let g:go_highlight_functions = 1
                    let g:go_highlight_methods = 1
                    let g:go_highlight_structs = 1
                    let g:go_highlight_operators = 1
                    let g:go_highlight_build_constraints = 1
                    let g:go_fmt_command = 'goimports'
                    let g:syntastic_go_checkers = ['golint', 'govet', 'errcheck']
                    let g:syntastic_mode_map = { 'mode': 'active', 'passive_filetypes': ['go'] }
                    augroup pkk_augroup
                        au FileType go nmap <Leader>s <Plug>(go-implements)
                        au FileType go nmap <Leader>i <Plug>(go-info)
                        au FileType go nmap <Leader>e <Plug>(go-rename)
                        au FileType go nmap <leader>r <Plug>(go-run)
                        au FileType go nmap <leader>b <Plug>(go-build)
                        au FileType go nmap <leader>t <Plug>(go-test)
                        au FileType go nmap <Leader>gd <Plug>(go-doc)
                        au FileType go nmap <Leader>gv <Plug>(go-doc-vertical)
                        au FileType go nmap <leader>co <Plug>(go-coverage)
                    augroup END
                endif
                " @}
            " Vim-Colorizer @{
                let g:colorizer_auto_filetype='css,html,vim'
                let g:colorizer_skip_comments = 1
                let g:colorizer_x11_names = 1
            " @}
            " JSON @{
                nmap <leader>jt <Esc>:%!python -m json.tool<CR><Esc>:set filetype=json<CR>
                let g:vim_json_syntax_conceal = 0
            " @}
        " @}
    " @}

    " Misc @{
        " Wildfire @{
        let g:wildfire_objects = {
                    \ '*' : ["i'", 'i"', 'i)', 'i]', 'i}', 'ip'],
                    \ 'html,xml' : ['at'],
                    \ }
        " @}
    " @}

" @}

" Setting Vim options @{

    " set pastetoggle=<F2>           " pastetoggle (sane indentation on pastes)
    set ttyfast  " fast scrolling
    set lazyredraw  " for performance
    set matchtime=3  " Time to show matching paranthesis
    set title " Set title to window

    if WINDOWS()
        set shell=cmd.exe
    else
        set shell=/bin/sh
    endif
    set noshellslash
    " set shellxescape="\"&|<>()@^"
    " set shelltype=4
    " set shellxquote='\"'
    " set shellquote=''

    set mouse=a                 " Automatically enable mouse usage
    set mousehide               " Hide the mouse cursor while typing
    " Let Vim use utf-8 internally, because many scripts require this
    set encoding=utf-8

    if has('clipboard')
        if has('unnamedplus')  " When possible use + register for copy-paste
            set clipboard=unnamed,unnamedplus
        else         " On mac and Windows, use * register for copy-paste
            set clipboard=unnamed
        endif
    endif

    "set autowrite                       " Automatically write a file when leaving a modified buffer
    set shortmess+=filmnrxoOtT          " Abbrev. of messages (avoids 'hit enter')
    set viewoptions=folds,options,cursor,unix,slash " Better Unix / Windows compatibility
    set virtualedit=onemore             " Allow for cursor beyond last character
    set history=1000                    " Store a ton of history (default is 20)
    set nospell                           " Spell checking on
    set hidden                          " Allow buffer switching without saving
    set iskeyword-=.                    " '.' is an end of word designator
    set iskeyword-=#                    " '#' is an end of word designator
    set iskeyword-=-                    " '-' is an end of word designator
    set foldmethod=indent
    set foldlevel=99

    " Setting up the directories
    set backup                  " Backups are nice ...
    if has('persistent_undo')
        set undofile                " So is persistent undo ...
        set undolevels=1000         " Maximum number of changes that can be undone
        set undoreload=10000        " Maximum number lines to save for undo on a buffer reload
    endif

    if executable('ag')
      set grepprg=ag\ --nogroup\ --nocolor\ --ignore-case\ --column
      set grepformat=%f:%l:%c:%m,%f:%l:%m
    endif

    set foldtext=NeatFoldText()

    " Nicer vertical split line
    set fillchars+=vert:│

    " Redraw screen every time when focus gained
    " au FocusGained * :redraw!

    " vimdiff options
    " Always use vertical diffs
    set diffopt+=vertical

    if &diff
        colorscheme murphy
    else
        colorscheme murphy
        set background=light
        set cursorline
        if &background ==# 'light'
            hi CursorLine   gui=NONE cterm=NONE ctermbg=17 guibg=#c0c0c0 ctermfg=NONE
        else
            hi CursorLine   gui=NONE cterm=NONE ctermbg=237 guibg=#3a3a3a ctermfg=NONE
        endif
        "hi CursorLine gui=underline cterm=underline
        "hi CursorLine   cterm=NONE ctermbg=8 guibg=#555555 ctermfg=NONE   " Highlight current line
    endif

    if v:version > 703
        set relativenumber " relative line numbers
    endif

    set tabpagemax=15               " Only show 15 tabs
    set showtabline=2
    set showmode                    " Display the current mode

    if has('cmdline_info')
        set ruler                   " Show the ruler
        set rulerformat=%30(%=\:b%n%y%m%r%w\ %l,%c%V\ %P%) " A ruler on steroids
        set showcmd                 " Show partial commands in status line and
                                    " Selected characters/lines in visual mode
    endif

    if has('statusline')
        set laststatus=1

        " Broken down into easily includeable segments
        set statusline=%<%f\                     " Filename
        set statusline+=%w%h%m%r                 " Options
        set statusline+=%{fugitive#statusline()} " Git Hotness
        set statusline+=\ [%{&ff}/%Y]            " Filetype
        set statusline+=\ [%{getcwd()}]          " Current dir
        set statusline+=%=%-14.(%l,%c%V%)\ %p%%  " Right aligned file nav info
    endif

    if WINDOWS()
        set linespace=2                 " Extra spaces between rows
    else
        set linespace=0                 " No extra spaces between rows
    endif

    set backspace=indent,eol,start  " Backspace for dummies
    set number                      " Line numbers on
    set showmatch                   " Show matching brackets/parenthesis
    set incsearch                   " Find as you type search
    set hlsearch                    " Highlight search terms
    set winminheight=0              " Windows can be 0 line high
    set ignorecase                  " Case insensitive search
    set smartcase                   " Case sensitive when uc present
    set whichwrap=b,s,h,l,<,>,[,]   " Backspace and cursor keys wrap too
    set scrolljump=0                " Lines to scroll when cursor leaves screen(0 means disabling)
    set scrolloff=3                 " Minimum lines to keep above and below cursor
    set sidescrolloff=5     " Keep at least 5 lines left/right
    set foldenable                  " Auto fold code
    " set list                        " Show whitespaces as characters
    set listchars=tab:│\ ,trail:•,extends:#,nbsp:. " Highlight problematic whitespace

    set noshowmode
    set visualbell

    set wildmenu                    " Show list instead of just completing
    set wildmode=list:longest,full  " Command <Tab> completion, list matches, then longest common part, then all.
    set wildignore+=.hg,.git,.svn " Version Controls"
    set wildignore+=*.aux,*.out,*.toc "Latex Indermediate files"
    set wildignore+=*.jpg,*.bmp,*.gif,*.png,*.jpeg "Binary Imgs"
    set wildignore+=*.o,*.obj,*.exe,*.dll,*.manifest "Compiled Object files"
    set wildignore+=*.spl "Compiled speolling world list"
    set wildignore+=*.sw? "Vim swap files"
    set wildignore+=*.DS_Store "OSX SHIT"
    set wildignore+=*.luac "Lua byte code"
    set wildignore+=migrations "Django migrations"
    set wildignore+=*.pyc "Python Object codes"
    set wildignore+=*.orig,*.rej "Merge resolution files"

    set nowrap                      " Do not wrap long lines
    set linebreak
    set autoindent                  " Indent at the same level of the previous line
    set shiftwidth=4                " Use indents of 4 spaces
    set smarttab
    set expandtab                   " Tabs are spaces, not tabs
    set tabstop=4                   " An indentation every four columns
    set softtabstop=4               " Let backspace delete indent
    set nojoinspaces                " Prevents inserting two spaces after punctuation on a join (J)
    set splitright                  " Puts new vsplit windows to the right of the current
    set splitbelow                  " Puts new split windows to the bottom of the current
    "set matchpairs+=<:>             " Match, to be used with %
    "set comments=sl:/*,mb:*,elx:*/  " auto format comment blocks

    "highlight ColorColumn ctermbg=red      " set a visible line at 80 char
    "call matchadd('ColorColumn', '\%81v', 100)

    " au command for each filetypes
    "autocmd FileType go autocmd BufWritePre <buffer> Fmt

    augroup pkk_augroup
        au FileType xml,c,cpp setlocal foldmethod=syntax foldlevel=0
        au FileType c,cpp,h,hpp,vim set textwidth=119 colorcolumn=+1
        au FileType python set textwidth=79 colorcolumn=+1
        autocmd FileType haskell,puppet,ruby,yml,html,xml,javascript,css setlocal shiftwidth=2 softtabstop=2 tabstop=2

        " Workaround vim-commentary for Haskell
        autocmd FileType haskell setlocal commentstring=--\ %s

        " Workaround broken colour highlighting in Haskell
        autocmd FileType haskell,rust setlocal nospell
    augroup END

    filetype plugin indent on   " Automatically detect file types.
    syntax on                   " Syntax highlighting
    scriptencoding utf-8

    " Dictionary path, from which the words are being looked up.
    set dictionary=/usr/share/dict/words

    set backupskip=/tmp/*,/private/tmp/*" " Make Vim able to edit corntab fiels again.

" @}

" GUI Settings @{

    " GVIM- (here instead of .gvimrc)
    if has('gui_running')
        if !exists('g:pkk_no_big_font')
            if LINUX()
                set guifont=Source\ Code\ Pro\ for\ Powerline\ Regular\ 10,
                            \Andale\ Mono\ Regular\ 10,
                            \Menlo\ Regular\ 11,Consolas\ Regular\ 12,
                            \Courier\ New\ Regular\ 14
            elseif OSX()
                set guifont=Andale\ Mono\ Regular:h12,Menlo\ Regular:h11,
                            \Consolas\ Regular:h12,Courier\ New\ Regular:h14
            elseif WINDOWS()
                set guifont=DejaVu_Sans_Mono_for_Powerline:h10:cANSI:qDRAFT,
                            \Consolas_NF:h10,Menlo:h10,Consolas:h10.2,
                            \Courier_New:h10
            endif
        endif

        set guioptions-=T           " Remove the toolbar
        " set guioptions-=m           " Remove the menubar

        if WINDOWS()
            augroup pkk_augroup
                au GUIEnter * simalt ~x     " Maxize the vim window
            augroup END
        else
            set lines=41 columns=155
        endif
    else
        if &term ==# 'xterm' || &term ==# 'screen'
            set t_Co=256            " Enable 256 colors to stop the CSApprox warning and make xterm vim shine
        endif
        if !has('nvim')
            set term=screen-256color "give us 256 color schemes!
        endif
    endif

    " Resize Split When the window is resized"
    augroup pkk_augroup
        au VimResized * :wincmd =
    augroup END

" @}

" Features @{

    " Maximize split window @{
        function! OpenCurrentAsNewTab()
            let l:currentPos = getcurpos()
            tabedit %
            call setpos('.', l:currentPos)
        endfunction
        nmap <leader>+ :call OpenCurrentAsNewTab()<CR>
    " @}

    " MaximizeToggle split window @{
        "let g:id_provider = 0
        "let g:windows_state = {}
        "function! ToggleMaximize()
            "if !exists('w:window_info') || g:windows_state[w:window_info[0]]
                "let w:window_info = [g:id_provider, 1]    " [id, isparent]
                "let g:windows_state[w:window_info[0]] = 0

                "let l:currentPos = getcurpos()
                "tabedit %
                "call setpos(".", l:currentPos)

                "let w:window_info = [g:id_provider, 0]    " [id, isparent]
                "let g:id_provider = g:id_provider + 1
            "elseif exists('w:window_info') && !w:window_info[1]
                "tabclose
                "let g:windows_state[w:window_info[0]] = 1
            "endif
        "endfunction
        "nmap <leader>+ :call ToggleMaximize()<CR>
    " @}

    " Toggle background @{
        function! ToggleBG()
            let s:tbg = &background
            " Inversion
            if s:tbg ==# 'dark'
                set background=light
                hi CursorLine   gui=NONE cterm=NONE ctermbg=7 guibg=#c0c0c0 ctermfg=NONE
                if !has('gui_running')
                    hi IndentGuidesOdd  ctermbg=254
                    hi IndentGuidesEven ctermbg=253
                endif
            else
                set background=dark
                hi CursorLine   gui=NONE cterm=NONE ctermbg=237 guibg=#3a3a3a ctermfg=NONE
                if !has('gui_running')
                    hi IndentGuidesOdd  ctermbg=236
                    hi IndentGuidesEven ctermbg=237
                endif
            endif
        endfunction

        noremap <leader>bg :call ToggleBG()<CR>
    " @}

    " Modify visual mode search@{
        function! VisualSelection(direction, extra_filter) range
            let l:saved_reg = @"
            execute 'normal! vgvy'

            let l:pattern = escape(@", '\\/.*$^~[]')
            let l:pattern = substitute(l:pattern, "\n$", '', '')

            if a:direction ==# 'gv'
                call CmdLine("Ag \"" . l:pattern . "\" " )
            elseif a:direction ==# 'replace'
                call CmdLine('%s' . '/'. l:pattern . '/')
            endif

            let @/ = l:pattern
            let @" = l:saved_reg
        endfunction

        " Visual mode pressing * or # searches for the current selection
        " Super useful! From an idea by Michael Naumann
        vnoremap <silent> * :<C-u>call VisualSelection('', '')<CR>/<C-R>=@/<CR><CR>
        vnoremap <silent> # :<C-u>call VisualSelection('', '')<CR>?<C-R>=@/<CR><CR>
    " @}

    " toggle normal line numbers and relative line numbers @{
        function! NumberToggle()
          if(&relativenumber == 1)
            set norelativenumber
          else
            set relativenumber
          endif
        endfunc

        " Toggle relative line numbers
        if v:version > 703
            nnoremap <leader>tn :call NumberToggle()<cr>
        endif
    " @}

    " Restore cursor position @{
        " Restore cursor to file position in previous editing session
        " http://vim.wikia.com/wiki/Restore_cursor_to_file_position_in_previous_editing_session
        if !exists('g:pkk_no_restore_cursor')
            function! ResCur()
                if line("'\"") <= line('$')
                    silent! normal! g`"
                    return 1
                endif
            endfunction

            augroup resCur
                autocmd!
                autocmd BufWinEnter * call ResCur()
            augroup END
        endif

        " Instead of reverting the cursor to the last position in the buffer, we
        " set it to the first line when editing a git commit message
        augroup pkk_augroup
            au FileType gitcommit au! BufEnter COMMIT_EDITMSG call setpos('.', [0, 1, 1, 0])
        augroup END
    " @}

    " Make Sure that Vim returns to the same line when we reopen a file @{
        augroup line_return
            au!
            au BufReadPost *
                        \ if line("'\"") > 0 && line("'\"") <= line("$") |
                        \ execute 'normal! g`"zvzz' |
                        \ endif
        augroup END
    " @}

    " Automatically change pwd to current file dir @{
        " automatically switch to the current file directory when
        " a new buffer is opened
        if !exists('g:pkk_no_autochdir')
            augroup pkk_augroup
                autocmd BufEnter * if bufname("") !~ "^\[A-Za-z0-9\]*://" | lcd %:p:h | endif
            augroup END
            " Always switch to the current file directory
        endif
    " @}

" @}

" Code Formatting, Navigation and building @{

    let g:xml_syntax_folding = 1
    let g:python_highlight_all=1

    " Formatting @{
        " Convert a 1-line CPP function definition signature to a declaration signature
        " Use by putting the cursor anywhere on the same line as the function signature
        nnoremap _sig >>Wd2f:A;<ESC>0w

        " Put cursor over a character to align the rest of the paragraph to, then type _align
        nnoremap _align ywmvV}:s/<C-r>"/`<C-r>"/g<CR>V'v:!column -ts \`<CR>
    " @}

    " Navigation @{
        " Open previous tag in new tab
        nnoremap _t :tabnew %<CR>:tabprev<CR><C-t>

        " Move to beginning of next word, skipping non-word characters
        function! NextWord() range
            for l:i in range(1,v:count1)
                call search('\W*\<\w', 'eW')
            endfor
        endfunction
        noremap <silent> W :call NextWord()<CR>

        " Manpage for word under cursor via 'M' in command moderuntime
        runtime ftplugin/man.vim
        augroup pkk_augroup
            au FileType c,cpp,h,hpp noremap <buffer> <silent> M :exe "Man" 3 expand('<cword>') <CR>
            au FileType sh,shell noremap <buffer> <silent> M :exe "Man" expand('<cword>') <CR>
            au FileType vim noremap <buffer> <silent> M :h <C-R>=expand('<cword>')<CR><CR>
        augroup END

        " Search path for 'gf' command (e.g. open #include-d files)
        augroup pkk_augroup
            au FileType c,cpp,h,hpp set path+=/usr/include/c++/**
        augroup END

        " Find and open companion file for c and cpp @{
            function! FindCompanionFile()
                let l:current_file=expand('%:t')
                if l:current_file[-4:] ==# '.cpp'
                    cs find f %:t:r.hpp
                elseif l:current_file[-4:] ==# '.hpp'
                    cs find f %:t:r.cpp
                elseif l:current_file[-2:] ==# '.c'
                    cs find f %:t:r.h
                elseif l:current_file[-2:] ==# '.h'
                    cs find f %:t:r.c
                else
                    echo 'No companion file for the file ' l:current_file
                endif
            endfunction

            " Open compainion file, if it exists (e.g. test.h -> test.cpp), using Ctrl-C and Ctrl-H
            augroup pkk_augroup
                autocmd FileType c,cpp  nnoremap <C-C> :call FindCompanionFile()<CR>
            augroup end
        " @}
    " @}

    " Building @{
        " Build and Run single file
        augroup pkk_augroup
            if WINDOWS()
                autocmd FileType c nnoremap <leader>r :Shell bash -c "gcc % -o bin/%< && ./bin/%<"<CR>
                autocmd FileType cpp nnoremap <leader>r :Shell bash -c "g++ % -o bin/%< && ./bin/%<"<CR>
            endif
        augroup end

    " @}

" @}

" Key (re)Mappings @{

    " Automatically go to the end of pasted text
    vnoremap <silent> y y`]
    nnoremap <silent> p p`]

    " replaces selected text with test from buffer
    vnoremap p <Esc>:let current_reg = @"<CR>gvs<C-R>=current_reg<CR><Esc>`]

    " TAB and Shift-TAB in normal mode cycle buffers
    nmap <Tab> :bn<CR>
    nmap <S-Tab> :bp<CR>

    " VIM-signature plugin
    nnoremap <leader>sm :SignatureToggleSigns<cr>

    " assign q; to avoid shift pressing when searching last ex commands
    nmap q; q:
    vmap q; q:

    " REFRESH COMMANDS
    " warning: to refresh NERDTree just type 'r' being in NERD window
    " nmap <F5> :e<cr>
    " imap <F5> <ESC>l:e<cr>i

    " ack and silversearcher-ag
    " nmap  <leader>ag :exe "Ack " expand('<cword>') <CR>
    func! Search_file(word)
        if executable('ag')
            execute 'AsyncRun ag --vimgrep ' . a:word . ' %'
        elseif executable('findstr')
            execute 'AsyncRun findstr /s /n /i /p ' . a:word . ' %'
        else
            execute 'AsyncRun grep -nH ' . a:word . ' %'
        endif
    endfunc

    func! Search_sandbox(word)
        if executable('ag')
            execute 'AsyncRun ag --vimgrep ' . a:word . ' ' . b:projectroot_dir
        elseif executable('findstr')
            execute 'AsyncRun findstr /s /n /i /p ' . a:word . ' ' . b:projectroot_dir . "/*.cpp"
                        \ . ' ' . b:projectroot_dir . "/*.c"
                        \ . ' ' . b:projectroot_dir . "/*.h"
                        \ . ' ' . b:projectroot_dir . "/*.hpp"
                        \ . ' ' . b:projectroot_dir . "/*.inl"
                        \ . ' ' . b:projectroot_dir . "/*.pyw"
                        \ . ' ' . b:projectroot_dir . "/*.py"
        else
            execute 'AsyncRun grep -nH -r --include=*.c --include=*.cpp --include=*.h --include=*.py --include=*.pyw ' . a:word . ' ' . b:projectroot_dir
        endif
    endfunc

    command! -complete=file -nargs=+ Ag call Search_file(<q-args>)
    command! -complete=file -nargs=+ Agg call Search_sandbox(<q-args>)

    nnoremap <leader>ag :Ag <cword><CR>
    nnoremap <leader>agg :Agg <cword><CR>

    " Sorrounding a word with ", ', (, [, {, `  @{
        " ," Surround a word with "quotes"
        map <leader>" ysiw"
        vmap <leader>" c"<C-R>""<ESC>

        " <leader>' Surround a word with 'single quotes'
        map <leader>' ysiw'
        vmap <leader>' c'<C-R>"'<ESC>
        " <leader>) or ,( Surround a word with (parens)
        " The difference is in whether a space is put in
        map <leader>( ysiw(
        map <leader>) ysiw)
        vmap <leader>( c( <C-R>" )<ESC>
        vmap <leader>) c(<C-R>")<ESC>

        " <leader>[ Surround a word with [brackets]
        map <leader>] ysiw]
        map <leader>[ ysiw[
        vmap <leader>[ c[ <C-R>" ]<ESC>
        vmap <leader>] c[<C-R>"]<ESC>

        " <leader>{ Surround a word with {braces}
        map <leader>} ysiw}
        map <leader>{ ysiw{
        vmap <leader>} c{ <C-R>" }<ESC>
        vmap <leader>{ c{<C-R>"}<ESC>

        map <leader>` ysiw`
    " @}

    " Change inside various enclosures with Alt-" and Alt-'
    " The f makes it find the enclosure so you don't have
    " to be standing inside it
    nnoremap <leader><leader>' f'ci'
    nnoremap <leader><leader>" f"ci"
    nnoremap <leader><leader>( f(ci(
    nnoremap <leader><leader>) f)ci)
    nnoremap <leader><leader>[ f[ci[
    nnoremap <leader><leader>] f]ci]
    nnoremap <leader><leader>{ f}ci}
    nnoremap <leader><leader>} f}ci}

    "" Tab navigation mappings
    "" Go to tab by number
    noremap <leader>1 1gt
    noremap <leader>2 2gt
    noremap <leader>3 3gt
    noremap <leader>4 4gt
    noremap <leader>5 5gt
    noremap <leader>6 6gt
    noremap <leader>7 7gt
    noremap <leader>8 8gt
    noremap <leader>9 9gt

    "settings for searching and moving
    nnoremap / /\v
    vnoremap / /\v

    " Map : to ; also in command mode.
    nnoremap ; :
    vmap ; :

    " The default mappings for editing and applying the pkk configuration
    " are <leader>ev and <leader>sv respectively.
    noremap <leader>ev :tabedit ~/_vimrc<CR>:tabedit ~/.vimrc.py<CR>
    noremap <leader>sv :source ~/_vimrc<CR>

    " Easier moving in tabs and windows
    " The lines conflict with the default digraph mapping of <C-K>
    nnoremap <C-J> <C-W><C-J>
    nnoremap <C-K> <C-W><C-K>
    nnoremap <C-L> <C-W><C-L>
    nnoremap <C-H> <C-W><C-H>

    " End/Start of line motion keys act relative to row/wrap width in the
    " presence of `:set wrap`, and relative to line for `:set nowrap`.
    " Default vim behaviour is to act relative to text line in both cases
    if !exists('g:pkk_no_wrapRelMotion')
        " Same for 0, home, end, etc
        function! WrapRelativeMotion(key, ...)
            let l:vis_sel=''
            if a:0
                let l:vis_sel='gv'
            endif
            if &wrap
                execute 'normal!' l:vis_sel . 'g' . a:key
            else
                execute 'normal!' l:vis_sel . a:key
            endif
        endfunction

        " Make 0 go to the first character rather than the beginning
        " of the line. When we're programming, we're almost always
        " interested in working with text rather than empty space.

        " Map g* keys in Normal, Operator-pending, and Visual+select
        noremap $ :call WrapRelativeMotion("$")<CR>
        noremap <End> :call WrapRelativeMotion("$")<CR>
        noremap ^ :call WrapRelativeMotion("0")<CR>
        noremap <Home> :call WrapRelativeMotion("0")<CR>
        noremap 0 :call WrapRelativeMotion("^")<CR>
        " Overwrite the operator pending $/<End> mappings from above
        " to force inclusive motion with :execute normal!
        onoremap $ v:call WrapRelativeMotion("$")<CR>
        onoremap <End> v:call WrapRelativeMotion("$")<CR>
        " Overwrite the Visual+select mode mappings from above
        " to ensure the correct vis_sel flag is passed to function
        vnoremap $ :<C-U>call WrapRelativeMotion("$", 1)<CR>
        vnoremap <End> :<C-U>call WrapRelativeMotion("$", 1)<CR>
        vnoremap ^ :<C-U>call WrapRelativeMotion("0", 1)<CR>
        vnoremap <Home> :<C-U>call WrapRelativeMotion("0", 1)<CR>
        vnoremap 0 :<C-U>call WrapRelativeMotion("^", 1)<CR>
    endif

    map <S-H> gT
    map <S-L> gt
    "map <leader>t :tabnew<CR>

    " Yank from the cursor to the end of the line, to be consistent with C and D.
    nnoremap Y y$

    " Code folding options
    nmap <leader>f0 :set foldlevel=0<CR>
    nmap <leader>f1 :set foldlevel=1<CR>
    nmap <leader>f2 :set foldlevel=2<CR>
    nmap <leader>f3 :set foldlevel=3<CR>
    nmap <leader>f4 :set foldlevel=4<CR>
    nmap <leader>f5 :set foldlevel=5<CR>
    nmap <leader>f6 :set foldlevel=6<CR>
    nmap <leader>f7 :set foldlevel=7<CR>
    nmap <leader>f8 :set foldlevel=8<CR>
    nmap <leader>f9 :set foldlevel=99<CR>

    " Most prefer to toggle search highlighting rather than clear the current
    " search results.
    if exists('g:pkk_clear_search_highlight')
        nmap <silent> <leader>/ :nohlsearch<CR>
    else
        nmap <silent> <leader>/ :set invhlsearch<CR>
    endif

    " Find merge conflict markers
    map <leader>fc /\v^[<\|=>]{7}( .*\|$)<CR>

    " Shortcuts
    " Change Working Directory to that of the current file
    cmap cd. lcd %:p:h

    " Visual shifting (does not exit Visual mode)
    vnoremap < <gv
    vnoremap > >gv

    " Allow using the repeat operator with a visual selection (!)
    " http://stackoverflow.com/a/8064607/127816
    vnoremap . :normal .<CR>

    " For when you forget to sudo.. Really Write the file.
    cmap w!! w !sudo tee % >/dev/null

    " Some helpers to edit mode
    " http://vimcasts.org/e/14
    cnoremap %% <C-R>=fnameescape(expand('%:h')).'/'<cr>
    map <leader>ew :e %%
    map <leader>es :sp %%
    "map <leader>ev :vsp %%
    map <leader>et :tabe %%

    " Adjust viewports to the same size
    map <Leader>= <C-w>=

    " Map <Leader>ff to display all lines with keyword under cursor
    " and ask which one to jump to
    nmap <Leader>ff [I:let nr = input("Which one: ")<Bar>exe "normal " . nr ."[\t"<CR>

    " Easier horizontal scrolling
    map zl zL
    map zh zH

    " Easier formatting
    nnoremap <silent> <leader>q gwip

    " fullscreen mode for GVIM and Terminal, need 'wmctrl' in you PATH
    " map <silent> <F11> :call system("wmctrl -ir " . v:windowid . " -b toggle,fullscreen")<CR>

    "Enable folding with the 's'
    nnoremap s za

    " insert newline without entering into insert mode
    nnoremap <leader><CR> o<Esc>cc<ESC>

    " Pressing <leader>sp will toggle and untoggle spell checking
    map <leader>sp :setlocal spell!<cr>

    " Disable arrow movement, resize splits instead.
    nnoremap <Up>    :resize +2<CR>
    nnoremap <Down>  :resize -2<CR>
    nnoremap <Left>  :vertical resize +2<CR>
    nnoremap <Right> :vertical resize -2<CR>

" @}

" Misc @{

    " design lines for c, cpp
    iabbr /** /************************************************************************
    iabbr **/ ************************************************************************/
    iabbr //- //-----------------------------------------------------------------------
    " design lines for python
    iabbr #-- #------------------------------------------------------------------------
    iabbr #** #************************************************************************

    " Force Saving Files that Require Root Permission
    command! Sudowrite w !sudo tee % > /dev/null

" @}

if filereadable(expand("~/.vim/bundle/snake/plugin/snake.vim"))
    source ~/.vim/bundle/snake/plugin/snake.vim
endif

