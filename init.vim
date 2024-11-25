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
Plug 'sshklifov/rsi'

let s:is_work_pc = isdirectory("/opt/aisys")
if s:is_work_pc
  Plug 'sshklifov/work'
endif

call plug#end()

let s:plug_directory = stdpath("data") .. "/plugged"
if !isdirectory(s:plug_directory)
  finish
endif

let s:session_directory = stdpath('data') .. "/sessions"
if !isdirectory(s:session_directory)
  call systemlist('mkdir ' .. s:session_directory)
  if v:shell_error
    echo "Failed to initialize sessions directory."
    finish
  endif
endif

" Redefine the group, avoids having the same autocommands twice
augroup VimStartup
au!

let s:this_file_path = stdpath("config") .. "/init.vim"
exe printf("autocmd BufWritePost %s source %s", s:this_file_path, s:this_file_path)

""""""""""""""""""""""""""""Plugin settings"""""""""""""""""""""""""""" {{{
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" This script
let g:auto_index_whitelist = ["obsidian-video", "libalcatraz"]

" sshklifov/work
if s:is_work_pc
  let s:default_host = "max_p15"
  if !exists('g:HOST')
    let g:HOST = s:default_host
    let g:DEVICE = "p15"
  endif
  if !exists('g:BUILD_TYPE')
    let g:BUILD_TYPE = "Debug"
  endif
  call plug#load('work')
endif

" sshklifov/rsi
command! -nargs=0 Rest call RsiEnterRest()
command! -nargs=0 Rsi call RsiPrintStats()

" sshklifov/debug
let g:promptdebug_commands = 0
let g:promptdebug_program_output = 1

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
function! init#Sum(...)
  if a:0 == 1 && type(a:1) == v:t_list
    let items = a:1
  else
    let items = a:000
  endif
    let res = 0
    for x in items
      let res += x
    endfor
    return res
endfunction

