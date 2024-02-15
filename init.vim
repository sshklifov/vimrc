" vim: set sw=2 ts=2 sts=2 foldmethod=marker:

call plug#begin()

Plug 'tpope/vim-sensible'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-endwise'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'

Plug 'webdevel/tabulous'
Plug 'catppuccin/nvim', { 'as': 'catppuccin' }

Plug 'tpope/vim-fugitive'
Plug 'neovim/nvim-lspconfig'

Plug 'sshklifov/debug'
Plug 'sshklifov/qsearch'
Plug 'sshklifov/qutil'

call plug#end()

packadd cfilter

" TODO :Index

""""""""""""""""""""""""""""Plugin settings"""""""""""""""""""""""""""" {{{
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Tabulous
let tabulousLabelLeftStr = ' ['
let tabulousLabelRightStr = '] '
let tabulousLabelNumberStr = ':'
let tabulousLabelNameDefault = 'Empty'
let tabulousCloseStr = ''

" Netrw
let g:netrw_hide = 1
let g:netrw_banner = 0

" sshklifov/debug
let g:termdebug_capture_msgs = 1

" sshklifov/qsearch
let g:qsearch_exclude_dirs = [".cache", ".git", "Debug", "Release"]
let g:qsearch_exclude_files = ["compile_commands.json"]

" tpope/vim-eunuch
function! s:Move(arg)
  if a:arg == ""
    echo "Did not move file"
    return
  endif

  let oldname = expand("%:p")
  let newname = s:Join(a:arg, expand("%:t"))
  
  let lua_str = 'lua vim.lsp.util.rename("' . oldname . '", "' . newname . '")'
  exe lua_str
endfunction

command! -nargs=1 -complete=dir Move call <SID>Move(<q-args>)

function! s:Rename(arg)
  if a:arg == ""
    echo "Did not rename file"
    return
  endif

  let oldname = expand("%:p")
  if stridx(a:arg, "/") < 0
    let dirname = expand("%:p:h")
    let newname = s:Join(dirname, a:arg)
  else
    let newname = a:arg
  endif

  let lua_str = 'lua vim.lsp.util.rename("' . oldname . '", "' . newname . '")'
  exe lua_str
endfunction

command! -nargs=1 -complete=file Rename call <SID>Rename(<q-args>)

function! s:Delete(bang)
  try
    let file = expand("%:p")
    exe "bw" . a:bang
    call delete(file)
  catch
    echoerr "No write since last change. Add ! to override."
  endtry
endfunction

command! -nargs=0 -bang Delete call <SID>Delete('<bang>')

" tpope/vim-commentary
autocmd BufEnter,BufNew *.fish setlocal commentstring=#\ %s
autocmd FileType vim setlocal commentstring=\"\ %s
autocmd FileType cpp setlocal commentstring=\/\/\ %s

" tpope/vim-fugitive
set diffopt-=horizontal
set diffopt+=vertical
"}}}

""""""""""""""""""""""""""""Everything else"""""""""""""""""""""""""""" {{{
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:Join(a, b)
  if a:a[-1:-1] == '/'
    return a:a . a:b
  else
    return a:a . '/' . a:b
  endif
endfunction

" Open vimrc quick (muy importante)
nnoremap <leader>ev :e ~/.config/nvim/init.vim<CR>
nnoremap <leader>lv :e ~/.config/nvim/lua/lsp.lua<CR>

cabbr Gd lefta Gdiffsplit
cabbr Gl Gclog!
cabbr Gb Git blame
cabbr Gdt Git! difftool
cabbr Gmt Git mergetool

" Git commit style settings
autocmd FileType gitcommit set spell
autocmd FileType gitcommit set tw=90

" Capture <Esc> in termal mode
tnoremap <Esc> <C-\><C-n>

