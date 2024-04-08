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

Plug 'sshklifov/debug'
Plug 'sshklifov/qsearch'
Plug 'sshklifov/qutil'

call plug#end()

" Redefine the group, avoids having the same autocommands twice
augroup vimrc
au!
autocmd BufWritePost init.vim source ~/.config/nvim/init.vim

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

" sshklifov/qsearch
let g:qsearch_exclude_dirs = [".cache", ".git", "Debug", "Release", "build"]
let g:qsearch_exclude_files = ["compile_commands.json"]

" tpope/vim-eunuch
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
nnoremap <silent> <leader>ev :e ~/.config/nvim/init.vim<CR>
nnoremap <silent> <leader>lv :e ~/.config/nvim/lua/lsp.lua<CR>

" Indentation settings
set expandtab
set shiftwidth=2
set tabstop=2
set softtabstop=0
set cinoptions=L0,l1,b0,g1,t0,(s,U1,N-s
autocmd FileType c,cpp setlocal cc=101

cabbr Gd lefta Gdiffsplit
cabbr Gl Gclog!
cabbr Gb Git blame
cabbr Gdt Git! difftool
cabbr Gmt Git mergetool

" Git commit style settings
autocmd FileType gitcommit setlocal spell | setlocal tw=90 | setlocal cc=91

" Capture <Esc> in termal mode
tnoremap <Esc> <C-\><C-n>

" Display line numbers
set number
set relativenumber

" Smart searching with '/'
set ignorecase
set smartcase
set hlsearch
nnoremap <silent> <Space> :nohlsearch<cr>

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

" Increase oldfiles size
set shada='1000,<0,s50,h
" Save undo history
set undofile

" Disable mouse
set mouse=

" Command completion
set wildchar=9
set wildcharm=9
set wildignore=*.o,*.out
set wildignorecase
set wildmode=full

cnoremap <expr> <Up> pumvisible() ? "\<C-p>" : "\<Up>"
cnoremap <expr> <Down> pumvisible() ? "\<C-n>" : "\<Down>"
cnoremap <expr> <Left> pumvisible() ? "\<Space>\<BS>\<Left>" : "\<Left>"
cnoremap <expr> <Right> pumvisible() ? "\<Space>\<BS>\<Right>" : "\<Right>"

set scrolloff=4
set autoread
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
let g:statusline_prio = ['sync', 'make', 'lsp']
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
set sessionoptions=buffers,curdir,help,tabpages,winsize

nnoremap <silent> <leader>cd :lcd %:p:h<CR>
nnoremap <silent> <leader>gcd :Gcd<CR>

nnoremap <silent> <leader>ta :tabnew<CR><C-O>
nnoremap <silent> <leader>tA :-tabnew<CR><C-O>
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

command! -nargs=0 -bar Retab set invexpandtab | retab!

function! s:GetWindows(pat, idx)
  let windows = flatten(map(gettabinfo(), "v:val.windows"))
  let win_names = map(windows, '[v:val, expand("#" . winbufnr(v:val) . ":t")]')
  let win_names = filter(win_names, 'stridx(v:val[1], a:pat) >= 0 && !empty(v:val[1])')
  return map(win_names, 'v:val[a:idx]')
endfunction

function! s:Window(pat)
  let w = s:GetWindows(a:pat, 0)
  if len(w) < 1
    echo "No windows"
  else
    call win_gotoid(w[0])
  endif
endfunction

command! -nargs=1 -complete=customlist,WindowCompl Window call s:Window(<q-args>)

function! WindowCompl(ArgLead, CmdLine, CursorPos)
  if a:CursorPos < len(a:CmdLine)
    return []
  endif
  return s:GetWindows(a:ArgLead, 1)
endfunction

function! s:DiffFugitiveWinid()
  " Load all windows in tab
  let winids = gettabinfo(tabpagenr())[0]["windows"]
  let winfos = map(winids, "getwininfo(v:val)[0]")
  " Ignore quickfix
  let winfos = filter(winfos, "v:val.quickfix != 1")

  " Consider two way diffs only
  if len(winfos) != 2
    return -1
  endif
  " Both buffers should have 'diff' set
  if win_execute(winfos[0].winid, "echon &diff") != "1" || win_execute(winfos[1].winid, "echon &diff") != "1"
    return -1
  endif
  " Consider diffs comming from fugitive plugin only
  if bufname(winfos[0].bufnr) =~# "^fugitive:///"
    return winfos[0].winid
  endif
  if bufname(winfos[1].bufnr) =~# "^fugitive:///"
    return winfos[1].winid
  endif
  return -1
endfunction

function! s:CanStartDiff()
  " Load all windows in tab
  let winids = gettabinfo(tabpagenr())[0]["windows"]
  let winfos = map(winids, "getwininfo(v:val)[0]")
  " Ignore quickfix
  let winfos = filter(winfos, "v:val.quickfix != 1")
  " Only a single file can be opened
  if len(winfos) != 1
    return 0
  endif
  " Must exist on disk
  let bufnr = winfos[0].bufnr
  if !filereadable(bufname(bufnr))
    return 0
  endif
  " Must be inside git
  return !empty(FugitiveGitDir(bufnr))
endfunction

" Mostly remove search from foldopen
set foldopen=block,hor,jump,mark,quickfix,undo

function! s:ToggleDiff()
  let winid = s:DiffFugitiveWinid()
  if winid >= 0
    let bufnr = getwininfo(winid)[0].bufnr
    if getbufvar(bufnr, '&mod') == 1
      echo "No write since last change"
      return
    endif
    let name = bufname(bufnr)
    let commitish = split(FugitiveParse(name)[0], ":")[0]
    " Memorize the last diff commitish for the buffer
    call setbufvar(bufnr, 'commitish', commitish)
    " Close fugitive window
    call win_gotoid(winid)
    quit
  elseif s:CanStartDiff()
    cclose
    if exists("b:commitish") && b:commitish != "0"
      exe "lefta Gdiffsplit " . b:commitish
    else
      exe "lefta Gdiffsplit"
    endif
  endif
endfunction

nnoremap <silent> <leader>dif :call <SID>ToggleDiff()<CR>

function! s:Operator(cmd, pending)
  let &operatorfunc = function('s:DoOperatorCmd', [a:cmd])
  if a:pending
    return 'g@'
  else
    return 'g@_'
  endif
endfunction

function! s:DoOperatorCmd(cmd, type)
  if a:type != "line"
    return
  endif
  let firstline = line("'[")
  let lastline = line("']")
  exe printf("%d,%d%s", firstline, lastline, a:cmd)
endfunction

xnoremap <expr> dp <SID>Operator("diffput", 1)
nnoremap <expr> dp <SID>Operator("diffput", 1)
nnoremap <expr> dP <SID>Operator("diffput", 0)

xnoremap <expr> do <SID>Operator("diffget", 1)
nnoremap <expr> do <SID>Operator("diffget", 1)
nnoremap <expr> dO <SID>Operator("diffget", 0)

" Undoing diffs
nnoremap dpu <C-w>wu<C-w>w
nnoremap dou u

" Saving diffs
nnoremap dpw <C-w>w:w<CR><C-w>w
nnoremap dow w

" Good ol' regular diff commands
nnoremap dpp dp
nnoremap doo do

function! s:GetUnstaged()
  let dict = FugitiveExecute(["ls-files", "--exclude-standard", "--modified"])
  if dict['exit_status'] != 0
    return []
  endif
  let files = filter(dict['stdout'], "!empty(v:val)")
  if empty(files)
    return []
  endif
  return map(files, "FugitiveFind(v:val)")
endfunction

command! -nargs=? -complete=customlist,UnstagedCompl Unstaged
      \ call s:GetUnstaged()->ArgFilter(<q-args>)->DropInQf("Unstaged")

function UnstagedCompl(ArgLead, CmdLine, CursorPos)
  if a:CursorPos < len(a:CmdLine)
    return []
  endif
  return s:GetUnstaged()->TailItems(a:ArgLead)
endfunction

function! s:GetUntracked()
  let dict = FugitiveExecute(["ls-files", "--exclude-standard", "--others"])
  if dict['exit_status'] != 0
    return []
  endif
  let files = filter(dict['stdout'], "!empty(v:val)")
  if empty(files)
    return []
  endif
  return map(files, "FugitiveFind(v:val)")
endfunction

command! -nargs=? -complete=customlist,UntrackedCompl Untracked
      \ call s:GetUntracked()->ArgFilter(<q-args>)->DropInQf("Untracked")

function UntrackedCompl(ArgLead, CmdLine, CursorPos)
  if a:CursorPos < len(a:CmdLine)
    return []
  endif
  return s:GetUntracked(bang)->TailItems(a:ArgLead)
endfunction

" CursorHold time
set updatetime=500
set completeopt=menuone,noinsert
set pumheight=10

" http://vim.wikia.com/wiki/Automatically_append_closing_characters
inoremap {<CR> {<CR>}<C-o>O

nmap <leader>sp :setlocal invspell<CR>

function! s:SwitchToBranch(arg)
  let dict = FugitiveExecute(["status", "--porcelain"])
  if dict['exit_status'] != 0
    echo "Not inside repo"
    return
  endif
  if dict['stdout'][0] != ''
    echo "Dirty repo detected"
    return
  endif

  let dict = FugitiveExecute(["checkout", a:arg])
  if dict['exit_status'] != 0
    echo "Failed to checkout " . a:arg
    return
  endif
  " Rebuild for an up-to-date version of compile_commands.json
  exe "Make!"
endfunction

function! s:GetRefs(ref_dirs, arg)
  let result = []
  let dirs = map(a:ref_dirs, 'FugitiveGitDir() . "/" . v:val')
  for dir in dirs
    if isdirectory(dir)
      let pat = dir . ".*" . a:arg . ".*"
      let result += Find(dir, "-type", "f", "-regex", pat, "-printf", "%P\n")
    endif
  endfor
  return uniq(sort(result))
endfunction

command! -nargs=1 -complete=customlist,BranchCompl Branch call <SID>SwitchToBranch(<q-args>)

function! BranchCompl(ArgLead, CmdLine, CursorPos)
  if a:CursorPos < len(a:CmdLine)
    return []
  endif
  return s:GetRefs(['refs/heads', 'refs/tags', 'refs/remotes'], a:ArgLead)
endfunction

command! -nargs=1 -complete=customlist,OriginCompl Origin call <SID>SwitchToBranch(<q-args>)

function! OriginCompl(ArgLead, CmdLine, CursorPos)
  if a:CursorPos < len(a:CmdLine)
    return []
  endif
  call FugitiveExecute(['fetch', 'origin'])
  return s:GetRefs(['refs/remotes/origin'], a:ArgLead)
endfunction

function! s:Review(bang, arg)
  if exists("g:review_stack")
    let items = g:review_stack[-1]
    call DisplayInQf(items, "Review")
    return
  endif

  " Run a test command
  if FugitiveExecute(["status"])['exit_status'] != 0
    echo "Not inside repo"
    return
  endif
  " Auto detect mainline if not passed. Either 'master' or 'main'
  let main = a:arg
  if empty(main)
    let branches = s:GetRefs(['refs/remotes'], 'ma')
    if index(branches, 'origin/master') >= 0
      let main = 'origin/master'
    elseif index(branches, 'origin/main') >= 0
      let main = 'origin/main'
    else
      echo "Failed to determine mainline. Pass it as argument"
      return
    endif
  endif
  " See if mainline exists
  if FugitiveExecute(["show", main])['exit_status'] != 0
    echo "Unknown ref to git: " . main
    return
  endif

  if a:bang == "!"
    " Force the branchpoint to be at the mainline. This is necessary when the below commands fail
    let bpoint = main
  else
    let range = main . "..HEAD"
    let dict = FugitiveExecute(["log", range, "--pretty=format:%H"])
    if dict['exit_status'] != 0
      echo "Revision range failed, aborting review"
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
  endif
  if !exists('bpoint')
    echo "Could not determine branch point, aborting review"
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

command! -nargs=? -bang -complete=customlist,OriginCompl Review call <SID>Review("<bang>", <q-args>)

function! s:ReviewCompleteFiles(cmd_bang, arg) abort
  if !exists("g:review_stack")
    echo "Start a review first"
    return
  endif
  " Close diff
  if s:DiffFugitiveWinid() >= 0
    call s:ToggleDiff()
  endif

  let new_items = copy(g:review_stack[-1])
  if !empty(a:arg)
    let idx = printf("stridx(bufname(v:val.bufnr), %s)", string(a:arg))
    let comp = a:cmd_bang == "!" ? " != " : " == "
    let new_items = filter(new_items, idx . comp . "-1")
    let n = len(g:review_stack[-1]) - len(new_items)
    echo "Completed " . n . " files"
  else
    let comp = a:cmd_bang == "!" ? " == " : " != "
    let bufnr = bufnr(FugitiveReal(bufname("%")))
    let new_items = filter(new_items, "v:val.bufnr" . comp . bufnr)
  endif
  call add(g:review_stack, new_items)
  if empty(new_items)
    echo "Review completed!"
    unlet g:review_stack
  else
    call DisplayInQf(new_items, "Review")
    cc
  endif
endfunction

function CompleteCompl(ArgLead, CmdLine, CursorPos)
  if a:CursorPos < len(a:CmdLine)
    return []
  endif
  if !exists('g:review_stack')
    return []
  endif
  return SplitItems(g:review_stack[-1], a:ArgLead)
endfunction

command! -bang -nargs=? -complete=customlist,CompleteCompl Complete  call <SID>ReviewCompleteFiles('<bang>', <q-args>)

function! s:ReviewPostponeFile()
  if !exists("g:review_stack")
    echo "Start a review first"
    return
  endif
  let list = g:review_stack[-1]
  let nrs = map(copy(list), "v:val.bufnr")
  let idx = index(nrs, bufnr())
  if idx < 0
    return
  endif
  let item = remove(list, idx)
  call add(list, item)

  " Close diff
  if s:DiffFugitiveWinid() >= 0
    call s:ToggleDiff()
  endif
  " Refresh quickfix
  call DisplayInQf(list, "Review")
  cc
endfunction

nnoremap <silent> <leader>ok <cmd>Complete<CR>
nnoremap <silent> <leader>nok <cmd>call <SID>ReviewPostponeFile()<CR>

function! s:UncompleteFiles()
  if !exists("g:review_stack")
    echo "Start a review first"
    return
  endif
  if len(g:review_stack) > 1
    call remove(g:review_stack, -1)
    let items = g:review_stack[-1]
    call DisplayInQf(items, "Review")
  endif
endfunction

command! -nargs=0 Uncomplete call <SID>UncompleteFiles()
" }}}

""""""""""""""""""""""""""""Code navigation"""""""""""""""""""""""""""" {{{
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:NextItem(dir)
  if s:DiffFugitiveWinid() >= 0
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

nnoremap <silent> [c :call <SID>NextItem("prev")<CR>
nnoremap <silent> ]c :call <SID>NextItem("next")<CR>
nnoremap <silent> [C :call <SID>NextItem("first")<CR>
nnoremap <silent> ]C :call <SID>NextItem("last")<CR>

function! s:ToggleQf()
  if s:DiffFugitiveWinid() < 0
    if IsQfOpen()
      cclose
    else
      copen
    endif
  endif
endfunction

nnoremap <silent> <leader>cc :call <SID>ToggleQf()<CR>

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
  let regex = ".*" . expand("%:t:r") . "\\.c.*"
  call QuickFind(FugitiveWorkTree(), "-regex", regex)
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
  let regex = ".*" . expand("%:t:r") . "\\.h.*"
  call QuickFind(FugitiveWorkTree(), "-regex", regex)
endfunction

nmap <silent> <leader>cpp :call <SID>OpenSource()<CR>
nmap <silent> <leader>hpp :call <SID>OpenHeader()<CR>

function! s:OpenCMakeLists()
  let dir = expand("%:p:h")
  let repo = FugitiveWorkTree()
  if len(repo) <= 0
    return
  endif

  while len(dir) >= len(repo)
    let lists = dir . "/CMakeLists.txt"
    if filereadable(lists)
      exe "edit " . lists
      return
    endif
    let dir = fnamemodify(dir, ":h")
  endwhile
endfunction

command! -nargs=0 Cmake call <SID>OpenCMakeLists()

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

""""""""""""""""""""""""""""Debugging"""""""""""""""""""""""""""" {{{
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:StartDebug(exe)
  let exe = empty(a:exe) ? "a.out" : a:exe
  let opts = {"exe": exe}
  call s:Debug(opts)
endfunction

command! -nargs=? -complete=customlist,ExeCompl Start call s:StartDebug(<q-args>)

function! s:RunDebug(exe)
  let exe = empty(a:exe) ? "a.out" : a:exe
  let br_cmd = "br " . s:GetDebugLoc()
  let run_cmd = "c"
  
  let opts = #{exe: exe, cmds: [br_cmd, run_cmd]}
  call s:Debug(opts)
endfunction

command! -nargs=? -complete=customlist,ExeCompl Run call s:RunDebug(<q-args>)

function! ExeCompl(ArgLead, CmdLine, CursorPos)
  if a:CursorPos < len(a:CmdLine)
    return []
  endif
  " Can't use Find() since it ignores the build folder
  let pat = "*" . a:ArgLead . "*"
  let cmd = ["find", ".", "(", "-path", "**/.git", "-prune", "-false", "-o", "-name", pat, ")"]
  let cmd += ["-type", "f", "-executable", "-printf", "%P\n"]
  return systemlist(cmd)
endfunction

function! s:AttachDebug(proc)
  let pids = systemlist(["pgrep", "-f", proc])
  " Report error
  if len(pids) == 0
    echo "No processes found"
    return
  elseif len(pids) > 1
    echo "Multiple processes found"
    return
  endif
  let opts = #{proc: pids[0]}
  call s:Debug(opts)
endfunction

command! -nargs=1 -complete=customlist,AttachCompl Attach call s:AttachDebug(<q-args>)

function! AttachCompl(ArgLead, CmdLine, CursorPos)
  if a:CursorPos < len(a:CmdLine)
    return []
  endif

  let cmdlines = systemlist(["ps", "h", "-U", $USER, "-o", "command"])
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
" - proc. Process pid to attach.
" Other arguments:
" - symbols. Whether to load symbols or not. Used for faster loading of gdb.
" - ssh. Launch GDB over ssh with the given address.
" - cmds. Additional commands to execute once the inferior is loaded
function! s:Debug(args)
  let required = ['exe', 'proc']
  let optional = ['symbols', 'ssh', 'cmds']
  let req_keys = filter(keys(a:args), "index(required, v:val) >= 0")
  if len(req_keys) != 1
    echo "Must pass exactly one of: " . string(required)
    return
  endif
  let total = required + optional
  let invalid_keys = filter(keys(a:args), "index(total, v:val) < 0")
  if len(invalid_keys) > 0
    echo "Unexpected arguments: " . string(invalid_keys)
    return
  endif

  " if index(keys, required[0]) == 0 && index(keys

  if TermDebugIsOpen()
    echoerr 'Terminal debugger already running, cannot run two'
    return
  endif

  " Install new autocmds
  autocmd! User TermDebugStopPre call s:DebugStopPre()
  exe "autocmd! User TermDebugRunPost call s:DebugRunPost(" . string(a:args) . ")"

  if has_key(a:args, "ssh")
    call TermDebugStart(a:args["ssh"])
  else
    call TermDebugStart()
  endif
  call s:DebugStartPost(a:args)
endfunction

function! s:DebugStartPost(args)
  let quick_load = has_key(a:args, "symbols") && !a:args["symbols"]

  command! -nargs=0 Capture call TermDebugGoToCapture()
  command! -nargs=0 Asm call TermDebugToggleAsm()
  command! -nargs=0 Gdb call TermDebugGoToGdb()
  command! -nargs=0 Up call TermDebugGoUp("/home/stef")
  command! -nargs=0 Pwd call TermDebugShowPwd()
  command! -nargs=0 Backtrace call TermDebugBacktrace()
  command! -nargs=0 Threads call TermDebugThreadInfo()

  nnoremap <silent> <leader>v <cmd>call TermDebugEvaluate(expand('<cword>'))<CR>
  vnoremap <silent> <leader>v :<C-u>call TermDebugEvaluate(<SID>GetRangeExpr())<CR>

  nnoremap <silent> <leader>br :call TermDebugSendCommand("br " . <SID>GetDebugLoc())<CR>
  nnoremap <silent> <leader>tbr :call TermDebugSendCommand("tbr " . <SID>GetDebugLoc())<CR>
  nnoremap <silent> <leader>unt :call TermDebugSendCommands("tbr " . <SID>GetDebugLoc(), "c")<CR>
  nnoremap <silent> <leader>pc :call TermDebugGoToPc()<CR>

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
  call TermDebugSendCommand("set max-completions 20")
  if quick_load
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
    call TermDebugSendCommand("start")
  endif
endfunction

function! s:DebugRunPost(args)
  call TermDebugSendCommand("set scheduler-locking step")
  let cmds = get(a:args, "cmds", [])
  for cmd in cmds
    call TermDebugSendCommand(cmd)
  endfor
endfunction

function! s:DebugStopPre()
  silent! nunmap <leader>v
  silent! vunmap <leader>v
  silent! nunmap <leader>br
  silent! nunmap <leader>tbr
  silent! nunmap <leader>unt
  silent! nunmap <leader>pc

  silent! delcommand Capture
  silent! delcommand Asm
  silent! delcommand Gdb
  silent! delcommand Up
  silent! delcommand Pwd
  silent! delcommand Backtrace
  silent! delcommand Threads
endfunction

function! s:GetDebugLoc()
  let basename = expand("%:t")
  let lnum = line(".")
  return printf("%s:%d", basename, lnum)
endfunction

function! s:GetRangeExpr()
  let [lnum1, col1] = getpos("'<")[1:2]
  let [lnum2, col2] = getpos("'>")[1:2]

  let lines = getline(lnum1, lnum2)
  let lines[-1] = lines[-1][:col2 - 1]
  let lines[0] = lines[0][col1 - 1:]
  return join(lines, " ")
endfunction
"}}}

""""""""""""""""""""""""""""LSP"""""""""""""""""""""""""""" {{{
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
command! -nargs=0 LspStop lua vim.lsp.stop_client(vim.lsp.get_active_clients())
command! -nargs=0 LspProg lua print(vim.inspect(vim.lsp.util.get_progress_messages()))

command! -nargs=0 -range=% For lua vim.lsp.buf.format{ range = {start= {<line1>, 0}, ["end"] = {<line2>, 0}} }

" Document highlight
highlight LspReferenceText gui=underline
highlight! link LspReferenceRead LspReferenceText
highlight! link LspReferenceWrite LspReferenceText

" Class highlight
highlight! link @lsp.type.class.cpp @lsp.type.type
highlight! link @lsp.type.class.c @lsp.type.type
highlight! link @lsp.type.parameter.cpp @lsp.type.variable
highlight! link @lsp.type.parameter.c @lsp.type.variable
highlight! link @lsp.typemod.method.defaultLibrary Function
highlight! link @lsp.typemod.function.defaultLibrary Function

lua require('lsp')

function! s:UpdateLspProgress() 
  let serverResponses = luaeval('vim.lsp.util.get_progress_messages()')
  if empty(serverResponses)
    let g:statusline_dict.lsp = ''
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

  let serverProgress = map(serverResponses, funcref("GetServerProgress"))

  let totalFiles = 0
  let totalDone = 0
  for progress in serverProgress
    let totalDone += progress[0]
    let totalFiles += progress[1]
  endfor

  if totalFiles == 0
    let g:statusline_dict.lsp = ''
    return
  endif

  let percentage = (100 * totalDone) / totalFiles
  let g:statusline_dict.lsp = percentage . "%"
endfunction

autocmd User LspProgressUpdate call <SID>UpdateLspProgress()

function! FindCompl(ArgLead, CmdLine, CursorPos) abort
  let cmd = substitute(a:CmdLine[:a:CursorPos-1], 'Find', 'find', '')
  return CmdCompl(cmd)
endfunction

command! -nargs=+ -complete=customlist,FindCompl Find call QuickFind(<f-args>)

command! -nargs=+ Grepo call QuickGrep(<q-args>, FugitiveWorkTree())

function! s:GetIndex()
  let dir = FugitiveWorkTree()
  if !isdirectory(dir)
    return []
  endif
  let source = ["c", "cc", "cp", "cxx", "cpp", "CPP", "c++", "C"]
  let header = ["h", "hh", "H", "hp", "hxx", "hpp", "HPP", "h++", "tcc"]
  let regex = '.*\.\(' . join(source, '\|') . '\|' . join(header, '\|') . '\)'
  return Find(dir, "-regex", regex)
endfunction

function! IndexCompl(ArgLead, CmdLine, CursorPos)
  if a:CursorPos < len(a:CmdLine)
    return []
  endif
  return s:GetIndex()->SplitItems(a:ArgLead)
endfunction

command! -nargs=? -complete=customlist,IndexCompl Index call s:GetIndex()->ArgFilter(<q-args>)->DropInQf('Index')

function! s:GetSource()
  let dir = FugitiveWorkTree()
  if !isdirectory(dir)
    return []
  endif
  let source = ["c", "cc", "cp", "cxx", "cpp", "CPP", "c++", "C"]
  let regex = '.*\.\(' . join(source, '\|') . '\)'
  return Find(dir, "-regex", regex)
endfunction

function! SourceCompl(ArgLead, CmdLine, CursorPos)
  if a:CursorPos < len(a:CmdLine)
    return []
  endif
  return s:GetSource()->TailItems(a:ArgLead)
endfunction

command! -nargs=? -complete=customlist,SourceCompl Source call s:GetSource()->ArgFilter(<q-args>)->DropInQf('Source')

function! s:GetWorkFiles()
  let dir = FugitiveWorkTree()
  if !isdirectory(dir)
    return []
  endif
  return Find(dir)
endfunction

function! WorkFilesCompl(ArgLead, CmdLine, CursorPos)
  if a:CursorPos < len(a:CmdLine)
    return []
  endif
  return s:GetWorkFiles()->SplitItems(a:ArgLead)
endfunction

command! -nargs=? -complete=customlist,WorkFilesCompl Workfiles call s:GetWorkFiles()->ArgFilter(<q-args>)->DisplayInQf('Workfiles')

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
    call DropInQf(items, "Hierarchy")
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
  call DisplayInQf(items, "References")
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
    call DisplayInQf(items, "Instances")
  endif
endfunction

command! -nargs=0 Instances call <SID>Instances()
"}}}

""""""""""""""""""""""""""""Remote"""""""""""""""""""""""""""" {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:RemoteStart(host, exe)
  let debug_args = #{ssh: a:host}
  if !empty(a:exe)
    let debug_args['exe'] = a:exe
  endif
  call s:Debug(debug_args)
endfunction

function! s:RemoteRun(host, exe)
  let debug_args = #{ssh: a:host}
  if !empty(a:exe)
    let debug_args['exe'] = a:exe
  endif
  let br_cmd = 'br ' . s:GetDebugLoc()
  let run_cmd = 'c'
  let debug_args['cmds'] = [br_cmd, run_cmd]
  call s:Debug(debug_args)
endfunction

function! s:RemotePid(host, proc)
  let pid = systemlist(["ssh", "-o", "ConnectTimeout=1", a:host, "pgrep " . a:proc])
  if len(pid) > 1
    echo "Multiple instances of " . a:proc
    return -1
  elseif len(pid) < 1
    echo "Cannot attach: " . a:proc . " is not running"
    return -1
  endif
  return pid[0]
endfunction

function! s:RemoteAttach(host, proc)
  let pid = s:RemotePid(a:host, a:proc)
  if pid > 0
    let opts = #{ssh: a:host, proc: pid[0]}
    call s:Debug(opts)
  endif
endfunction

function! s:SshTerm(remote)
  tabnew
  startinsert
  let id = termopen(["ssh", a:remote])
endfunction

function! s:Sshfs(remote, args)
  silent exe "tabnew scp://" . a:remote . "/" . a:args
endfunction

"}}}

" Context dependent

""""""""""""""""""""""""""""Building"""""""""""""""""""""""""""" {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let s:build_type = "Debug"

function s:ObsidianMake(...)
  let repo = split(FugitiveWorkTree(), "/")[-1]
  let obsidian_repos = ["obsidian-video", "libalcatraz", "mpp"]
  if index(obsidian_repos, repo) < 0
    echo "Unsupported repo: " . repo
    return
  endif

  const sdk = "/opt/aisys/obsidian_10"
  let common_flags = join([
        \ printf("-isystem %s/sysroots/armv8a-aisys-linux/usr/include/c++/11.4.0/", sdk),
        \ printf("-isystem %s/sysroots/armv8a-aisys-linux/usr/include/c++/11.4.0/aarch64-aisys-linux", sdk),
        \ "-O0 -ggdb -U_FORTIFY_SOURCE"])
  let cxxflags = "export CXXFLAGS=" . string(common_flags)
  let cflags = "export CFLAGS=" . string(common_flags)

  let dir = printf("cd %s", FugitiveWorkTree())
  let env = printf("source %s/environment-setup-armv8a-aisys-linux", sdk)

  let cmake = printf("cmake -B %s -S . -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=%s", s:build_type, s:build_type)
  let build = printf("cmake --build %s", s:build_type)

  let cmds = [dir, env, cxxflags, cflags, cmake, build]
  let command = ["/bin/bash", "-c", join(cmds, ';')]

  let bang = get(a:, 1, "")
  return Make(command, bang)
endfunction

command! -nargs=0 -bang Make call <SID>ObsidianMake("<bang>")

command! -nargs=0 Clean call system("rm -rf " . FugitiveFind(s:build_type))

function! s:ResolveEnvFile()
  let fname = expand("%:f")
  let resolved = ""
  if stridx(fname, "include/alcatraz") >= 0
    let idx = stridx(fname, "include/alcatraz")
    let resolved = "/home/stef/libalcatraz/" . fname[idx:]
  elseif stridx(fname, "include/rockchip")
    let basename = fnamemodify(fname, ":t")
    let resolved = "/home/stef/mpp/inc/" . basename
  endif

  if filereadable(resolved)
    let view = winsaveview()
    exe "edit " . resolved
    call winrestview(view)
  else
    echo "Sorry, I'm buggy, Update me!"
  endif
endfunction

nnoremap <silent> <leader>env :call <SID>ResolveEnvFile()<CR>
"}}}

""""""""""""""""""""""""""""Host commands"""""""""""""""""""""""""""" {{{
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! RemoteExeCompl(ArgLead, CmdLine, CursorPos)
  if a:CursorPos < len(a:CmdLine)
    return []
  endif
  let pat = "*" . a:ArgLead . "*"
  let find = "find /var/tmp -name " . shellescape(pat) . " -type f -executable"
  return systemlist(["ssh", "-o", "ConnectTimeout=1", s:host, find])
endfunction

function! SshfsCompl(ArgLead, CmdLine, CursorPos)
  if a:CursorPos < len(a:CmdLine)
    return []
  endif

  if empty(a:ArgLead) || a:ArgLead == '/'
    return systemlist(["ssh", s:host, "find / -maxdepth 1"])
  else
    let dirname = fnamemodify(a:ArgLead, ':h')
    let remote_dirs = systemlist(["ssh", s:host, "find " . dirname . " -maxdepth 1 -type d"])
    let remote_dirs = map(remote_dirs, 'v:val . "/"')
    let remote_files = systemlist(["ssh", s:host, "find " . dirname . " -maxdepth 1 -type f"])
    let total = remote_dirs + remote_files
    return filter(total, 'stridx(v:val, a:ArgLead) == 0')
  endif
endfunction

function! s:RemoteSync(arg, ...)
  function! OnStdout(id, data, event)
    for data in a:data
      let text = substitute(data, '\n', '', 'g')
      if len(text) > 0
        let m = matchlist(text, '[0-9]\+%')
        if len(m) > 0 && !empty(m[0])
          let g:statusline_dict['sync'] = m[0]
        endif
      endif
    endfor
  endfunction

  function! OnExit(id, code, event)
    if a:code == 0
      echom "Synced!"
    else
      echom "Sync failed!"
    endif
    let g:statusline_dict['sync'] = ''
  endfunction

  let dir = a:arg
  if !isdirectory(dir) && !filereadable(dir)
    echo "Not found: " . dir
    return
  endif
  " Remove leading / or rsync will be naughty
  if dir[-1:-1] == '/'
    let dir = dir[0:-2]
  endif
  const remote_dir = s:host . ":/var/tmp/"

  let bang = get(a:000, 0, "")
  if empty(bang)
    let cmd = ["rsync", "-rlt", "--info=progress2", dir, remote_dir]
    let opts = #{on_stdout: funcref("OnStdout"), on_exit: funcref("OnExit")}
    return jobstart(cmd, opts)
  else
    bot new
    let cmd = ["rsync", "-rlt", "--info=all4", dir, remote_dir]
    let opts = #{on_exit: funcref("OnExit")}
    let id = termopen(cmd, opts)
    call cursor("$", 1)
    return id
  endif
endfunction

function! s:Resync()
  let dir = FugitiveFind(s:build_type)
  exe printf("autocmd! User MakeSuccessful ++once call s:RemoteSync('%s')", dir)
  call s:ObsidianMake()
endfunction

command! -nargs=0 Resync call s:Resync()

function s:ChangeHost(host, check)
  if a:check
    call system(["ssh", "-o", "ConnectTimeout=1", a:host, "exit"])
    if v:shell_error != 0
      echo "Failed to connect to host " . a:host
      return
    endif
  endif

  let s:host = a:host
  exe printf("command! -nargs=? -complete=customlist,RemoteExeCompl Start call <SID>RemoteStart('%s', <q-args>)", s:host)
  exe printf("command! -nargs=? -complete=customlist,RemoteExeCompl Run call <SID>RemoteRun('%s', <q-args>)", s:host)
  exe printf("command! -nargs=1 Attach call <SID>RemoteAttach('%s', <q-args>)", s:host)
  exe printf("command! -nargs=1 -complete=customlist,SshfsCompl Sshfs call <SID>Sshfs('%s', <q-args>)", s:host)
endfunction

command! -nargs=1 -complete=customlist,ChangeHostCompl Host call s:ChangeHost(<q-args>, 1)

function ChangeHostCompl(ArgLead, CmdLine, CursorPos)
  if a:CursorPos < len(a:CmdLine)
    return []
  endif
  return ['p10']
endfunction

call s:ChangeHost('p10', 0)
"}}}

""""""""""""""""""""""""""""Applications"""""""""""""""""""""""""""" {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let s:job_list = []
function! s:RunObsidianVideo()
  let bufname = 'Obsidian video'
  if bufexists(bufname)
    echo "Already running"
    return
  endif

  let cmds = []

  let stop_list = ["rtsp-server-noauth", "rtsp-server.socket", "rtsp-server.service", "obsidian-video"]
  for elem in stop_list
    let cmd = "systemctl stop " . elem
    call add(cmds, cmd)
  endfor

  let cmd = printf("cp /var/tmp/%s/application/obsidian-video /tmp", s:build_type)
  call add(cmds, cmd)

  let cmd = "setcap cap_sys_nice+ep /tmp/obsidian-video"
  call add(cmds, cmd)

  let cmd = "sudo -u rock-video /tmp/obsidian-video"
  call add(cmds, cmd)

  let was_win = win_getid()
  tabnew

  let id = termopen(["ssh", s:host])
  call cursor("$", 1)
  call add(cmds, "")
  call chansend(id, cmds)
  exe "file " . bufname
  call add(s:job_list, id)

  call win_gotoid(was_win)
endfunction

command! -nargs=0 Video call <SID>RunObsidianVideo()

function! s:RunRtspServer()
  let bufname = 'Rtsp server'
  if bufexists(bufname)
    echo "Already running"
    return
  endif

  let cmds = []

  let stop_list = ["rtsp-server-noauth", "rtsp-server.socket", "rtsp-server.service"]
  for elem in stop_list
    let cmd = "systemctl stop " . elem
    call add(cmds, cmd)
  endfor

  let cmd = printf("cp /var/tmp/%s/application/rtsp-server /tmp", s:build_type)
  call add(cmds, cmd)

  let cmd = "setcap cap_sys_nice+ep /tmp/rtsp-server"
  call add(cmds, cmd)

  let cmd = "sudo -u rtsp-server /tmp/rtsp-server"
  call add(cmds, cmd)

  let was_win = win_getid()
  tabnew

  let id = termopen(["ssh", s:host])
  call cursor("$", 1)
  call add(cmds, "")
  call chansend(id, cmds)
  call add(s:job_list, id)
  exe "file " . bufname

  call win_gotoid(was_win)
endfunction

command! -nargs=0 Rtsp call <SID>RunRtspServer()

function! s:KillApplications()
  if TermDebugIsOpen()
    call TermDebugQuit()
  endif
  for id in s:job_list
    let chan_info = nvim_get_chan_info(id)
    call jobstop(id)
    if has_key(chan_info, 'buffer')
      exe "bwipe! " . chan_info['buffer']
    endif
  endfor
  let s:job_list = []
endfunction

command! -nargs=0 Kill call <SID>KillApplications()

function! s:CheckSpinning(main_file, ...)
  let origw = win_getid()
  exe "split /home/stef/obsidian-video/application/src/" . a:main_file

  if search("volatile int spin") <= 0
    if a:0 == 0
      return 0
    endif
    let lnum = search("int main")
    call append(lnum, "  volatile int spin = 0;")
    call append(lnum + 1, "  while (spin);")
    throw "Bootstrapping spinning code..."
  endif

  let line = getline('.')
  let state = (line =~ "1")
  if a:0 > 0
    let expected = a:1
    if state != expected
      let line = substitute(line, state, expected, '')
      call setline('.', line)
      write
      Resync
    endif
  endif
  quit
  call win_gotoid(origw)
  return state
endfunction

command! -nargs=0 -bang SpinVideo call s:CheckSpinning("obsidian_video.cc", <bang>1)
command! -nargs=0 -bang SpinRtsp call s:CheckSpinning("rtsp_server.cc", <bang>1)

function! s:AttachToSpinning(main_file)
  if a:main_file =~ "video"
    let pid = s:RemotePid(s:host, "video")
  elseif a:main_file =~ "rtsp"
    let pid = s:RemotePid(s:host, "rtsp")
  endif
  if !exists('pid') || pid < 0
    return
  endif

  let is_spinning = s:CheckSpinning(a:main_file)
  let opts = #{ssh: s:host, proc: pid}
  if is_spinning
    let cmds = ['set var spin = 0', 'c']
    if &ft == 'cpp' || &ft == 'c'
      let cmds = ['br ' . s:GetDebugLoc()] + cmds
    endif
    let opts['cmds'] = cmds
  endif
  call s:Debug(opts)
endfunction

command -nargs=0 AttachVideo call s:AttachToSpinning("obsidian_video.cc")
command -nargs=0 AttachRtsp call s:AttachToSpinning("rtsp_server.cc")
"}}}

nnoremap <silent> <leader>k <cmd>Kill<CR>
nnoremap <silent> <leader>re <cmd>Resync<CR>
nnoremap <silent> <leader>rv <cmd>Video<CR>
nnoremap <silent> <leader>rs <cmd>Rtsp<CR>
nnoremap <silent> <leader>av <cmd>AttachVideo<CR>
nnoremap <silent> <leader>as <cmd>AttachRtsp<CR>

""""""""""""""""""""""""""""TODO"""""""""""""""""""""""""""" {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! DecodeH264Packet()
  call system(["ssh", "p10", "/var/tmp/Debug/test/mpi_dec_test -i /tmp/packet.h264 -o /tmp/packet.nv12 -w 1920 -h 1072 -f 0"])
  if v:shell_error
    echo "Decoding h264 packet failed!"
    return
  endif

  call system(["ssh", "p10", "[ -s /tmp/packet.nv12 ]"])
  if v:shell_error
    echo "Empty nv12 frame!"
    return
  endif

  call system(["scp", "p10:/tmp/packet.nv12", "/home/stef/Downloads"])
  if v:shell_error
    echo "Copy packet to machine failed!"
    return
  endif

  call system("ffmpeg -y -f rawvideo -pix_fmt nv12 -s 1920x1072 -i /home/stef/Downloads/packet.nv12 -f image2 -pix_fmt rgb24 /home/stef/Downloads/packet.png")
  if v:shell_error
    echo "Converting nv12 packet to png failed!"
    return
  endif

  echom "Done with Downloads/packet.png"
endfunction

function! s:HistFind(...)
  " XXX becuase of E464 this is ok
  let f_list = []
  for cmd_prefix in a:000
    call add(f_list, printf('stridx(v:val, "%s") == 0', cmd_prefix))
  endfor
  let f_str = join(f_list, ' || ')

  let hist = map(range(1, histnr(':')), 'histget(":", v:val)')
  let hist = filter(hist, f_str)
  if empty(hist)
    return ""
  else
    return hist[-1]
  endif
endfunction

function! s:Rerun(...)
  if a:0 == 0
    return
  endif
  let fargs = join(map(range(1, a:0),  "'a:' . v:val"), ", ")
  let hist_cmd = eval(printf("s:HistFind(%s)", fargs))
  if empty(hist_cmd)
    echo "Cannot rerun, not in history"
  else
    exe hist_cmd
  endif
endfunction
"}}}

" Go back to default autocommand group
augroup END