function! init#Warn(msg)
  call nvim_echo([[a:msg, "WarningMsg"]], v:true, #{})
endfunction

function! init#ToClipboard(msg)
  if empty(a:msg)
    return
  endif
  silent! let @+ = a:msg
  if len(a:msg) < 100
    echom printf("Copied to clipboard: '%s'.", a:msg)
  else
    echo "Copied to clipboard (truncated)."
  endif
endfunction

function s:ScriptLocalVars()
  tabnew
  setlocal buftype=nofile
  setlocal bufhidden=wipe
  call appendbufline(bufnr(), 0, 'Script local variables:')
  for var in keys(s:)
    let msg = printf("%s = %s", var, s:[var])
    call append('$', msg)
  endfor
endfunction

command! -nargs=0 Vars call s:ScriptLocalVars()

" Open vimrc quick (muy importante)
nnoremap <silent> <leader>ev :e ~/.config/nvim/init.vim<CR>
nnoremap <silent> <leader>lv :e ~/.config/nvim/lua/lsp.lua<CR>
nnoremap <silent> <leader>dv :e ~/.local/share/nvim/plugged/debug/plugin/promptdebug.vim<CR>
nnoremap <silent> <leader>wv :e ~/.local/share/nvim/plugged/work/plugin/work.vim<CR>

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
cabbr W w
cabbr Tab tab

function s:Quit(bang)
  let windows = 0
  for tabnr in range(1, tabpagenr('$'))
    let windows += tabpagewinnr(tabnr, '$')
  endfor
  if windows > 1
    exe "q" .. a:bang
    return
  endif

  let mod = getbufinfo(#{bufmodified: 1})
  if empty(a:bang) && !empty(mod)
    exe "b " .. mod[0].bufnr
    echo "No write since last change."
    return
  endif

  if exists('*ConfirmQuit') && !ConfirmQuit()
    return
  endif
  exe "q" .. a:bang
endfunction

function s:QuitAll(bang)
  let mod = getbufinfo(#{bufmodified: 1})
  if empty(a:bang) && !empty(mod)
    let items = []
    let nrs = map(mod, 'v:val.bufnr')
    for nr in nrs
      let dict = getchangelist(nr)[0][-1]
      let dict['bufnr'] = nr
      let dict['text'] = getbufoneline(nr, dict['lnum'])
      call add(items, dict)
    endfor
    call setqflist([], ' ', #{title: 'Modified buffers', items: items})
    copen
    echo "No write since last change."
    return
  endif
  if exists('*ConfirmQuit') && !ConfirmQuit()
    return
  endif
  exe "qa" .. a:bang
endfunction

command! -nargs=0 -bang Q call s:Quit("<bang>")
command! -nargs=0 -bang Qa call s:QuitAll("<bang>")

cabbr q Q
cabbr qa Qa

" Annoying quirks
set updatecount=0
set shortmess+=I
au FileType * setlocal fo-=cro
nnoremap <C-w>t <C-w>T
let mapleader = "\\"

" Increase oldfiles size
set shada=!,'10000,<0,s500,h
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

" Kind of resticts maximum returned length
if !exists('s:status_toggle')
  let s:status_max = 70
endif

command! -nargs=1 Statusline let s:status_max = <f-args>

function! GetFileStatusLine()
  " Return basename for help files
  if &ft == "help"
    return expand("%:t")
  endif
  " Empty buffer -> Display path
  let filename = bufname()
  if empty(filename)
    return getcwd() .. ">"
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
    return s:PathShorten(filename, s:status_max)
  endif

  " Display mixed status
  let filename = filename[len(cwd)+1:]
  const sep = "> "
  return s:PathShorten(cwd . sep . filename, s:status_max)
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
let g:statusline_prio = ['sync', 'make', 'lsp', 'rsi']

function! OnStatusDictChange(...)
  redrawstatus
endfunction

call dictwatcheradd(g:statusline_dict, '*', 'OnStatusDictChange')

function! GetProgressStatusLine(...)
  for key in g:statusline_prio
    if has_key(g:statusline_dict, key) && !empty(g:statusline_dict[key])
      return g:statusline_dict[key] .. ' '
    endif
  endfor
  return ''
endfunction

function! init#BranchName()
  let dict = FugitiveExecute(["branch", "--show-current"])
  if dict['exit_status'] != 0
    return ''
  endif
  return dict['stdout'][0]
endfunction

function! BranchStatusLine()
  let want_status = empty(bufname()) || filereadable(bufname())
  if !want_status
    return ""
  endif
  let dict = FugitiveExecute(["rev-parse", "--abbrev-ref", "HEAD"])
  if dict['exit_status'] != 0
    return ""
  endif
  let ref = dict['stdout'][0]
  if ref == "HEAD"
    let dict = FugitiveExecute(["rev-parse", "HEAD"])
    if dict['exit_status'] != 0
      return ""
    endif
    let ref = dict['stdout'][0][0:10]
  endif
  return ref .. '>'
endfunction

function! HostStatusLine()
  if empty(FugitiveWorkTree())
    return ''
  endif
  if exists('g:HOST') && g:HOST != s:default_host
    return "(" .. g:HOST .. ")"
   else
     return ''
   endif
endfunction

function! BuildStatusLine()
  if empty(FugitiveWorkTree())
    return ''
  endif
  let build_type = get(g:, 'BUILD_TYPE', '')
  if build_type == "Release"
    return "(Release)"
  elseif build_type == "Debug"
    return "(Debug)"
  else
    return ''
  endif
endfunction

set statusline=
set statusline+=%(%{HostStatusLine()}%{%BuildStatusLine()%}\ %)
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
  setlocal bufhidden=wipe
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

function! s:ShowHistory(CmdLine)
  let result = init#HistFind(a:CmdLine)
  call init#CreateCustomQuickfix('History', result, '<SID>SelectCommand')
endfunction

function! s:SelectCommand()
  let command = getline('.')
  quit
  exe command
endfunction

command! -nargs=* History call s:ShowHistory(<q-args>)

function! s:GetSessionFile()
  let repo = fnamemodify(FugitiveWorkTree(), ':t')
  let branch = init#BranchName()
  if !empty(branch) && !empty(repo)
    let branch = substitute(branch, '/', '.', 'g')
    let session_file = printf('%s.%s.vim', repo, branch)
  else
    let session_file = "default_session.vim"
  endif
  return session_file
endfunction

function! s:SaveSession(basename)
  let fullname = s:session_directory .. "/" .. a:basename
  exe "mksession! " .. fullname
  echo fullname
endfunction

nnoremap <silent> <leader><leader>q :call <SID>SaveSession(<SID>GetSessionFile())<CR>

command! -nargs=1 -complete=customlist,SaveCompl Save call s:SaveSession(<q-args>)

function! SaveCompl(ArgLead, CmdLine, CursorPos)
  if a:CursorPos < len(a:CmdLine)
    return []
  endif
  let sessions = s:GetSessions()
  call map(sessions, 'fnamemodify(v:val, ":t")')
  call filter(sessions, 'stridx(v:val, a:ArgLead) >= 0')
  return sessions
endfunction

function! s:GetSessions()
  let dir = stdpath('data') .. '/sessions'
  let session_files = systemlist(['find', dir, '-type', 'f'])
  let Comparator = {lhs, rhs -> getftime(rhs) - getftime(lhs)}
  call sort(session_files, Comparator)
  if v:shell_error
    return []
  else
    return session_files
  endif
endfunction

function! s:ShowSessions(pat)
  let session_files = s:GetSessions()
  if empty(session_files)
    echo "Nothing to show."
    return
  endif
  call init#CreateCustomQuickfix('Sessions', session_files, '<SID>SelectSession')
endfunction

function! s:SelectSession()
  let file = getline('.')
  exe "so " .. file
endfunction

command! -nargs=0 Load call s:ShowSessions('')

nnoremap <silent> <leader>so :exe "so " .. <SID>GetSessions()[0]<CR>

set sessionoptions=buffers,curdir,help,tabpages,winsize

nnoremap <silent> cd :lcd %:p:h<CR>
nnoremap <silent> gcd :Gcd<CR>

nnoremap <silent> <leader>ta :tabnew<CR><C-O>
nnoremap <silent> <leader>tA :-tabnew<CR><C-O>
nnoremap <silent> <leader>tc :tabclose<CR>
nnoremap <silent> <leader>on :only<CR>

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

command! -nargs=0 Shada exe "tabnew " .. stdpath("state") .. "/shada/main.shada" | setlocal bufhidden=wipe

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
  let windows = s:GetWindows(a:ArgLead, 1)
  return uniq(sort(windows))
endfunction

function! s:SimplifyTabs(max_count)
  let infos = map(range(1, bufnr('$')), 'getbufinfo(v:val)')
  call filter(infos, '!empty(v:val)')
  call map(infos, 'v:val[0]')
  let Cmp = {a, b -> b['lastused'] - a['lastused']}
  call sort(infos, Cmp)

  silent! tabonly
  silent! only
  let curr_count = 0
  for info in infos
    if curr_count < a:max_count && filereadable(info['name'])
      exe "b " .. info['bufnr']
      tabnew
      let curr_count += 1
    endif
  endfor
  quit
  tabfirst
endfunction

command! -nargs=? Simp call s:SimplifyTabs(empty(<q-args>) ? 1 : <q-args>)

" CursorHold time
set updatetime=500
set completeopt=menuone,noinsert
set pumheight=10

" http://vim.wikia.com/wiki/Automatically_append_closing_characters
inoremap {<CR> {<CR>}<C-o>O

nmap <leader>sp :setlocal invspell<CR>
" }}}

""""""""""""""""""""""""""""Git"""""""""""""""""""""""""""" {{{
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
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
    let was_winid = win_getid()
    if exists("b:commitish") && b:commitish != "0"
      exe "lefta Gdiffsplit " . b:commitish
    else
      exe "lefta Gdiffsplit"
    endif
    call win_gotoid(was_winid)
  endif
endfunction

nnoremap <silent> <leader>dif :call <SID>ToggleDiff()<CR>

function! s:Operator(cmd, pending)
  let &operatorfunc = function('<SID>DoOperatorCmd', [a:cmd])
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
  " Git reports these duplicated sometimes
  call uniq(sort(files))
  return map(files, "FugitiveFind(v:val)")
endfunction

command! -nargs=? -complete=customlist,UnstagedCompl Dirty
      \ call s:GetUnstaged()->FileFilter(<q-args>)->DropInQf("Unstaged")

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
      \ call s:GetUntracked()->FileFilter(<q-args>)->DropInQf("Untracked")

function UntrackedCompl(ArgLead, CmdLine, CursorPos)
  if a:CursorPos < len(a:CmdLine)
    return []
  endif
  return s:GetUntracked(bang)->TailItems(a:ArgLead)
endfunction

function! init#WorkTreeCleanOrThrow()
  let dict = FugitiveExecute(["status", "--porcelain"])
  if dict['exit_status'] != 0
    throw "Not inside repo"
  endif
  if dict['stdout'][0] != ''
    throw "Work tree not clean"
  endif
endfunction

function! init#CheckedBranchOrThrow()
  let dict = FugitiveExecute(["rev-parse", "--abbrev-ref", "HEAD"])
  if dict['exit_status'] != 0
    throw "Not inside repo"
  endif
  return dict['stdout'][0]
endfunction

function init#TryCall(what, ...)
  let Partial = function(a:what, a:000)
  try
    return Partial()
  catch
    echo v:exception
  endtry
endfunction

function! init#SwitchToBranchOrThrow(arg)
  call init#WorkTreeCleanOrThrow()

  let dict = FugitiveExecute(["checkout", a:arg])
  if dict['exit_status'] != 0
    throw "Failed to checkout " . a:arg
  endif
  call FugitiveExecute(["submodule", "update", "--init", "--recursive"])
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

function! s:OpenBranchBuffer()
  let dict = FugitiveExecute(["for-each-ref", "--sort=-committerdate", "refs/heads/", "--format=%(refname:short)"])
  if dict['exit_status'] != 0
    return init#ShowErrors(dict['stderr'])
  endif
  let branches = filter(dict['stdout'], '!empty(v:val)')
  call init#CreateCustomQuickfix('Branches', branches, '<SID>SelectBranch')
endfunction

function! s:SelectBranch()
  let branch = getline('.')
  quit
  call init#TryCall("init#SwitchToBranchOrThrow", branch)
endfunction

function s:Branch(args)
  if empty(a:args)
    call s:OpenBranchBuffer()
  else
    call init#TryCall("init#SwitchToBranchOrThrow", a:args)
  endif
endfunction

command! -nargs=? -complete=customlist,BranchCompl Branch call s:Branch(<q-args>)

function! BranchCompl(ArgLead, CmdLine, CursorPos)
  if a:CursorPos < len(a:CmdLine)
    return []
  endif
  return s:GetRefs(['refs/heads', 'refs/tags'], a:ArgLead)
endfunction

command! -nargs=1 -bang -complete=customlist,OriginCompl Origin
      \ call init#TryCall("init#SwitchToBranchOrThrow", <q-args>)

function! init#ShowErrors(errors)
  let errors = map(a:errors, "strtrans(v:val)")
  if empty(errors)
    let errors = ["<No errors to show>"]
  endif

  let nr = init#CreateCustomBuffer('Errors', errors)
  bot sp
  exe "b " .. nr
endfunction

function! s:UpdateBranch()
  let branch = FugitiveHead()
  let check_file = printf("%s/refs/remotes/origin/%s", FugitiveGitDir(), branch)
  if !filereadable(check_file)
    echo "Could not find origin/" .. branch
    return
  endif

  let args = ["fetch", "origin", branch]
  let dict = FugitiveExecute(args)
  if dict['exit_status'] != 0
    return init#ShowErrors(dict['stderr'])
  endif

  const range = printf("%s..origin/%s", branch, branch)
  let args = ["log", "--pretty=format:%h", range]
  let dict = FugitiveExecute(args)
  if dict['exit_status'] != 0
    return init#ShowErrors(dict['stderr'])
  endif
  const commits = filter(dict['stdout'], "!empty(v:val)")

  if len(commits) <= 0
    echo "No changes."
    return
  endif

  let args = ["merge", "origin/" .. branch]
  let dict = FugitiveExecute(args)
  if dict['exit_status'] != 0
    return init#ShowErrors(dict['stderr'])
  endif
  exe printf("G log -n %d %s", len(commits), commits[0])
endfunction

command! -nargs=0 Pull call s:UpdateBranch()

function! s:PushBranch(force)
  if a:force
    let dict = FugitiveExecute(["push", "--force", "origin", "HEAD"])
  else
    call init#WorkTreeCleanOrThrow()
    let dict = FugitiveExecute(["push", "origin", "HEAD"])
  endif
  if dict['exit_status'] != 0
    return init#ShowErrors(dict['stderr'])
  elseif s:is_work_pc
    let issue = work#BranchIssueNumber()
    if !empty(issue)
      return work#OpenJira(issue)
    endif
  endif
  echo "Up to date with origin."
endfunction

command! -nargs=0 -bang Push call s:PushBranch(<bang>0)

function! OriginCompl(ArgLead, CmdLine, CursorPos)
  if a:CursorPos < len(a:CmdLine)
    return []
  endif
  call FugitiveExecute(['fetch', 'origin'])
  return s:GetRefs(['refs/remotes/origin'], a:ArgLead)
endfunction

function! s:RecentRefs(max_refs)
  let max_refs = a:max_refs
  if type(max_refs) == v:t_number
    let max_refs = string(max_refs)
  endif
  let dict = FugitiveExecute(["reflog", "-n", max_refs, "--pretty=format:%H"])
  if dict['exit_status'] != 0
    return []
  endif
  let hashes = dict['stdout']
  let dict = FugitiveExecute(["name-rev", "--annotate-stdin", "--name-only"], #{stdin: hashes})
  if dict['exit_status'] != 0
    return []
  endif
  let refs = dict['stdout']
  call filter(refs, "!empty(v:val)")
  return refs
endfunction

command -nargs=1 -bang -complete=customlist,ReflogCompl Reflog
      \ call init#TryCall("init#SwitchToBranchOrThrow", <q-args>)

cabbr Ref Reference

function! ReflogCompl(ArgLead, CmdLine, CursorPos)
  if a:CursorPos < len(a:CmdLine)
    return []
  endif
  let refs = s:RecentRefs(30)
  call filter(refs, "stridx(v:val, a:ArgLead) >= 0")
  return refs[1:]
endfunction

function! init#CreateCustomBuffer(name, lines)
  let nr = bufadd(a:name)
  call setbufvar(nr, '&buftype', 'nofile')
  call setbufvar(nr, '&bufhidden', 'wipe')
  call bufload(nr)
  call setbufline(nr, 1, a:lines)
  call setbufvar(nr, '&modified', v:false)
  call setbufvar(nr, '&modifiable', v:false)
  return nr
endfunction

function! init#CreateCustomQuickfix(name, lines, cb)
  let nr = init#CreateCustomBuffer('History', a:lines)
  bot sp
  resize 10
  exe "b " .. nr
  setlocal cursorline
  exe "nnoremap <silent> <buffer> <CR> :call " .. a:cb .. "()<CR>"
  return nr
endfunction

function! s:DanglingCommits()
  let refs = s:RecentRefs(100)
  call filter(refs, 'v:val =~# "^\\x*$"')
  call init#CreateCustomQuickfix('Dangling commits', refs, '<SID>VisitCommit')
endfunction

function! s:VisitCommit()
  let ns = nvim_create_namespace('dangling_commits')
  call nvim_buf_set_extmark(bufnr(), ns, line('.') - 1, 0, #{line_hl_group: "Conceal"})
  exe "G log " .. getline(".")
endfunction

command! -nargs=0 Dangle call s:DanglingCommits()

function! init#MasterOrThrow()
  let branches = s:GetRefs(['refs/remotes'], 'ma')
  if index(branches, 'origin/obsidian-master') >= 0
    return 'origin/obsidian-master'
  elseif index(branches, 'origin/master') >= 0
    return 'origin/master'
  elseif index(branches, 'origin/main') >= 0
    return 'origin/main'
  else
    throw "Failed to determine mainline."
  endif
endfunction

function! init#HashOrThrow(commitish)
  let dict = FugitiveExecute(["rev-parse", a:commitish])
  if dict['exit_status'] != 0
    throw "Failed to parse " .. a:commitish
  endif
  return dict['stdout'][0]
endfunction

function! init#BranchCommitsOrThrow(branch, main)
  let range = printf("%s..%s", a:main, a:branch)
  let dict = FugitiveExecute(["log", range, "--pretty=format:%H"])
  if dict['exit_status'] != 0
    throw "Revision range failed"
  endif
  return dict['stdout']
endfunction

function! init#CommonParentOrThrow(branch, main)
  let range = init#BranchCommitsOrThrow(a:branch, a:main)
  let branch_first = range[-1]
  if empty(branch_first)
    " 'branch' and 'main' are the same commits
    return a:main
  endif
  " Go 1 back to find the common commit
  let dict = FugitiveExecute(["rev-parse", branch_first . "~1"])
  if dict['exit_status'] != 0
    throw "Failed to go back 1 commit from " . branch_first
  endif
  let common = dict['stdout'][0]
  return common
endfunction

function! init#RefExistsOrThrow(commit)
  if FugitiveExecute(["show", a:commit])['exit_status'] != 0
    throw "Unknown ref to git: " . a:commit
  endif
endfunction

function! init#InsideGitOrThrow()
  if FugitiveExecute(["status"])['exit_status'] != 0
    throw "Not inside repo"
  endif
endfunction

function! s:Review(arg)
  " Refresh current state of review
  if exists("g:review_stack")
    let items = g:review_stack[-1]
    call DisplayInQf(items, "Review")
    echo "Review in progress, refreshing quickfix..."
    return
  endif

  call init#InsideGitOrThrow()
  " Determine main branch
  let head = init#HashOrThrow("HEAD")
  let mainline = empty(a:arg) ? init#MasterOrThrow() : a:arg
  call init#RefExistsOrThrow(mainline)
  let bpoint = init#CommonParentOrThrow(head, mainline)
  " Load files for review.
  " If possible, make the diff windows editable by not passing a ref to fugitive
  if get(a:, "arg", "") == "HEAD"
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

command! -nargs=? -complete=customlist,BranchCompl Review call init#TryCall("s:Review", <q-args>)

command! -nargs=0 D Review HEAD
command! -nargs=* R execute "Review " .. <q-args>

function! s:CompleteFiles(cmd_bang, arg) abort
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
    call init#Warn("Review completed")
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

command! -bang -nargs=? -complete=customlist,CompleteCompl Complete  call <SID>CompleteFiles('<bang>', <q-args>)

function! s:PostponeFile()
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
nnoremap <silent> <leader>nok <cmd>call <SID>PostponeFile()<CR>

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

function! s:Pickaxe(keyword)
  call init#InsideGitOrThrow()
  " Determine branch.
  let head = init#HashOrThrow("HEAD")
  let mainline = init#MasterOrThrow()
  let commits = init#BranchCommitsOrThrow(head, mainline)
  " Add a fake commit for unstanged changes
  call add(commits, "0000000000000000000000000000000000000000")
  " Get changed files.
  let dict = FugitiveExecute(["diff", "HEAD~" .. len(commits), "--name-only"])
  if dict['exit_status'] != 0
    throw "Collecting changed filed failed"
  endif
  let files = dict['stdout']
  call map(files, 'FugitiveFind(v:val)')
  " Run git bame on each file
  let output = []
  for file in files
    let dict = FugitiveExecute(["blame", "-p", "--", file])
    if dict['exit_status'] != 0
      " File might have been deleted
      continue
    endif
    let blame = dict['stdout']
    let idx = 0
    while idx < len(blame)
      if blame[idx] =~# '^\x\{40\}'
        let [_, commit, orig_lnum, lnum; _] = matchlist(blame[idx], '\(\x*\) \(\d*\) \(\d*\)')
        if index(commits, commit) >= 0
          while blame[idx][0] != "\t"
            let idx += 1
          endwhile
          if stridx(blame[idx], a:keyword) >= 0
            call add(output, #{filename: file, lnum: lnum, text: blame[idx][1:]})
          endif
        endif
      endif
      let idx += 1
    endwhile
  endfor
  call DisplayInQf(output, 'Pickaxe')
endfunction

command! -nargs=0 Todo call init#TryCall('s:Pickaxe', 'TODO')
command! -nargs=* Pickaxe call init#TryCall('s:Pickaxe', <q-args>)
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
    " copen
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

function! s:BlockHierarchy()
  let pos = getpos('.')[1:2]
  let blocks = []
  while v:true
    let entry = #{filename: bufname(), lnum: pos[0], col: pos[1], text: getline(pos[0])}
    call add(blocks, entry)
    keepjumps normal [{
    let next_pos = getpos('.')[1:2]
    if next_pos == pos
      break
    endif
    let pos = next_pos
  endwhile
  call setqflist([], ' ', #{title: 'Blocks', items: reverse(blocks)})
  copen
  silent keepjumps clast
endfunction

command! -nargs=0 Blocks call s:BlockHierarchy()

" Navigate folds
nnoremap [z zo[z
nnoremap ]z zo]z

function! s:OpenSource()
  let extensions = [".cpp", ".c", ".cc"]
  for ext in extensions
    let file = expand("%:r") . ext
    if filereadable(file)
      if bufnr() != bufnr(file)
        exe "edit " . file
      endif
      return
    endif

    let file = substitute(file, "include", "src", "")
    if filereadable(file)
      if bufnr() != bufnr(file)
        exe "edit " . file
      endif
      return
    endif
  endfor

  " Default to search in root of workspace
  let glob = expand("%:t:r") . ".c*"
  call QuickFind(FugitiveWorkTree(), "-iname", glob)
endfunction

function! s:OpenHeader()
  let extensions = [".h", ".hpp", ".hh"]
  for ext in extensions
    let file = expand("%:r") . ext
    if filereadable(file)
      if bufnr() != bufnr(file)
        exe "edit " . file
      endif
      return
    endif

    let file = substitute(file, "src", "include", "")
    if filereadable(file)
      if bufnr() != bufnr(file)
        exe "edit " . file
      endif
      return
    endif
  endfor

  " Default to search in root of workspace
  let glob = expand("%:t:r") . ".h*"
  call QuickFind(FugitiveWorkTree(), "-iname", glob)
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

function! s:FugitiveCommit()
  " return split(FugitiveParse()[0], ":")[0]
  return FugitiveParse()[0]
endfunction

nnoremap <silent> <leader>com <cmd> exe "Gedit " .. <SID>FugitiveCommit()<CR>

" TODO init#SwitchToBranchOrThrow with FugitiveCommit?

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

function! s:SearchOrStay(pat, flags)
  if getline('.') !~ a:pat
    call search(a:pat, a:flags)
  endif
endfunction

function! s:OursOrTheirs()
  if getline('.') =~ '=\{7\}'
    echo "Choose context to resolve!"
    return
  endif
  call s:SearchOrStay('[<=>]\{7}', 'bW')

  if getline('.') =~ '<\{7}'
    delete
    call s:SearchOrStay('=\{7}', 'W')
    let firstline = line('.')
    call s:SearchOrStay('>\{7}', 'W')
    let lastline = line('.')
    exe printf("%d,%ddelete", firstline, lastline)
  elseif getline('.') =~ '=\{7}'
    let lastline = line('.')
    call s:SearchOrStay('<\{7}', 'bW')
    let firstline = line('.')
    exe printf("%d,%ddelete", firstline, lastline)
    call s:SearchOrStay('>\{7}', 'W')
    delete
  elseif getline('.') =~ '>\{7}'
    delete
    call s:SearchOrStay('=\{7}', 'bW')
    let lastline = line('.')
    call s:SearchOrStay('<\{7}', 'bW')
    let firstline = line('.')
    exe printf("%d,%ddelete", firstline, lastline)
  else
    echo "Not inside a conflict"
  endif
endfunction

command! -nargs=0 Resolve call s:OursOrTheirs()

function s:OpenStackTrace()
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
endfunction

command! -nargs=0 Crashtrace call s:OpenStackTrace()

function! init#HistFind(...)
  " XXX becuase of E464 this is mostly ok
  let f_list = []
  for cmd_prefix in a:000
    call add(f_list, printf('stridx(v:val, "%s") == 0', cmd_prefix))
  endfor
  let f_str = join(f_list, ' || ')

  let hist = map(range(1, histnr(':')), 'histget(":", v:val)')
  return reverse(filter(hist, f_str))
endfunction

function! HistoryCompl(ArgLead, CmdLine, CursorPos)
  if a:CursorPos < len(a:CmdLine)
    return []
  endif
  let prefix = len(a:CmdLine) - len(a:ArgLead)
  let result = init#HistFind(a:CmdLine)
  return map(result, 'v:val[prefix:]')
endfunction
"}}}

""""""""""""""""""""""""""""Debugging"""""""""""""""""""""""""""" {{{
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! PrettyPrinterFilesystem(expr)
  let path_expr = printf('%s._M_pathname._M_dataplus._M_p', a:expr)
  return [[0, 'pathname', path_expr]]
endfunction

function! PrettyPrinterFormat(expr)
  let pix = a:expr .. ".format.fmt.pix"
  let width = pix .. ".width"
  let height = pix .. ".height"
  let fmt = pix .. ".pixelformat"
  return [[0, "width", width], [0, "height", height], [0, "format", fmt]]
endfunction

function! s:StartDebug(exe)
  let exe = empty(a:exe) ? "a.out" : a:exe
  let opts = {"exe": exe}
  call init#Debug(opts)
endfunction

function! s:RunDebug(exe)
  let exe = empty(a:exe) ? "a.out" : a:exe
  let opts = #{exe: exe, br: init#GetDebugLoc()}
  call init#Debug(opts)
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
  let pids = systemlist(["pgrep", "-f", a:proc])
  " Report error
  if len(pids) == 0
    echo "No processes found"
    return
  elseif len(pids) > 1
    echo "Multiple processes found"
    return
  endif
  let opts = #{proc: pids[0]}
  call init#Debug(opts)
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

if !s:is_work_pc
  command! -nargs=? -complete=customlist,ExeCompl Start call s:StartDebug(<q-args>)
  command! -nargs=? -complete=customlist,ExeCompl Run call s:RunDebug(<q-args>)
  command! -nargs=1 -complete=customlist,AttachCompl Attach call s:AttachDebug(<q-args>)
endif

" Available modes:
" - exe. Pass executable + arguments
" - proc. Process pid to attach.
" - headless. Do not run any inferior
" Other arguments:
" - symbols. Whether to load symbols or not. Used for faster loading of gdb.
" - ssh. Launch GDB over ssh with the given address.
" - br. Place a breakpoint at location and run inferior.
function! init#Debug(args)
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

  if PromptDebugIsOpen()
    echoerr 'Terminal debugger already running, cannot run two'
    return
  endif

  " Install new autocmds
  autocmd! User PromptDebugStopPost call s:DebugStopPost()
  autocmd! User PromptDebugRunPost call s:DebugRunPost()

  " Remove annoying highlighting
  highlight clear LspReferenceText
  highlight LspReferenceText gui=NONE

  " Run configurations once GDB is loaded
  let cmd = printf("call s:DebugStartPost(%s)", string(a:args))
  exe "autocmd! User PromptDebugStartPost " .. cmd

  " Open GDB
  if has_key(a:args, "ssh")
    if has_key(a:args, "user")
      call PromptDebugStart(a:args["ssh"], a:args["user"])
    else
      call PromptDebugStart(a:args["ssh"])
    endif
  else
    call PromptDebugStart()
  endif
endfunction

function! s:DebugStartPost(args)
  let quick_load = has_key(a:args, "symbols") && !a:args["symbols"]

  command! -nargs=0 Capture call PromptDebugGoToCapture()
  command! -nargs=0 Gdb call PromptDebugGoToGdb()
  command! -nargs=0 Output call PromptDebugGoToOutput()
  command! -nargs=0 Pwd call PromptDebugShowPwd()
  command! -nargs=0 DebugSym call PromptDebugFindSym(expand('<cword>'))
  command! -nargs=? Break call PromptDebugGoToBreakpoint(<q-args>)

  nnoremap <silent> <leader>v <cmd>call PromptDebugEvaluate(expand('<cword>'))<CR>
  vnoremap <silent> <leader>v :<C-u>call PromptDebugEvaluate(init#GetRangeExpr())<CR>

  nnoremap <silent> <leader>br :call PromptDebugSendCommand("br " . init#GetDebugLoc())<CR>
  nnoremap <silent> <leader>tbr :call PromptDebugSendCommand("tbr " . init#GetDebugLoc())<CR>
  nnoremap <silent> <leader>unt :call PromptDebugSendCommands("tbr " . init#GetDebugLoc(), "c")<CR>
  nnoremap <silent> <leader>pc :call PromptDebugGoToPC()<CR>

  call PromptDebugSendCommand("set debug-file-directory /dev/null")
  call PromptDebugSendCommand("set print asm-demangle on")
  call PromptDebugSendCommand("set print pretty on")
  call PromptDebugSendCommand("set print frame-arguments none")
  call PromptDebugSendCommand("set print raw-frame-arguments off")
  call PromptDebugSendCommand("set print entry-values no")
  call PromptDebugSendCommand("set print inferior-events off")
  call PromptDebugSendCommand("set print thread-events off")
  call PromptDebugSendCommand("set print object on")
  call PromptDebugSendCommand("set breakpoint pending on")
  call PromptDebugSendCommand("skip -rfu ^std::")
  call PromptDebugSendCommand("skip -rfu ^cv::")
  if quick_load
    call PromptDebugSendCommand("set auto-solib-add off")
  endif

  " Custom pretty printers
  call PromptDebugPrettyPrinter(['std::filesystem'], "PrettyPrinterFilesystem")
  call PromptDebugPrettyPrinter(['v4l2::Format'], "PrettyPrinterFormat")

  if has_key(a:args, "proc")
    call PromptDebugSendCommand("attach " . a:args["proc"])
    if has_key(a:args, "br")
      call PromptDebugSendCommand("br " . a:args['br'])
      call PromptDebugSendCommand("c")
    endif
  elseif has_key(a:args, "exe")
    let cmdArgs = split(a:args["exe"], " ")
    call PromptDebugSendCommand("file " . cmdArgs[0])
    if len(cmdArgs) > 1
      call PromptDebugSendCommand("set args " . join(cmdArgs[1:], " "))
    endif
    if has_key(a:args, "br")
      call PromptDebugSendCommand("br " . a:args['br'])
      call PromptDebugSendCommand("r")
    else
      call PromptDebugSendCommand("start")
    endif
  elseif has_key(a:args, "headless") && a:args['headless']
    " NO-OP
  endif
endfunction

function! s:DebugRunPost()
  call PromptDebugSendCommand("set scheduler-locking step")
endfunction

function! s:DebugStopPost()
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

  " Restore highlighting
  highlight clear LspReferenceText
  highlight LspReferenceText guibg=#51576e gui=underline
endfunction

function! init#GetDebugLoc()
  let basename = expand("%:t")
  let lnum = line(".")
  return printf("%s:%d", basename, lnum)
endfunction

function! init#GetRangeExpr()
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
command! -nargs=0 LspProg lua print(vim.inspect(vim.lsp.status()))

command! -nargs=0 -range=% For lua vim.lsp.buf.format{ range = {start= {<line1>, 0}, ["end"] = {<line2>, 0}} }

" Document highlight
highlight LspReferenceText guibg=#51576e gui=underline
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

command! -nargs=* Find call QuickFind(getcwd(), "-regex", ".*" .. <q-args> .. ".*")

command! -nargs=+ Grepo call QuickGrep(<q-args>, FugitiveWorkTree())

function! s:GetSource(...)
  let dir = get(a:000, 0, '')
  if empty(dir)
    let dir = FugitiveWorkTree()
  endif
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

command! -nargs=? -complete=customlist,SourceCompl Source call s:GetSource()->FileFilter(<q-args>)->DropInQf('Source')

function! s:GetHeader(...)
  let dir = get(a:000, 0, '')
  if empty(dir)
    let dir = FugitiveWorkTree()
  endif
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

command! -nargs=? -complete=customlist,Header Header call s:GetHeader()->FileFilter(<q-args>)->DropInQf('Header')

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

command! -nargs=? -complete=customlist,WorkFilesCompl Workfiles call s:GetWorkFiles()->FileFilter(<q-args>)->DropInQf('Workfiles')

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

function! s:SymbolInfo()
  let params = v:lua.vim.lsp.util.make_position_params()
  let resp = s:LspRequestSync(0, 'textDocument/symbolInfo', params)
  return resp[0]
endfunction

function! s:Instances()
  let params = v:lua.vim.lsp.util.make_position_params()
  let resp = s:LspRequestSync(0, 'textDocument/references', params)
  if empty(resp)
    echo "No response"
    return
  endif
  let info = s:SymbolInfo()
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

if !exists('s:lsp_files_to_index')
  let s:lsp_files_to_index = #{}
endif

function! s:Index(wt)
  let files = s:GetSource(a:wt) + s:GetHeader(a:wt)
  for file in files
    if !has_key(g:lsp_status, file)
      let s:lsp_files_to_index[file] = 1
      let nr = bufadd(file)
      call bufload(nr)
    endif
  endfor
endfunction

command! -nargs=? -complete=dir Index call s:Index(empty(<q-args>) ? FugitiveWorkTree() : fnamemodify(<q-args>, ":p"))

if !exists('g:lsp_status')
  let g:lsp_status = #{}
endif

function! UpdateLspStatus(key, value)
  if empty(s:lsp_files_to_index)
    return
  endif
  let g:lsp_status[a:key] = a:value

  if a:value == "idle"
    let s:lsp_files_to_index[a:key] = 0
  endif
  let total = len(s:lsp_files_to_index)
  let indexed = len(filter(copy(s:lsp_files_to_index), 'v:val == 0'))
  let percent = indexed * 100 / total
  let g:statusline_dict['lsp'] = percent .. '%'
  
  if indexed == total
    echo "Index complete!"
    let g:statusline_dict['lsp'] = ''
    let s:lsp_files_to_index = #{}
    redrawstatus
  endif
endfunction
"}}}

""""""""""""""""""""""""""""Remote"""""""""""""""""""""""""""" {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! init#RemoteStart(host, exe)
  let debug_args = #{ssh: a:host}
  if !empty(a:exe)
    let debug_args['exe'] = a:exe
  endif
  call init#Debug(debug_args)
endfunction

function! init#RemoteRun(host, exe)
  let debug_args = #{ssh: a:host, br: init#GetDebugLoc()}
  if !empty(a:exe)
    let debug_args['exe'] = a:exe
  endif
  call init#Debug(debug_args)
endfunction

function! init#RemotePid(host, proc)
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

function! init#RemoteAttach(host, proc)
  if a:proc =~ '^[0-9]\+$'
    let pid = a:proc
  else
    let pid = init#RemotePid(a:host, a:proc)
  endif
  if pid > 0
    let opts = #{ssh: a:host, proc: pid}
    call init#Debug(opts)
  endif
endfunction

function! init#SshTerm(remote)
  tabnew
  startinsert
  let id = termopen(["ssh", a:remote])
endfunction

function! init#Sshfs(remote, args)
  silent exe "tabnew scp://" . a:remote . "/" . a:args
endfunction

function! init#Scp(remote)
  let cmd = printf("rsync -pt %s %s:/tmp", expand("%:p"), a:remote)
  let ret = systemlist(cmd)
  if v:shell_error
    call init#ShowErrors(ret)
  else
    echo "Copied to /tmp."
  endif
endfunction

function! init#RemoteRecentFiles(bang, remote, ...)
  let p = get(a:, 1, '')
  let regex = '.*' .. p .. '.*'
  if !empty(a:bang)
    let file_args = printf('-type f -regex "%s"', regex)
  else
    let file_args = printf('-type f -cmin -5 -regex "%s"', regex)
  endif
  let cmd = printf('find / -path /proc -prune -type f -o -path /sys -prune -type f -o \( %s \)', file_args)
  let files = systemlist(["ssh", a:remote, cmd])
  call init#CreateCustomQuickfix('Remote files', files, '<SID>SelectRemoteFile')
endfunction

function! s:SelectRemoteFile()
  let file = getline('.')
  quit
  exe "Sshfs " .. file
endfunction
"}}}

" Go back to default autocommand group
augroup END
