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
Plug 'ojroques/nvim-osc52'

Plug 'sshklifov/debug'
Plug 'sshklifov/qsearch'
Plug 'sshklifov/qutil'

call plug#end()

if !isdirectory(printf("/home/%s/.local/share/nvim/plugged", $USER))
  finish
endif

" Redefine the group, avoids having the same autocommands twice
augroup VimStartup
au!
autocmd BufWritePost /home/$USER/.config/nvim/init.vim source ~/.config/nvim/init.vim

""""""""""""""""""""""""""""Plugin settings"""""""""""""""""""""""""""" {{{
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" sshklifov/debug
let g:termdebug_ignore_no_such = 1
let g:termdebug_override_s_and_n = 1
let g:termdebug_override_up_and_down = 1
let g:termdebug_override_finish_and_return = 1

" Tabulous
let tabulousLabelLeftStr = ' ['
let tabulousLabelRightStr = '] '
let tabulousLabelNumberStr = ':'
let tabulousLabelNameDefault = 'Empty'
let tabulousCloseStr = ''

" Netrw
let g:netrw_hide = 1
let g:netrw_banner = 0
let g:netrw_keepdir = 0

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
autocmd BufEnter *.fish setlocal commentstring=#\ %s
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
nnoremap <silent> <leader>dv :e ~/.local/share/nvim/plugged/debug/plugin/termdebug.vim<CR>

