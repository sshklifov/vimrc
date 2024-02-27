" vim: set sw=2 ts=2 sts=2 foldmethod=marker:

call plug#begin()

Plug 'tpope/vim-sensible'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-endwise'
Plug 'tpope/vim-surround'

Plug 'webdevel/tabulous'
Plug 'catppuccin/nvim', { 'as': 'catppuccin' }

Plug 'tpope/vim-fugitive'
Plug 'neovim/nvim-lspconfig'
Plug 'tpope/vim-sleuth'

Plug 'sshklifov/debug'
Plug 'sshklifov/qsearch'
Plug 'sshklifov/qutil'

call plug#end()

packadd cfilter

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
let g:qsearch_exclude_dirs = [".cache", ".git", "Debug", "Release", "build"]
let g:qsearch_exclude_files = ["compile_commands.json"]

" tpope/vim-eunuch
function! s:Move(arg)
  if a:arg == ""
    echo "Did not move file"
    return
  endif

  let oldname = expand("%:p")
  let newname = a:arg . "/" . expand("%:t")
  
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
    let newname = dirname . "/" . a:arg
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

" Indentation settings (will be overriden by vim-sleuth)
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

" Modules which want to write to the progress portion of the statusline can add their keys here
let g:statusline_dict = #{}
" Must register modules here. When multiple modules have progress output, items at the front of the
" list will take precedence
let g:statusline_prio = ['make', 'lsp']
call dictwatcheradd(g:statusline_dict, '*', {d, k, z -> execute('redrawstatus')})

function! GetProgressStatusLine(...)
  for key in g:statusline_prio
    if has_key(g:statusline_dict, key) && !empty(g:statusline_dict[key])
      return g:statusline_dict[key]
    endif
  endfor
  return ''
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
set statusline+=%(%{GetFileStatusLine()}\ %{GetProgressStatusLine()}%m%h%r%)
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
set sessionoptions=buffers,curdir,help,localoptions,options,tabpages,winsize

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
  cclose " TODO patch
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