" Indentation settings
set expandtab
set shiftwidth=4
set tabstop=4
set softtabstop=0
set cinoptions=L0,l1,b1,g0,t0,(s,U1,

" Display line numbers
set number
set relativenumber
set cc=101

" Smart searching with '/'
set ignorecase
set smartcase
set hlsearch
nnoremap <silent> <Space> :nohlsearch <cr>

" Typos
command! -bang Q q<bang>
command! -bang W w<bang>
command! -bang Qa qa<bang>

" Annoying quirks
set sessionoptions-=blank
set shortmess+=I
au FileType * setlocal fo-=cro
nnoremap <C-w>t <C-w>T
let mapleader = "\\"
autocmd SwapExists * let v:swapchoice = "e"

" Command completion
set wildchar=9
set wildcharm=9
set wildignore=*.o,*.out
set wildignorecase
set wildmode=full
cnoremap <expr> <Up> pumvisible() ? "\<C-p>" : "\<Up>"
cnoremap <expr> <Down> pumvisible() ? "\<C-n>" : "\<Down>"
cnoremap <expr> <Right> pumvisible() ? "\<Down>" : "\<Right>"

set scrolloff=4
set noautoread
set splitright
set nottimeout
set notimeout
set foldmethod=manual
set shell=/bin/bash

" Display better the currently selected entry in quickfix
autocmd FileType qf setlocal cursorline
" }}}

""""""""""""""""""""""""""""Appearance"""""""""""""""""""""""""""" {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
colorscheme catppuccin-frappe
highlight Structure guifg=#e78284
highlight debugBreakpoint guifg=#303446 guibg=#e78284
highlight debugBreakpointDisabled guifg=#303446 guibg=#949cbb
highlight DiffText gui=underline

set termguicolors
hi! link qfFileName Comment
hi! link netrwDir Comment
set fillchars+=vert:\|

" Show indentation
set list
set list lcs=tab:\|\ 

function! GetFileStatusLine()
  " Kind of resticts maximum returned length
  const maxwidth = 80

  " Return basename for help files
  if &ft == "help"
    return expand("%:t")
  endif
  " Empty file -> Empty string
  let filename = bufname()
  if empty(filename)
    return ""
  endif
  " No file on disk -> Display buffer only
  if !filereadable(filename)
    return filename
  endif

  let filename = expand("%:p")
  let cwd = getcwd()
  let mixedStatus = (filename[0:len(cwd)-1] == cwd)

  " Dir is not substring of file -> Display file only
  if !mixedStatus
    return s:PathShorten(filename, maxwidth)
  endif

  " Display mixed status
  let filename = filename[len(cwd)+1:]
  const sep = "> "
  return s:PathShorten(cwd . sep . filename, maxwidth)
endfunction

function! s:PathShorten(file, maxwidth)
  if empty(a:file)
    return "[No name]"
  endif
  if len(a:file) < a:maxwidth
    return a:file
  endif
  " Truncate from the left. truncPart will be substituted in place of excess symbols.
  let items = reverse(split(a:file, "/"))
  let accum = items[0]
  for item in items[1:]
    let tmp = item . "/" . accum
    if len(tmp) > a:maxwidth
      return "(..)/" . accum
    endif
    let accum = tmp
  endfor
  if a:file[0] == '/'
    return '/' . accum
  else
    return accum
  endif
endfunction

function! GetLspStatusLine()
  let serverResponses = luaeval('vim.lsp.util.get_progress_messages()')
  if empty(serverResponses)
    return ""
  endif

  function! GetServerProgress(_, status)
    if !has_key(a:status, 'message')
      return [0, 0]
    endif
    let msg = a:status['message']
    let partFiles = split(msg, "/")
    if len(partFiles) != 2
      return [0, 0]
    endif
    return [str2nr(partFiles[0]), str2nr(partFiles[1])]
  endfunction

  let serverProgress = map(serverResponses, function("GetServerProgress"))

  let totalFiles = 0
  let totalDone = 0
  for progress in serverProgress
    let totalDone += progress[0]
    let totalFiles += progress[1]
  endfor

  if totalFiles == 0
    return ""
  endif

  let percentage = (100 * totalDone) / totalFiles
  return percentage . "%"
endfunction

function! BranchStatusLine()
  let res = FugitiveStatusline()
  if empty(res)
    return res
  endif
  let res = substitute(res, "\\[Git(", "", "")
  let res = substitute(res, ")\\]", "", "")
  return res . ">"
endfunction

set statusline=
set statusline+=%(%{BranchStatusLine()}\ %)
set statusline+=%(%{GetFileStatusLine()}\ %{GetLspStatusLine()}%m%h%r%)
set statusline+=%=
set statusline+=%(%l,%c\ %10.p%%%)

function! s:SynStack()
  if !exists("*synstack")
    return
  endif
  echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")')
endfunc

command! -nargs=0 CursorSym call <SID>SynStack()
" }}}

""""""""""""""""""""""""""""IDE maps"""""""""""""""""""""""""""" {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

nnoremap <leader><leader>q :mksession! ~/.local/share/nvim/session.vim<CR>
nnoremap <leader>so :so ~/.local/share/nvim/session.vim<CR>
set sessionoptions=buffers,curdir,folds,help,localoptions,options,tabpages,winsize

nnoremap <silent> <leader>cd :lcd %:p:h<CR>
nnoremap <silent> <leader>gcd :Gcd<CR>

nnoremap <silent> <leader>ta :tabnew<CR><C-O>
nnoremap <silent> <leader>tc :tabclose<CR>

nnoremap <silent> <leader>unix :set ff=unix<CR>
nnoremap <silent> <leader>dos :set ff=dos<CR>

" copy-pasting
nnoremap <leader>y "+y
nnoremap <leader>Y "+Y
xnoremap <leader>y "+y
xnoremap <leader>Y "+Y
nnoremap <silent> <leader>p :set
      \ paste <Bar> exe 'silent! normal! "+p' <Bar> set nopaste<CR>
nnoremap <silent> <leader>P :set
      \ paste <Bar> exe 'silent! normal! "+P' <Bar> set nopaste<CR>
xnoremap <silent> <leader>p :<C-W>set
      \ paste <Bar> exe 'silent! normal! gv"+p' <Bar> set nopaste<CR>
xnoremap <silent> <leader>P :<C-W>set
      \ paste <Bar> exe 'silent! normal! gv"+P' <Bar> set nopaste<CR>

command! -bar Retab set invexpandtab | retab!

function! s:ToggleDiff()
  let winids = gettabinfo(tabpagenr())[0]["windows"]
  let fugitive_winids = []
  let diff_winids = []
  for winid in winids
    let winnr = win_id2tabwin(winid)[1]
    let bufnr = winbufnr(winnr)
    let name = bufname(bufnr)
    if win_execute(winid, "echon &diff") == "1"
      call add(diff_winids, winid)
    endif
    if name =~# "^fugitive:///"
      call add(fugitive_winids, winid)
    endif
  endfor

  if len(winids) == 1 && len(diff_winids) == 0 && len(fugitive_winids) == 0
    if exists("b:commitish") && b:commitish != "0"
      exe "lefta Gdiffsplit " . b:commitish
    else
      exe "lefta Gdiffsplit"
    endif
    return
  elseif len(winids) == 2 && len(diff_winids) == 2 && len(fugitive_winids) == 1
    let winid = fugitive_winids[0]
    let winnr = win_id2tabwin(winid)[1]
    let bufnr = winbufnr(winnr)
    let name = bufname(bufnr)
    let commitish = split(FugitiveParse(name)[0], ":")[0]
    let realnr = bufnr(FugitiveReal(name))
    " Memorize the last diff commitish for the buffer
    call win_gotoid(winid)
    exe "b " . realnr
    let b:commitish = commitish
    " Close fugitive window
    quit
  else
    echo "You done fucked up..."
  endif
endfunction

nnoremap <silent> <leader>dif :call <SID>ToggleDiff()<CR>

set updatetime=500
set completeopt=menuone
inoremap <silent> <C-Space> <C-X><C-O>

" http://vim.wikia.com/wiki/Automatically_append_closing_characters
inoremap {<CR> {<CR>}<C-o>O

nmap <leader>sp :setlocal invspell<CR>
" }}}

""""""""""""""""""""""""""""Code navigation"""""""""""""""""""""""""""" {{{
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:GoToNextItem(dir)
  if &foldmethod == "diff"
    if a:dir == "prev"
      exe "normal! [c"
    elseif a:dir == "next"
      exe "normal! ]c"
    endif
    return
  endif

  let listProps = getqflist({"size": 1, "idx": 0})
  let cmd = "c" . a:dir
  let size = listProps["size"]
  let idx = listProps["idx"]
  if size == 0
    return
  endif

  if (a:dir == "next" && idx < size) ||
        \ (a:dir == "prev" && idx > 1) ||
        \ (a:dir == "first" || a:dir == "last")
    copen
    exe cmd
  endif
endfunction

nnoremap <silent> [c :call <SID>GoToNextItem("prev")<CR>
nnoremap <silent> ]c :call <SID>GoToNextItem("next")<CR>
nnoremap <silent> [C :call <SID>GoToNextItem("first")<CR>
nnoremap <silent> ]C :call <SID>GoToNextItem("last")<CR>

" Navigate blocks
nnoremap [b [{
nnoremap ]b ]}

" Navigate folds
nnoremap [z zo[z
nnoremap ]z zo]z

function! s:OpenSource()
  let extensions = [".cpp", ".c", ".cc"]
  for ext in extensions
    let file = expand("%:r") . ext
    if filereadable(file)
      exe "edit " . file
      return
    endif

    let file = substitute(file, "include", "src", "")
    if filereadable(file)
      exe "edit " . file
      return
    endif
  endfor

  " Default to search in root of workspace
  call FindInQuickfix(FugitiveWorkTree(), expand("%:t:r") . ".c")
endfunction

function! s:OpenHeader()
  let extensions = [".h", ".hpp", ".hh"]
  for ext in extensions
    let file = expand("%:r") . ext
    if filereadable(file)
      exe "edit " . file
      return
    endif

    let file = substitute(file, "src", "include", "")
    if filereadable(file)
      exe "edit " . file
      return
    endif
  endfor

  " Default to search in root of workspace
  call FindInQuickfix(FugitiveWorkTree(), expand("%:t:r") . ".h")
endfunction

nmap <silent> <leader>cpp :call <SID>OpenSource()<CR>
nmap <silent> <leader>hpp :call <SID>OpenHeader()<CR>

function! s:EditFugitive()
  let actual = bufname()
  let real = FugitiveReal()
  if actual != real
    let pos = getpos(".")
    exe "edit " . FugitiveReal()
    call setpos(".", pos)
  endif
endfunction

nnoremap <silent> <leader>fug :call <SID>EditFugitive()<CR>
"}}}

""""""""""""""""""""""""""""DEBUGGING"""""""""""""""""""""""""""" {{{
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

command! -nargs=? -complete=customlist,ExeCompl Start call s:Debug({"exe": empty(<q-args>) ? "a.out" : <q-args>})
command! -nargs=? -complete=customlist,ExeCompl Run call s:Debug({"exe": empty(<q-args>) ? "a.out" : <q-args>, "br": <SID>GetDebugLoc()})

function! ExeCompl(ArgLead, CmdLine, CursorPos)
  if a:CursorPos < len(a:CmdLine)
    return []
  endif

  " Apply 'smartcase' to the regex
  if a:ArgLead =~# "[A-Z]"
    let regex = "-regex"
  else
    let regex = "-iregex"
  endif
  let pat = ".*" . a:ArgLead . ".*"

  let cmd = ["find", ".", '(', "-path", "**/.git", "-prune", "-false", "-o", regex, pat, ')']
  let cmd += ["-type", "f", "-executable", "-printf", "%P\n"]
  return split(system(cmd), nr2char(10))
endfunction

command! -nargs=1 -complete=customlist,AttachCompl Attach call s:Debug({"proc": <q-args>})

function! AttachCompl(ArgLead, CmdLine, CursorPos)
  if a:CursorPos < len(a:CmdLine)
    return []
  endif

  let cmdlines = split(system(["ps", "h", "-U", $USER, "-o", "command"]), nr2char(10))
  let compl = []
  for cmdline in cmdlines
    let name = split(cmdline, " ")[0]
    if executable(name) && stridx(name, a:ArgLead) >= 0
      call add(compl, name)
    endif
  endfor
  let compl = uniq(sort(compl))
  return compl
endfunction

" Available modes:
" - exe. Pass executable + arguments
" - proc. Process name or pid to attach.
" Other arguments:
" - symbols. Whether to load symbols or not. Used for faster loading of gdb.
" - ssh. Launch GDB over ssh with the given address.
" - br. Works only with exe mode. Will run process and place a breakpoint.
function! s:Debug(args)
  if TermDebugIsOpen()
    echoerr 'Terminal debugger already running, cannot run two'
    return
  endif

  " Resolve process name early
  let proc = get(a:args, "proc", "")
  if proc !~ "^[0-9]*$"
    let pids = split(system(["pgrep", "-f", proc]), nr2char(10))
    " Report error
    if len(pids) == 0
      echo "No processes found"
      return
    elseif len(pids) > 1
      echo "Multiple processes found"
      return
    endif
    " Resolve to pid
    let a:args["proc"] = pids[0]
  endif

  autocmd User TermdebugStopPre call s:DebugStopPre()
  exe "autocmd User TermdebugStartPost call s:DebugStartPost(" . string(a:args) . ")"

  if has_key(a:args, "ssh")
    call TermDebugStartSSH(a:args["ssh"])
  else
    call TermDebugStart()
  endif
endfunction

function! s:DebugStartPost(args)
  let quickLoad = has_key(a:args, "symbols") && !a:args["symbols"]

  nnoremap <silent> <leader>v :call TermDebugSendCommand("p " . expand('<cword>'))<CR>
  vnoremap <silent> <leader>v :call TermDebugSendCommand("p " . <SID>GetRangeExpr())<CR>
  nnoremap <silent> <leader>br :call TermDebugSendCommand("br " . <SID>GetDebugLoc())<CR>
  nnoremap <silent> <leader>tbr :call TermDebugSendCommand("tbr " . <SID>GetDebugLoc())<CR>
  nnoremap <silent> <leader>unt :call TermDebugSendCommand("tbr " . <SID>GetDebugLoc())<BAR>call TermDebugSendCommand("c")<CR>
  nnoremap <silent> <leader>pc :call TermDebugGoToPC()<CR>

  call TermDebugSendCommand("set debug-file-directory /dev/null")
  call TermDebugSendCommand("set print asm-demangle on")
  call TermDebugSendCommand("set print pretty on")
  call TermDebugSendCommand("set print frame-arguments none")
  call TermDebugSendCommand("set print raw-frame-arguments off")
  call TermDebugSendCommand("set print entry-values no")
  call TermDebugSendCommand("set print inferior-events off")
  call TermDebugSendCommand("set print thread-events off")
  call TermDebugSendCommand("set print object on")
  call TermDebugSendCommand("set breakpoint pending on")
  call TermDebugSendCommand("set debuginfod enabled off")
  if quickLoad
    call TermDebugSendCommand("set auto-solib-add off")
  endif
  
  if has_key(a:args, "proc")
    call TermDebugSendCommand("attach " . a:args["proc"])
  elseif has_key(a:args, "exe")
    let cmdArgs = split(a:args["exe"], " ")
    call TermDebugSendCommand("file " . cmdArgs[0])
    if len(cmdArgs) > 1
      call TermDebugSendCommand("set args " . join(cmdArgs[1:], " "))
    endif
    " Either start or run process
    if has_key(a:args, "br")
      call TermDebugSendCommand("tbr " . a:args["br"])
      call TermDebugSendCommand("run")
    else
      call TermDebugSendCommand("start")
    endif
  endif

  if TermDebugGetPid() > 0
    call TermDebugSendCommand("set scheduler-locking step")
    call TermDebugSendCommand("set disassembly-flavor intel")
  endif
endfunction

function! s:DebugStopPre()
  autocmd! User TermdebugStopPre
  autocmd! User TermdebugStartPost
  execute "Source" | setlocal so=4

  nunmap <silent> <leader>v
  vunmap <silent> <leader>v
  nunmap <silent> <leader>br
  nunmap <silent> <leader>tbr
  nunmap <silent> <leader>unt
  nunmap <silent> <leader>pc
endfunction

function! s:GetDebugLoc()
  const absolute = v:false
  if absolute
    let file = expand("%:p")
  else
    let file = expand("%:t")
  endif
  let ln = line(".")
  return file.":".ln
endfunction

function! s:GetRangeExpr()
  let [lnum1, col1] = getpos("'<")[1:2]
  let [lnum2, col2] = getpos("'>")[1:2]
  let lines = getline(lnum1, lnum2)
  let lines[-1] = lines[-1][:col2 - 1]
  let lines[0] = lines[0][col1 - 1:]
  let expr = join(lines, "\n")
  return expr
endfunction

command! -nargs=0 -bar TermDebugMessages tabnew | exe "b " . bufnr("Gdb messages")
"}}}

""""""""""""""""""""""""""""LSP"""""""""""""""""""""""""""" {{{
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
command! LspStop lua vim.lsp.stop_client(vim.lsp.get_active_clients())
command! LspProg lua print(vim.inspect(vim.lsp.util.get_progress_messages()))

command! -range=% For lua vim.lsp.buf.format{ range = {start= {<line1>, 0}, ["end"] = {<line2>, 0}} }

" Document highlight
highlight LspReferenceText gui=underline
highlight! link LspReferenceRead LspReferenceText
highlight! link LspReferenceWrite LspReferenceText

" Class highlight
highlight! link @lsp.type.class.cpp @lsp.type.type
highlight! link @lsp.type.parameter.cpp @lsp.type.variable
highlight! link @lsp.typemod.method.defaultLibrary Function
highlight! link @lsp.typemod.function.defaultLibrary Function

lua require('lsp')

autocmd User LspProgressUpdate redrawstatus
autocmd User LspRequest redrawstatus
"}}}