" Indentation settings
set expandtab
set shiftwidth=2
set tabstop=2
set softtabstop=0
set cinoptions=L0,l1,b0,g1,h1,t0,(s,U1,N-s
autocmd BufEnter *.cpp,*.cc,*.c,*.h setlocal cc=101

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

inoremap <expr> <Tab> pumvisible() ? "\<C-y>" : "\<Tab>"

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
set nofoldenable
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
set lcs=tab:\|\ 

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

command! -nargs=0 CursorSym call s:SynStack()

function s:ShowHighlights()
  let hls = split(execute("highlight"), "\n")
  call map(hls, "split(v:val, '\\s')[0]")
  tabnew
  setlocal buftype=nofile
  call appendbufline(bufnr(), 0, 'List of highlights in vim:')
  let ns = nvim_create_namespace("")
  for hl in hls
    call append('$', hl)
    let line = nvim_buf_line_count(0) - 1
    call nvim_buf_set_extmark(0, ns, line, 0, #{end_col: len(hl), hl_group: hl})
  endfor
endfunction

command! -nargs=0 ChooseHighlight call s:ShowHighlights()
" }}}

""""""""""""""""""""""""""""IDE maps"""""""""""""""""""""""""""" {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

nnoremap <leader><leader>q :mksession! ~/.local/share/nvim/session.vim<CR>
nnoremap <leader>so :so ~/.local/share/nvim/session.vim<CR>
set sessionoptions=buffers,curdir,help,tabpages,winsize

nnoremap <silent> cd :lcd %:p:h<CR>
nnoremap <silent> gcd :Gcd<CR>

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

function! s:DiffOtherExecute(cmd)
  let winids = gettabinfo(tabpagenr())[0]['windows']
  if winids[0] != win_getid()
    call win_gotoid(winids[0])
    exe a:cmd
    call win_gotoid(winids[1])
  else
    call win_gotoid(winids[1])
    exe a:cmd
    call win_gotoid(winids[0])
  endif
endfunction

function! s:EnableDiffMaps()
  if v:option_new
    " Diff put
    nnoremap <expr> dp <SID>Operator("diffput", 1)
    nnoremap <expr> dP <SID>Operator("diffput", 0)
    " Diff get
    nnoremap <expr> do <SID>Operator("diffget", 1)
    nnoremap <expr> dO <SID>Operator("diffget", 0)
    " Undoing diffs
    nnoremap dpu <cmd>call <SID>DiffOtherExecute("undo")<CR>
    " Saving diffs
    nnoremap dpw <cmd>call <SID>DiffOtherExecute("write")<CR>
    " Good ol' regular diff commands
    nnoremap dpp dp
    nnoremap doo do
    " Visual mode
    vnoremap dp :diffput<CR>
    vnoremap do :diffget<CR>
  else
    let normal_list = ["dp", "dP", "do", "dO", "dpu", "dpw", "dpp", "dpp"]
    for bind in normal_list
      silent! "nunmap " . bind
    endfor
    " Visual mode
    silent! vunmap dp
    silent! vunmap do
  endif
endfunction

autocmd! OptionSet diff call s:EnableDiffMaps()

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
  return result
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

function! s:MasterOrThrow()
  let branches = s:GetRefs(['refs/remotes'], 'ma')
  if index(branches, 'origin/master') >= 0
    return 'origin/master'
  elseif index(branches, 'origin/main') >= 0
    return 'origin/main'
  else
    throw "Failed to determine mainline."
  endif
endfunction

function! s:HeadOrThrow()
  let dict = FugitiveExecute(["rev-parse", "HEAD"])
  if dict['exit_status'] != 0
    throw "Failed to parse HEAD"
  endif
  return dict['stdout'][0]
endfunction


function! s:CommonParentOrThrow(branch, main)
  let range = printf("%s..%s", a:main, a:branch)
  let dict = FugitiveExecute(["log", range, "--pretty=format:%H"])
  if dict['exit_status'] != 0
    throw "Revision range failed"
  endif
  let branch_first = dict['stdout'][-1]
  " Go 1 back to find the common commit
  let dict = FugitiveExecute(["rev-parse", branch_first . "~1"])
  if dict['exit_status'] != 0
    throw "Failed to go back 1 commit from " . branch_first
  endif
  let common = dict['stdout'][0]
  return common
endfunction

function! s:RefExistsOrThrow(commit)
  if FugitiveExecute(["show", a:commit])['exit_status'] != 0
    throw "Unknown ref to git: " . a:commit
  endif
endfunction

function! s:InsideGitOrThrow()
  if FugitiveExecute(["status"])['exit_status'] != 0
    throw "Not inside repo"
  endif
endfunction

function! s:TryReview(bang, arg)
  " Refresh current state of review
  if exists("g:review_stack")
    let items = g:review_stack[-1]
    call DisplayInQf(items, "Review")
    return
  endif

  call s:InsideGitOrThrow()
  " Determine main branch
  let head = s:HeadOrThrow()
  if a:bang == "!"
    let bpoint = empty(a:arg) ? head : a:arg
    call s:RefExistsOrThrow(bpoint)
  else
    let mainline = empty(a:arg) ? s:MasterOrThrow() : a:arg
    call s:RefExistsOrThrow(mainline)
    let bpoint = s:CommonParentOrThrow(head, mainline)
  endif
  " Load files for review.
  " If possible, make the diff windows editable by not passing a ref to fugitive
  if bpoint == head
    exe "Git difftool --name-only"
    let bufs = map(getqflist(), "v:val.bufnr")
    call map(bufs, 'setbufvar(v:val, "commitish", "0")')
  else
    exe "Git difftool --name-only " . bpoint
    let bufs = map(getqflist(), "v:val.bufnr")
    call map(bufs, 'setbufvar(v:val, "commitish", bpoint)')
  endif
  call setqflist([], 'a', #{title: "Review"})
  let g:review_stack = [getqflist()]
endfunction

function s:Review(bang, arg)
  try
    call s:TryReview(a:bang, a:arg)
  catch
    echo v:exception
  endtry
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
    call nvim_echo([["Review completed", "WarningMsg"]], v:true, #{})
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

func s:OpenStackTrace()
  let dirs = GetRepos()

  let lines = join(getline(1, '$'), "\n")
  let lines = split(lines, '\(^#\)\|\(\n#\)')
  let list = []
  for line in lines
    let m = matchlist(line, '^\([0-9]\+\).* at \([^:]\+\):\([0-9]\+\)')
    if len(m) < 4
      call add(list, #{text: '#'.line, valid: 0})
    else
      let level = m[1]
      let file = m[2]
      let line = m[3]
      let resolved = v:false
      for dir in dirs
        let repo = fnamemodify(dir, ":t")
        let resolved = substitute(file, "^.*" . repo, dir, "")
        if filereadable(resolved)
          call add(list, #{filename: resolved, lnum: line, text: level})
          let resolved = v:true
          break
        endif
      endfor
      if !resolved
        let text = printf("%s:%d", file, line)
        call add(list, #{text: text, valid: 0})
      endif
    endif
  endfor
  call setqflist([], ' ', #{title: 'Stack', items: list})
  copen
endfunc

command! -nargs=0 Crashtrace call s:OpenStackTrace()
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
nnoremap <silent> <leader>com <cmd> exe "Gedit " .. split(FugitiveParse()[0], ":")[0]<CR>

function! s:Context(reverse)
  call search('^\(@@ .* @@\|[<=>|]\{7}[<=>|]\@!\)', a:reverse ? 'bW' : 'W')
endfunction

nnoremap <silent> [n :call <SID>Context(v:true)<CR>
nnoremap <silent> ]n :call <SID>Context(v:false)<CR>

function! s:ContextMotion()
  call s:Context(v:false)
  let end = line('.')
  call s:Context(v:true)
  exe printf("normal V%dG", end)
endfunction

omap an <cmd>call <SID>ContextMotion()<CR>

function! s:FoldMotion()
  normal V[z]z
endfunction

omap az <cmd>call <SID>FoldMotion()<CR>
"}}}

""""""""""""""""""""""""""""Debugging"""""""""""""""""""""""""""" {{{
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:StartDebug(exe)
  let exe = empty(a:exe) ? "a.out" : a:exe
  let opts = {"exe": exe}
  call s:Debug(opts)
endfunction

function! s:RunDebug(exe)
  let exe = empty(a:exe) ? "a.out" : a:exe
  let opts = #{exe: exe, br: s:GetDebugLoc()}
  call s:Debug(opts)
endfunction

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
" - headless. Do not run any inferior
" Other arguments:
" - symbols. Whether to load symbols or not. Used for faster loading of gdb.
" - ssh. Launch GDB over ssh with the given address.
" - br. Place a breakpoint at location and run inferior.
function! s:Debug(args)
  let required = ['exe', 'proc', 'headless']
  let optional = ['symbols', 'ssh', 'user', 'br']
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

  if TermDebugIsOpen()
    echoerr 'Terminal debugger already running, cannot run two'
    return
  endif

  " Install new autocmds
  autocmd! User TermDebugStopPre call s:DebugStopPre()
  autocmd! User TermDebugRunPost call s:DebugRunPost()

  " Open GDB
  if has_key(a:args, "ssh")
    if has_key(a:args, "user")
      call TermDebugStart(a:args["ssh"], a:args["user"])
    else
      call TermDebugStart(a:args["ssh"])
    endif
  else
    call TermDebugStart()
  endif

  " Run configurations
  call s:DebugStartPost(a:args)
endfunction

function! s:DebugStartPost(args)
  let quick_load = has_key(a:args, "symbols") && !a:args["symbols"]

  command! -nargs=0 Capture call TermDebugGoToCapture()
  command! -nargs=0 Gdb call TermDebugGoToGdb()
  command! -nargs=0 Pwd call TermDebugShowPwd()
  command! -nargs=0 Backtrace call TermDebugBacktrace()
  command! -nargs=? Threads call TermDebugThreadInfo(<q-args>)
  command! -nargs=0 DebugSym call TermDebugFindSym(expand('<cword>'))
  command! -nargs=? Break call TermDebugGoToBreakpoint(<q-args>)
  command! -nargs=? Commands call TermDebugEditCommands(<f-args>)

  nnoremap <silent> <leader>v <cmd>call TermDebugEvaluate(expand('<cword>'))<CR>
  vnoremap <silent> <leader>v :<C-u>call TermDebugEvaluate(<SID>GetRangeExpr())<CR>

  nnoremap <silent> <leader>br :call TermDebugSendCommand("br " . <SID>GetDebugLoc())<CR>
  nnoremap <silent> <leader>tbr :call TermDebugSendCommand("tbr " . <SID>GetDebugLoc())<CR>
  nnoremap <silent> <leader>unt :call TermDebugSendCommands("tbr " . <SID>GetDebugLoc(), "c")<CR>
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
  if quick_load
    call TermDebugSendCommand("set auto-solib-add off")
  endif
  
  if has_key(a:args, "proc")
    call TermDebugSendCommand("attach " . a:args["proc"])
    if has_key(a:args, "br")
      call TermDebugSendCommand("br " . a:args['br'])
      call TermDebugSendCommand("c")
    endif
  elseif has_key(a:args, "exe")
    let cmdArgs = split(a:args["exe"], " ")
    call TermDebugSendCommand("file " . cmdArgs[0])
    if len(cmdArgs) > 1
      call TermDebugSendCommand("set args " . join(cmdArgs[1:], " "))
    endif
    if has_key(a:args, "br")
      call TermDebugSendCommand("br " . a:args['br'])
      call TermDebugSendCommand("r")
    else
      call TermDebugSendCommand("start")
    endif
  elseif has_key(a:args, "headless") && a:args['headless']
    " NO-OP
  endif
endfunction

function! s:DebugRunPost()
  " PASS
endfunction

function! s:DebugStopPre()
  silent! nunmap <leader>v
  silent! vunmap <leader>v
  silent! nunmap <leader>br
  silent! nunmap <leader>tbr
  silent! nunmap <leader>unt
  silent! nunmap <leader>pc

  silent! delcommand Capture
  silent! delcommand Gdb
  silent! delcommand Pwd
  silent! delcommand Backtrace
  silent! delcommand Threads
  silent! delcommand Break
  silent! delcommand Commands
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

function! s:GetHeader()
  let dir = FugitiveWorkTree()
  if !isdirectory(dir)
    return []
  endif
  let header = ["h", "hh", "H", "hp", "hxx", "hpp", "HPP", "h++", "tcc"]
  let regex = '.*\.\(' . join(header, '\|') . '\)'
  return Find(dir, "-regex", regex)
endfunction

function! Header(ArgLead, CmdLine, CursorPos)
  if a:CursorPos < len(a:CmdLine)
    return []
  endif
  return s:GetHeader()->TailItems(a:ArgLead)
endfunction

command! -nargs=? -complete=customlist,Header Header call s:GetHeader()->ArgFilter(<q-args>)->DropInQf('Header')

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

command! -nargs=? -complete=customlist,WorkFilesCompl Workfiles call s:GetWorkFiles()->ArgFilter(<q-args>)->DropInQf('Workfiles')

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
  let debug_args = #{ssh: a:host, br: s:GetDebugLoc()}
  if !empty(a:exe)
    let debug_args['exe'] = a:exe
  endif
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
    let opts = #{ssh: a:host, proc: pid}
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
let s:sdk_dir = "/opt/aisys/obsidian_p10"

function s:ObsidianMake(...)
  let repo = FugitiveWorkTree()
  if empty(repo)
    echo "Not inside repo"
    return
  endif
  let repo = split(FugitiveWorkTree(), "/")[-1]
  let obsidian_repos = ["obsidian-video", "libalcatraz", "mpp", "camera_engine_rkaiq", "badge-and-face"]
  if index(obsidian_repos, repo) < 0
    echo "Unsupported repo: " . repo
    return
  endif

  let common_flags = join([
        \ printf("-isystem %s/sysroots/armv8a-aisys-linux/usr/include/c++/11.4.0/", s:sdk_dir),
        \ printf("-isystem %s/sysroots/armv8a-aisys-linux/usr/include/c++/11.4.0/aarch64-aisys-linux", s:sdk_dir),
        \ printf("-I %s/sysroots/armv8a-aisys-linux/usr/include/liveMedia", s:sdk_dir),
        \ printf("-I %s/sysroots/armv8a-aisys-linux/usr/include/groupsock", s:sdk_dir),
        \ printf("-I %s/sysroots/armv8a-aisys-linux/usr/include/UsageEnvironment", s:sdk_dir),
        \ "-O0 -ggdb -U_FORTIFY_SOURCE"])
  let cxxflags = "export CXXFLAGS=" . string(common_flags)
  let cflags = "export CFLAGS=" . string(common_flags)

  let dir = printf("cd %s", FugitiveWorkTree())
  let env = printf("source %s/environment-setup-armv8a-aisys-linux", s:sdk_dir)

  if repo == 'camera_engine_rkaiq'
    let cmake = printf("cmake -S. -B%s -DCMAKE_BUILD_TYPE=%s", s:build_type, s:build_type)
    let cmake .= printf(" -DIQ_PARSER_V2_EXTRA_CFLAGS='-I%s/sysroots/armv8a-aisys-linux/usr/include/rockchip-uapi;", s:sdk_dir)
    let cmake .= printf("-I%s/sysroots/armv8a-aisys-linux/usr/include'", s:sdk_dir)
    let cmake .= " -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DISP_HW_VERSION='-DISP_HW_V30' -DARCH='aarch64' -DRKAIQ_TARGET_SOC='rk3588'"
  else
    let cmake = printf("cmake -B %s -S . -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=%s", s:build_type, s:build_type)
  endif
  let build = printf("cmake --build %s -j 10", s:build_type)

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
  elseif stridx(fname, "include/rockchip") >= 0
    let basename = fnamemodify(fname, ":t")
    let resolved = "/home/stef/mpp/inc/" . basename
  elseif stridx(fname, "include/liveMedia") >= 0
    let part = matchlist(fname, 'include/liveMedia/\(.*\)')[1]
    let resolved = "/home/stef/live/liveMedia/include/" . part
  elseif stridx(fname, "include/UsageEnvironment") >= 0
    let part = matchlist(fname, 'include/UsageEnvironment/\(.*\)')[1]
    let resolved = "/home/stef/live/UsageEnvironment/include/" . part
  elseif stridx(fname, "include/BasicUsageEnvironment") >= 0
    let part = matchlist(fname, 'include/BasicUsageEnvironment/\(.*\)')[1]
    let resolved = "/home/stef/live/BasicUsageEnvironment/include/" . part
  elseif stridx(fname, "include/groupsock") >= 0
    let part = matchlist(fname, 'include/groupsock/\(.*\)')[1]
    let resolved = "/home/stef/live/groupsock/include/" . part
  endif

  if filereadable(resolved)
    let view = winsaveview()
    exe "edit " . resolved
    call winrestview(view)
  else
    echo "Sorry, I'm buggy, Update me! Resolved to: " . resolved
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

  let cmd = ["rsync", "-rlt"]

  const fast_sync = v:true
  if fast_sync
    " Include all directories
    call add(cmd, '--include=*/')
    " Include all executables
    let exes = systemlist(["find", dir, "-type", "f", "-executable", "-printf", "%P\n"])
    for exe in exes
      " throw exe
      call add(cmd, '--include=' . exe)
    endfor
    " Exclude rest. XXX: ORDER OF FLAGS MATTERS!
    call add(cmd, '--exclude=*')
  endif

  let bang = get(a:000, 0, "")
  if empty(bang)
    call extend(cmd, ["--info=progress2", dir, remote_dir])
    return jobstart(cmd, #{on_stdout: funcref("OnStdout"), on_exit: funcref("OnExit")})
  else
    bot new
    call extend(cmd, ["--info=all4", dir, remote_dir])
    let id = termopen(cmd, #{on_exit: funcref("OnExit")})
    call cursor("$", 1)
    return id
  endif
endfunction

function! s:Resync()
  let dir = FugitiveFind(s:build_type)
  exe printf("autocmd! User MakeSuccessful ++once call s:RemoteSync('%s')", dir)
  call s:ObsidianMake()
endfunction

function s:MakeNiceApp(exe)
  let dst = "/tmp/" .. fnamemodify(a:exe, ":t")
  let cmd = printf("cp %s %s && setcap cap_sys_nice+ep %s", a:exe, dst, dst)
  let msg = systemlist(["ssh", s:host, cmd])
  if v:shell_error
    bot new
    setlocal buftype=nofile
    call setline(1, msg[0])
    call append(1, msg[1:])
    throw "Failed to prepare " . a:exe
  endif
  return dst
endfunction

function! s:PrepareApp(exe)
  if a:exe =~ "obsidian-video$"
    let nice_exe = s:MakeNiceApp(a:exe)
    return #{exe: nice_exe, ssh: s:host, user: "rock-video"}
  elseif a:exe =~ "rtsp-server$"
    let nice_exe = s:MakeNiceApp(a:exe)
    return #{exe: nice_exe, ssh: s:host, user: "rtsp-server"}
  elseif a:exe =~ "badge_and_face$"
    let nice_exe = s:MakeNiceApp(a:exe)
    return #{exe: nice_exe, ssh: s:host, user: "badge_and_face"}
  elseif !empty(a:exe)
    return #{exe: a:exe, ssh: s:host}
  else
    return #{headless: v:true, ssh: s:host}
  endif
endfunction

function! s:DebugApp(exe, run)
  let opts = s:PrepareApp(a:exe)
  if a:run
    let opts['br'] = s:GetDebugLoc()
  endif
  call s:Debug(opts)
endfunction

function s:ChangeHost(host, check)
  if empty(a:host) || a:host == 'localhost'
    command! -nargs=? -complete=customlist,ExeCompl Start call s:StartDebug(<q-args>)
    command! -nargs=? -complete=customlist,ExeCompl Run call s:RunDebug(<q-args>)
    command! -nargs=1 -complete=customlist,AttachCompl Attach call s:AttachDebug(<q-args>)
    silent! delcommand Sshfs
    silent! unlet s:host
    return
  endif

  if a:check
    call system(["ssh", "-o", "ConnectTimeout=1", a:host, "exit"])
    if v:shell_error != 0
      echo "Failed to connect to host " . a:host
      return
    endif
  endif
  let s:host = a:host
  exe printf("command! -nargs=? -complete=customlist,RemoteExeCompl Start call <SID>DebugApp(<q-args>, v:false)")
  exe printf("command! -nargs=? -complete=customlist,RemoteExeCompl Run call <SID>DebugApp(<q-args>, v:true)")
  exe printf("command! -nargs=1 Attach call <SID>RemoteAttach('%s', <q-args>)", s:host)
  exe printf("command! -nargs=1 -complete=customlist,SshfsCompl Sshfs call <SID>Sshfs('%s', <q-args>)", s:host)
endfunction

command! -nargs=? -complete=customlist,ChangeHostCompl Host call s:ChangeHost(<q-args>, 1)

function ChangeHostCompl(ArgLead, CmdLine, CursorPos)
  if a:CursorPos < len(a:CmdLine)
    return []
  endif
  return ['p10', 'broken_rgb', 'miro_camera']
endfunction

if readfile("/etc/hostname") == ["npc"]
  call s:ChangeHost('p10', v:false)
else
  call s:ChangeHost('localhost', v:false)
endif

function! s:StopServices()
  let cmds = []
  let stop_list = ["rtsp-server-noauth", "rtsp-server.socket", "rtsp-server.service", "obsidian-video"]
  for service in stop_list
    let cmd = "systemctl stop " . service
    call add(cmds, cmd)
  endfor

  let msg = systemlist(["ssh", s:host, join(cmds, ";")])
  if v:shell_error
    bot new
    setlocal buftype=nofile
    call setline(1, msg[0])
    call append(1, msg[1:])
    throw "Failed to stop services"
  endif
endfunction

function! s:ToClipboardApp(app)
  call s:StopServices()
  let opts = s:PrepareApp(a:app)
  let @+ = printf("sudo -u %s %s", opts['user'], opts['exe'])
  echom "Copied command to clipboard!"
endfunction

nnoremap <silent> <leader>re <cmd>call <SID>Resync()<CR>
nnoremap <silent> <leader>rv <cmd>call <SID>ToClipboardApp("/var/tmp/Debug/application/obsidian-video")<CR>
nnoremap <silent> <leader>rs <cmd>call <SID>ToClipboardApp("/var/tmp/Debug/application/rtsp-server")<CR>
nnoremap <silent> <leader>rb <cmd>call <SID>ToClipboardApp("/var/tmp/Debug/bin/badge_and_face")<CR>
"}}}

""""""""""""""""""""""""""""Testing"""""""""""""""""""""""""""" {{{
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
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