function! s:Review()
  if exists("g:review_stack")
    call setqflist([], ' ', #{title: "Review", items: g:review_stack[-1]})
    copen
    return
  endif

  let dict = FugitiveExecute(["log", "origin/main..HEAD", "--pretty=format:%H"])
  if dict['exit_status'] != 0
    echo "Review failed, have you checked out the branch?"
    return
  endif

  let commit = dict['stdout'][-1]
  let dict = FugitiveExecute(["log", "--format=%B", "-n", "1", commit])
  if dict['exit_status'] == 0
    let message = dict['stdout'][0]
    if message !~# ".*SW-[0-9][0-9][0-9][0-9].*"
      let dict = FugitiveExecute(["rev-parse", commit . "~1"])
      if dict['exit_status'] == 0
        let bpoint = dict['stdout'][0]
      endif
    endif
  endif
  if !exists('bpoint')
    echo "Could not determine branch point, have you fetched main?"
    return
  endif

  exe "Git difftool --name-only " . bpoint
  call setqflist([], 'a', #{title: "Review"})
  let bufs = map(getqflist(), "v:val.bufnr")
  for b in bufs
    call setbufvar(b, "commitish", bpoint)
  endfor
  let g:review_stack = [getqflist()]
endfunction

command! -nargs=0 Review call <SID>Review()

function! s:ReviewCompleteFiles(cmd_bang, pat) abort
  if !exists("g:review_stack")
    echo "Start a review first"
    return
  endif

  let new_items = copy(g:review_stack[-1])
  if !empty(a:pat)
    let comp = a:cmd_bang == "!" ? "!=" : "=="
    let new_items = filter(new_items, "match(bufname(v:val.bufnr), '" . a:pat . "') " . comp . " -1")
  else
    let comp = a:cmd_bang == "!" ? "== " : "!= "
    let new_items = filter(new_items, "v:val.bufnr " . comp . bufnr("%"))
  endif
  call setqflist([], ' ', #{title: "Review", items: new_items})
  call add(g:review_stack, new_items)

  if empty(new_items)
    echo "Review completed!"
  else
    copen
  endif
endfunction

command! -bang -nargs=? -complete=customlist,BufferCompl Complete  call <SID>ReviewCompleteFiles('<bang>', <q-args>)

function! s:UncompleteFiles()
  if !exists("g:review_stack")
    echo "Start a review first"
    return
  endif
  if len(g:review_stack) > 1
    call remove(g:review_stack, -1)
    call setqflist([], ' ', #{title: "Review", items: g:review_stack[-1]})
    copen
  end
endfunction

command! -nargs=0 Uncomplete call <SID>UncompleteFiles()
" }}}

""""""""""""""""""""""""""""Code navigation"""""""""""""""""""""""""""" {{{
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:GoToNextItem(dir)
  if &diff
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
  " 1-based index
  let idx = listProps["idx"]
  if size == 0
    return
  endif

  if (a:dir == "next" && idx < size) ||
        \ (a:dir == "prev" && idx > 1) ||
        \ (a:dir == "first" || a:dir == "last")
    copen
    silent! exe cmd
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

function! s:Context(reverse)
  call search('^\(@@ .* @@\|[<=>|]\{7}[<=>|]\@!\)', a:reverse ? 'bW' : 'W')
endfunction

nnoremap <silent> [n :call <SID>Context(v:true)<CR>
nnoremap <silent> ]n :call <SID>Context(v:false)<CR>
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

function! s:UpdateLspProgress() 
  let serverResponses = luaeval('vim.lsp.util.get_progress_messages()')
  if empty(serverResponses)
    silent! unlet g:statusline_dict.lsp
    return
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
    silent! unlet g:statusline_dict.lsp
    return
  endif

  let percentage = (100 * totalDone) / totalFiles
  let g:statusline_dict.lsp = percentage . "%"
endfunction

autocmd User LspProgressUpdate call <SID>UpdateLspProgress()

function! s:Index()
  let source = ["c", "cc", "cp", "cxx", "cpp", "CPP", "c++", "C"]
  let header = ["h", "hh", "H", "hp", "hxx", "hpp", "HPP", "h++", "tcc"]
  let regex = '.*\.\(' . join(source, '\|') . '\|' . join(header, '\|') . '\)'
  let files = split(system(["find", FugitiveWorkTree(), "-regex", regex]), nr2char(10))
  let items = map(files, "#{lnum: 1, col: 1, filename: v:val}")
  call setqflist([], ' ', #{title: "Index", items: items})
  copen
endfunction

command! -nargs=0 Index call <SID>Index()

function! TypeHierarchyHandler(res, encoding)
  let items = []
  if has_key(a:res, "children")
    let items = a:res.children
  elseif has_key(a:res, "parents")
    let items = a:res.parents
  endif

  if len(items) == 1
    let fname = v:lua.vim.uri_to_fname(items[0].uri)
    let line = items[0].range.start.line + 1
    let col = items[0].range.start.character + 1
    exe "edit " . fname
    call cursor(line, col)
  elseif len(items) > 1
    let items = v:lua.vim.lsp.util.locations_to_items(items, a:encoding)
    call setqflist([], ' ', #{title: 'Hierarchy', items: items})
    copen
  endif
endfunction

function! AstHandler(buf, kinds, res)
  " Find first CXXRecord (class/struct/union)
  let queue = [a:res]
  while !empty(queue)
    let head = queue[0]
    call remove(queue, 0)
    if head.kind == 'CXXRecord'
      break
    endif
    if has_key(head, 'children')
      let queue += head.children
    endif
  endwhile

  " Load all child methods
  if head.kind == 'CXXRecord'
    let items = []
    let queue = [head]
    while !empty(queue)
      let head = queue[0]
      call remove(queue, 0)
      if index(a:kinds, head.kind) >= 0
        let lnum = head.range.start.line + 1
        let col = head.range.start.character + 1
        let text = readfile(bufname(a:buf))[lnum-1][col-1:]
        call add(items, #{bufnr: a:buf, lnum: lnum, col: col, text: text})
      endif
      if has_key(head, 'children')
        let queue += head.children
      endif
    endwhile
    call sort(items, {a, b -> a.lnum - b.lnum})
    call setqflist([], ' ', #{title: 'AST', items: items})
    copen
  endif
endfunction

function! SwitchSourceHeaderHandler(res)
  exe "edit " . v:lua.vim.uri_to_fname(a:res)
endfunction

function! ReferenceContainerHandler(res)
  let items = map(a:res, "#{
        \ filename: v:lua.vim.uri_to_fname(v:val.uri),
        \ lnum: v:val.range.start.line + 1,
        \ col: v:val.range.start.character + 1,
        \ text: v:val.containerName}")
  call sort(items, {a, b -> a.lnum - b.lnum})
  call setqflist([], ' ', #{title: "References", items: items})
  copen
endfunction

function! s:LspRequestSync(buf, method, params)
  let resp = v:lua.vim.lsp.buf_request_sync(a:buf, a:method, a:params)
  if type(resp) != type([]) || len(resp) == 0
    return #{}
  endif
  if type(resp[0]) != type(#{}) || !has_key(resp[0], "result")
    return #{}
  endif
  return resp[0].result
endfunction

function! SymbolInfo()
  let params = v:lua.vim.lsp.util.make_position_params()
  let resp = s:LspRequestSync(0, 'textDocument/symbolInfo', params)
  return resp[0]
endfunction

command! -nargs=0 Info echo SymbolInfo()

function! SyntaxTreeCword()
  let line = getpos('.')[1] - 1
  let char = getpos('.')[2] - 1
  let range = #{start: #{line: line, character: char}, end: #{line: line, character: char + 1}}
  let params = #{textDocument: #{uri: v:lua.vim.uri_from_bufnr(0)}, range: range}
  let resp =  s:LspRequestSync(0, 'textDocument/ast', params)
  return resp
endfunction

command! -nargs=0 Tree echo SyntaxTreeCword()

function! s:Instances()
  let params = v:lua.vim.lsp.util.make_position_params()
  let resp = s:LspRequestSync(0, 'textDocument/references', params)
  if empty(resp)
    echo "No response"
    return
  endif
  let info = SymbolInfo()
  let excludeContainer = get(info, "containerName", "") . info.name

  let items = []
  for ref in resp
    if stridx(ref.containerName, excludeContainer) < 0
      let fname = v:lua.vim.uri_to_fname(ref.uri)
      let lnum = ref.range.start.line + 1
      let col = ref.range.start.character + 1
      let text = readfile(fname)[lnum-1][col-1:]
      call add(items, #{filename: fname, lnum: lnum, col: col, text: text})
    endif
  endfor
  if empty(items)
    echo "No instances"
  else
    call sort(items, {a, b -> a.lnum - b.lnum})
    call setqflist([], ' ', #{title: "Instances", items: items})
    copen
  endif
endfunction

command! -nargs=0 Instances call <SID>Instances()

" Convenience method allowing s:Method to work on instances
function! s:FindInstanceType()
  let info = SymbolInfo()
  if !has_key(info, "definitionRange")
    return #{}
  endif
  let range = info.definitionRange.range
  let uri = info.definitionRange.uri
  let params = #{range: range, textDocument: #{uri: uri}}
  let resp =  s:LspRequestSync(v:lua.vim.uri_to_bufnr(uri), 'textDocument/ast', params)
  if empty(resp)
    return #{}
  endif
  " Locate variable type in the definition AST
  let queue = [resp]
  while !empty(queue)
    let head = queue[0]
    call remove(queue, 0)
    if head.kind == 'record'
      break
    endif
    if has_key(head, 'children')
      let queue += head.children
    endif
  endwhile
  if head.kind == 'record'
    return #{textDocument: #{uri: uri}, range: head.range}
  endif
  return #{}
endfunction

function! s:Member(filterList)
  let node = SyntaxTreeCword()
  if !has_key(node, "kind")
    echo "Failed to detect cword"
    return
  endif
  let uri = v:lua.vim.uri_from_bufnr(0)
  let kind = node.kind
  let range = node.range
  unlet node

  if kind != "CXXRecord" && kind != "Record"
    let type = s:FindInstanceType()
    if empty(type)
      echo "Failed to find type of instance"
      return
    endif
    let uri = type.textDocument.uri
    let range = type.range
    let kind = "Record"
  endif

  if kind != "CXXRecord"
    let bufnr = v:lua.vim.uri_to_bufnr(uri)
    let params = #{position: range.start, textDocument: #{uri: uri}}
    let resp = s:LspRequestSync(bufnr, 'textDocument/symbolInfo', params)
    if empty(resp) || !has_key(resp[0], "declarationRange")
      echo "Failed to find class declaration"
      return
    endif
    let uri = resp[0].declarationRange.uri
    let range = resp[0].declarationRange.range
  endif

  unlet kind " CXXRecord

  let params = #{textDocument: #{uri: uri}, range: range}
  let bufnr = v:lua.vim.uri_to_bufnr(uri)
  let resp = s:LspRequestSync(bufnr, 'textDocument/ast', params)
  if empty(resp)
    echo "Failed to load AST of class"
    return
  endif
  call AstHandler(bufnr, a:filterList, resp)
endfunction

command! -nargs=0 Mfun call <SID>Member(["CXXMethod", "CXXConstructor", "CXXDestructor"])
command! -nargs=0 Mvar call <SID>Member(["Field"])

"}}}

""""""""""""""""""""""""""""Context dependent"""""""""""""""""""""""""""" {{{
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:ResolveEnvFile()
  let fname = expand("%:f")
  let idx = stridx(fname, "include/alcatraz")
  if idx >= 0
    let resolved = "/home/stef/libalcatraz/" . fname[idx:]
    if filereadable(resolved)
      let pos = getcurpos()[1:]
      exe "edit " . resolved
      call cursor(pos)
    else
      echo "Sorry, I'm buggy, Update me!"
    endif
  else
    echo "Sorry, no idea. Update me!"
  endif
endfunction

nnoremap <silent> <leader>env :call <SID>ResolveEnvFile()<CR>

function! RemoteCompl(ArgLead, CmdLine, CursorPos)
  if a:CursorPos < len(a:CmdLine)
    return []
  endif

  " No 'iregex' on remote device
  let pat = ".*" . a:ArgLead . ".*"
  let find = "find /home/root/Debug -regex '" . pat . "' -type f -executable"
  let machine = "root@10.1.20." . a:CmdLine[6] . a:CmdLine[7]
  return split(system(["ssh", "-o", "ConnectTimeout=1", machine, find]), nr2char(10))
endfunction

command! -nargs=1 -complete=customlist,RemoteCompl Remote26 call s:Debug({"exe": <q-args>, "ssh": "root@10.1.20.26"})

function! s:Make()
  function! OnStdout(id, data, event)
    for data in a:data
      let text = substitute(data, '\n', '', 'g')
      if len(text) > 0
        let m = matchlist(text, '\[ *\([0-9]\+%\)\]')
        if len(m) > 1 && !empty(m[1])
          let g:statusline_dict['make'] = m[1]
        endif
      endif
    endfor
  endfunction

  let g:make_error_list = []

  function! OnStderr(id, data, event)
    for data in a:data
      let text = substitute(data, '\n', '', 'g')
      if len(text) > 0
        let m = matchlist(text, '\(.*\):\([0-9]\+\):\([0-9]\+\): \(.*\)')
        if len(m) >= 5
          let file = m[1]
          let lnum = m[2]
          let col = m[3]
          let text = m[4]
          if filereadable(file) && !empty(text)
            let item = #{filename: file, text: text, lnum: lnum, col: col}
            call add(g:make_error_list, item)
          endif
        endif
      endif
    endfor
  endfunction

  function! OnExit(id, code, event)
    if a:code == 0
      echom "Make successful!"
    else
      echom "Make failed!"
      call setqflist([], ' ', #{title: "Make", items: g:make_error_list})
      copen
    endif
    unlet g:make_error_list
    silent! unlet g:statusline_dict['make']
  endfunction

  call setqflist([], ' ', #{title: "Make"})
  let opts = #{on_stdout: function("OnStdout"), on_stderr: function("OnStderr"), on_exit: function("OnExit")}
  let id = jobstart(["/bin/bash", "-c", "source /opt/aisys/obsidian_05/environment-setup-armv8a-aisys-linux; make"], opts)
endfunction

command! -nargs=0 Make call <SID>Make()

"}}}
