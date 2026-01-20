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
Plug 'sshklifov/git'

" TODO: Do I want to restore custom quickfix with <leader>cc?

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

" sshklifov/git
let g:git_install = 1
" Mostly remove search from foldopen
set foldopen=block,hor,jump,mark,quickfix,undo

" sshklifov/work
if s:is_work_pc
  let g:RSYNC_DIR = "/var/tmp"
  let s:default_host = "p15"
  if !exists('g:HOST')
    let g:HOST = s:default_host
    let g:DEVICE = "p15"
  endif
  call plug#load('work')
endif

if !exists('g:BUILD_TYPE')
  let g:BUILD_TYPE = "Release"
endif

" sshklifov/rsi
command! -nargs=0 Rest Rsi EnterRest

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
let g:qsearch_exclude_dirs = [".cache", ".git", "Debug", "Release", "RelWithDebInfo", "build"]
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
  LspRestart
endfunction

command! -nargs=1 -complete=file Rename call <SID>Rename(<q-args>)

function! s:Delete(bang)
  if !executable("kioclient5")
    call init#Warn("kioclient5 is not installed!")
  endif
  try
    let file = expand("%:p")
    exe "bw" . a:bang
  catch
    echoerr "No write since last change. Add ! to override."
  endtry
  call init#TryCall('init#SystemOrThrow', ["kioclient5", "move", file, 'trash:/'])
endfunction

command! -nargs=0 -bang Delete call <SID>Delete('<bang>')

" tpope/vim-commentary
autocmd BufEnter *.fish setlocal commentstring=#\ %s
autocmd FileType vim setlocal commentstring=\"\ %s
autocmd FileType cpp setlocal commentstring=\/\/\ %s
autocmd BufEnter *.cl setlocal ft=c

" tpope/vim-fugitive
set diffopt-=horizontal
set diffopt+=vertical
"}}}

""""""""""""""""""""""""""""Everything else"""""""""""""""""""""""""""" {{{
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! init#GetState()
  return deepcopy(s:)
endfunction

func init#Get(what, ...)
  if type(a:what) != v:t_dict && type(a:what) != v:t_list
    throw "Invalid arguments, expecting dictionary or list"
  endif
  let result = a:what
  let default = a:000[-1]
  for key in a:000[:-2]
    if type(result) == v:t_dict && !has_key(result, key)
      return default
    endif
    if type(result) == v:t_list && len(result) >= key
      return default
    endif
    let result = result[key]
  endfor
  return result
endfunc

function! init#AppendChunks(bufnr, lnum, chunks)
  let line = join(map(copy(a:chunks), "v:val[0]"), '')
  if nvim_buf_line_count(a:bufnr) > 0
    call appendbufline(a:bufnr, a:lnum, line)
  else
    call setbufline(a:bufnr, a:lnum, line)
  endif

  let ns = nvim_create_namespace('ChunkHighlight')
  let end_col = 0
  for [msg, hl_group] in a:chunks
    let start_col = end_col
    let end_col = start_col + len(msg)
    if end_col > start_col
      let opts = #{end_col: end_col, hl_group: hl_group}
      call nvim_buf_set_extmark(a:bufnr, ns, a:lnum, start_col, opts)
    endif
  endfor
endfunc

function! init#AppendChunksAtEnd(bufnr, chunks)
  let lnum = nvim_buf_line_count(a:bufnr)
  call init#AppendChunks(a:bufnr, lnum, a:chunks)
endfunction

function! init#CopySyntax(src_lnum, dst_buf, ...)
  let items = []
  let text = ""
  let text_hl = ""
  let src_line = getline(a:src_lnum)
  for idx in range(len(src_line))
    let hl = synID(a:src_lnum, idx + 1, 1)->synIDattr("name")
    if hl == text_hl
      let text ..= src_line[idx]
    else
      call add(items, [text, text_hl])
      let text = src_line[idx]
      let text_hl = hl
    endif
  endfor
  call add(items, [text, text_hl])
  let dst_lnum = get(a:000, 0, nvim_buf_line_count(a:dst_buf))
  call init#AppendChunks(a:dst_buf, dst_lnum, items)
endfunction

function! init#CreateCustomBuffer(name, lines)
  let nr = bufadd(a:name)
  call setbufvar(nr, '&buftype', 'nofile')
  call setbufvar(nr, '&bufhidden', 'wipe')
  call bufload(nr)
  call setbufvar(nr, '&modifiable', v:true)
  call setbufline(nr, 1, a:lines)
  call setbufvar(nr, '&modifiable', v:false)
  call setbufvar(nr, '&modified', v:false)
  return nr
endfunction

function! init#CustomBottomBuffer(name, lines)
  let nr = init#CreateCustomBuffer(a:name, a:lines)
  bot sp
  exe "b " .. nr
  return nr
endfunction

function! init#OnTermSuccess(id, cb, ...)
  let id = str2nr(a:id)
  let info = nvim_get_chan_info(id)
  let nr = info["buffer"]
  call assert_true(type(a:cb) == type(""))
  let Cb = function(a:cb, a:000)
  exe printf("autocmd TermClose <buffer=%d> ++once call s:DoTermClose(%d, %s)", nr, nr, string(Cb))
endfunction

function! s:DoTermClose(bufnr, Cb)
  let status = v:event['status']
  if status == 0
    exe "bw " .. a:bufnr
    call a:Cb()
  endif
endfunction

function! init#OnBufDelete(nr, cb, ...)
  call assert_true(type(a:cb) == type(""))
  let Cb = function(a:cb, a:000)
  exe printf("autocmd BufWipeout <buffer=%d> ++once call %s()", a:nr, string(Cb))
endfunction

function! init#Jobstart(cmds, ...)
  if a:0 > 0
    let id = jobstart(a:cmds, a:1)
  else
    let id = jobstart(a:cmds)
  endif
  if !exists('s:job_list')
    let s:job_list = []
  endif
  if type(a:cmds) == type([])
    let args = join(a:cmds)
  else
    let args = a:cmds
  endif
  call add(s:job_list, #{id: id, args: args})
  return id
endfunction

function! s:ShowJobs()
  if !exists('s:job_list')
    echo "No jobs."
    return
  endif

  for j in s:job_list
    if !has_key(j, 'exitted')
      silent! let pid = jobpid(j.id)
      if pid <= 0
        let j['exitted'] = 1
      endif
    endif
  endfor
  let lines = map(copy(s:job_list), 'v:val.args')
  call init#CustomBottomBuffer('Jobs', lines)

  let exitted = map(copy(s:job_list), 'has_key(v:val, "exitted")')
  let ns = nvim_create_namespace('jobs')
  for i in range(len(exitted))
    if exitted[i]
      call nvim_buf_set_extmark(bufnr(), ns, i, 0, #{line_hl_group: "Conceal"})
    endif
  endfor
endfunction

command! -nargs=0 Jobs call s:ShowJobs()

function! init#OnJobProcess(cmds, input, cb, ...)
  call assert_true(type(a:cb) == v:t_string)
  call assert_true(type(a:input) == v:t_list)
  let Cb = function(a:cb, a:000)
  let WrapCb = {_0, data, _1 -> Cb(data) }
  let id = init#Jobstart(a:cmds, #{stdout_buffered: v:true, on_stdout: WrapCb})

  call chansend(id, a:input)
  call chanclose(id, 'stdin')
  return id
endfunction

function! init#OnJobOutput(cmds, cb, ...)
  call assert_true(type(a:cb) == v:t_string)
  let Cb = function(a:cb, a:000)
  let WrapCb = {_0, data, _1 -> Cb(data) }
  return init#Jobstart(a:cmds, #{stdout_buffered: v:true, on_stdout: WrapCb})
endfunction

function! init#OnJobExit(cmds, cb, ...)
  call assert_true(type(a:cb) == v:t_string)
  let Cb = function(a:cb, a:000)
  if type(a:cmds) == type([])
    let job_name = a:cmds[0]
  else
    let job_name = split(a:cmds)[0]
  endif
  return init#Jobstart(a:cmds, #{on_exit: {_0, code, _2 -> Cb(code)}})
endfunction

function! init#OnJobSuccess(cmds, cb, ...)
  call assert_true(type(a:cb) == v:t_string)
  let Cb = function(a:cb, a:000)
  if type(a:cmds) == type([])
    let job_name = a:cmds[0]
  else
    let job_name = split(a:cmds)[0]
  endif
  return init#Jobstart(a:cmds, #{on_exit: function('s:CheckJobSuccess', [job_name, Cb])})
endfunction

function s:CheckJobSuccess(job_name, Cb, _0, code, _1)
  if a:code == 0
    call a:Cb()
  else
    let msg = printf("Job '%s' failed", a:job_name)
    call init#Warn(msg)
  endif
endfunction

function! init#OnJobFail(cmds, cb, ...)
  call assert_true(type(a:cb) == v:t_string)
  let Cb = function(a:cb, a:000)
  if type(a:cmds) == type([])
    let job_name = a:cmds[0]
  else
    let job_name = split(a:cmds)[0]
  endif
  return init#Jobstart(a:cmds, #{on_exit: {_0, code, _1 -> code != 0 ? Cb()}})
endfunction

function! init#IsVisible(bufname)
  let nr = bufnr(a:bufname)
  for win in range(1, winnr('$'))
    if winbufnr(win) == nr
      return v:true
    endif
  endfor
  return v:false
endfunction

function! init#Unique(list)
  let idx = 0
  let hash_map = #{}
  for item in a:list
    if !has_key(hash_map, item)
      let hash_map[item] = idx
      let idx += 1
    endif
  endfor
  let order = sort(items(hash_map), {a, b -> a[1] - b[1]})
  return map(order, 'v:val[0]')
endfunction

function! init#ShowErrors(errors)
  let errors = map(a:errors, "strtrans(v:val)")
  if empty(errors)
    let errors = ["<No errors to show>"]
  endif

  call init#CustomBottomBuffer('Errors', errors)
endfunction

function init#SystemOrThrow(args)
  let output = systemlist(a:args)
  if v:shell_error
    call init#ShowErrors(output)
    throw "System call failed!"
  endif
  return output
endfunction

function init#TryCall(what, ...)
  let Partial = function(a:what, a:000)
  try
    return Partial()
  catch
    echom v:exception
  endtry
endfunction

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

function! init#Warn(msg, ...)
  let msg = a:msg
  if len(a:000) > 0
    let vargs = insert(copy(a:000), msg, 0)
    let msg = function("printf", vargs)()
  endif
  call nvim_echo([[msg, "WarningMsg"]], v:true, #{})
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

function init#IsWorkspace(str)
  " SSH connections will report the same workspace (how you last left your desktop).
  if !empty($SSH_CONNECTION)
    return v:false
  endif

  let ws = systemlist("qdbus org.kde.KWin /KWin org.kde.KWin.currentDesktop")
  if v:shell_error
    call init#Warn("qdbus command failed!")
    return v:flase
  endif
  return ws[0] == a:str
endfunction

function init#IsMainWorkspace()
  if !empty($SSH_MAIN_CONNECTION)
    return v:true
  endif
  return init#IsWorkspace("2")
endfunction

function! s:ScriptLocalVars()
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

if !exists('s:recent_buffers')
  let s:recent_buffers = #{}
endif

function! s:OnBufferEnter()
  let nr = expand("<abuf>")
  let s:recent_buffers[nr] = localtime()
endfunction

function! init#PrettyTime(secs)
  let secs = a:secs % 60
  let mins = (a:secs / 60) % 60
  let hrs = (a:secs / 60 / 60)
  if hrs > 0
    return printf("%dh %dm %ds", hrs, mins, secs)
  elseif mins > 0
    return printf("%dm %ds", mins, secs)
  else
    return printf("%ds", secs)
  endif
endfunction

function! s:RecentBuffers()
  let buffers = map(keys(s:recent_buffers), 'str2nr(v:val)')
  call filter(buffers, 'bufexists(v:val) && filereadable(bufname(v:val))')
  call sort(buffers, {a, b -> s:recent_buffers[b] - s:recent_buffers[a]})
  call map(buffers, '#{bufnr: v:val, text: init#PrettyTime(localtime() - s:recent_buffers[v:val])}')
  call qutil#SetQuickfix(buffers, 'Recent buffers')
endfunction

command! -nargs=0 Buffers call s:RecentBuffers()
command! -nargs=0 Recent call s:RecentBuffers()

autocmd BufEnter * call s:OnBufferEnter()

" Open vimrc quick (muy importante)
nnoremap <silent> <leader>ev :e ~/.config/nvim/init.vim<CR>
nnoremap <silent> <leader>lv :e ~/.config/nvim/lua/lsp.lua<CR>
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

cabbr Q q
cabbr Qa qa

cabbr Rgrpe Rgrep
cabbr Rgpre Rgrep

" Annoying quirks
set updatecount=0
set shortmess+=I
au FileType * setlocal fo-=cro
nnoremap <C-w>t <C-w>T
nnoremap <silent> zA :set invfoldenable<CR>
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

set notimeout
set foldmethod=manual
set nofoldenable
set shell=/bin/bash
set splitright

" This is causing problems because of slow SSH connections
" I think so? But it is definitely causing problems...
set ttimeout

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
  let mixedStatus = (filename[0:len(cwd)] == (cwd .. "/"))

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
  if exists('g:HOST') && g:HOST != s:default_host
    if !work#GetHostStatus()
      return "(- " .. g:HOST .. ")"
    else
      return "(" .. g:HOST .. ")"
    endif
   else
    if exists("*work#GetHostStatus") && !work#GetHostStatus()
      return "(- " .. g:HOST .. ")"
    else
      return ""
    endif
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
command! -nargs=0 -bar Debug let g:BUILD_TYPE = "Debug" | Clangd
command! -nargs=0 -bar Release let g:BUILD_TYPE = "Release" | Clangd

function! init#GetMakeCommand(...)
  let force = get(a:000, 0, v:false)
  let repo = FugitiveWorkTree()
  if empty(repo)
    echo "Not inside repo"
    return
  endif

  let cmds = []
  call add(cmds, printf("cd %s", FugitiveWorkTree()))

  let build_dir = printf("%s/%s", FugitiveWorkTree(), g:BUILD_TYPE)
  if force || !isdirectory(build_dir)
    let cmake = printf("cmake -B %s -S . -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=%s", g:BUILD_TYPE, g:BUILD_TYPE)
    call add(cmds, cmake)
  endif

  let build = printf("cmake --build %s -j 10", g:BUILD_TYPE)
  call add(cmds, build)

  let command = ["/bin/bash", "-c", join(cmds, ';')]
  return command
endfunction

command! -nargs=0 -bang Make call qutil#Make(init#GetMakeCommand(), "<bang>")
command! -nargs=0 Clean call system("rm -rf " . FugitiveFind(g:BUILD_TYPE))
command! -nargs=0 -bang Remake exe "Clean" | exe "Make<bang>"

nnoremap <silent> <leader>re :Make<CR>

function s:PushCommand(bang)
  if !git#PushCommand(a:bang)
    return
  endif
  if s:is_work_pc
    let issue = work#BranchIssueNumber()
    if !empty(issue) && exists('*work#OpenJira')
      return work#OpenJira(issue)
    endif
  endif
endfunction

command! -nargs=0 -bang Push call s:PushCommand("<bang>")

function! s:ShowHistory(CmdLine)
  let result = init#HistFind(a:CmdLine)
  call qutil#CreateOneShotQuickfix(result, 'History', expand('<SID>') .. 'SelectCommand')
endfunction

function! s:SelectCommand(cmd)
  exe a:cmd
endfunction

command! -nargs=* History call s:ShowHistory(<q-args>)

function! s:GetSessionFile()
  let repo = fnamemodify(FugitiveWorkTree(), ':t')
  let branch = git#GetBranch()
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
  call qutil#CreateOneShotQuickfix(session_files, 'Sessions', '<SID>SelectSession')
endfunction

function! s:SelectSession(file)
  exe "so " .. a:file
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

command! -nargs=0 Errno call init#ToClipboard("https://www.thegeekstuff.com/2010/10/linux-error-codes")

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

function! s:SimplifyTabs()
  while tabpagenr() != tabpagenr('$')
    +tabclose
  endwhile
endfunction

command! Simp call s:SimplifyTabs()

" CursorHold time
set updatetime=500
set completeopt=menuone,noinsert
set pumheight=10

" http://vim.wikia.com/wiki/Automatically_append_closing_characters
inoremap {<CR> {<CR>}<C-o>O

nmap <leader>sp :setlocal invspell<CR>
" }}}

""""""""""""""""""""""""""""Code navigation"""""""""""""""""""""""""""" {{{
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:NextItem(dir)
  if git#DiffWinid() >= 0
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
  if git#DiffWinid() < 0
    let winids = qutil#GetQuickfixWins()
    if !empty(winids)
      call nvim_win_close(winids[0], v:false)
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
  call qsearch#Find(FugitiveWorkTree(), "-iname", glob)
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
  call qsearch#Find(FugitiveWorkTree(), "-iname", glob)
endfunction

nmap <silent> <leader>cp :call <SID>OpenSource()<CR>
nmap <silent> <leader>hp :call <SID>OpenHeader()<CR>

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

command! -nargs=0 Cmake call s:OpenCMakeLists()

function! s:CreateClangd()
  let repo = FugitiveWorkTree()
  if empty(repo)
    echo "Not inside repo!"
    return
  endif
  let file = repo .. "/.clangd"
  let db = repo .. "/" .. g:BUILD_TYPE
  top sp
  exe "e " .. file
  %delete
  call append(0, ['CompileFlags:', '  CompilationDatabase: ' .. db])
  write
  quit
endfunction

command! -nargs=0 -bar Clangd call s:CreateClangd() | LspRestart

function! s:CheckClangd(repo)
  if len(a:repo) <= 0
    return
  endif
  let file = printf("%s/.clangd", a:repo)
  if !filereadable(file)
    return
  endif
  let lines = readfile(file)
  let expected = printf("  CompilationDatabase: %s/%s", a:repo, g:BUILD_TYPE)
  if index(lines, expected) < 0
    call init#Warn("Detected old .clangd!") 
  endif
endfunction

function! s:CheckCMakeCache(repo)
  if empty(a:repo)
    return
  endif
  let file = printf("%s/%s/CMakeCache.txt", a:repo, g:BUILD_TYPE)
  if !filereadable(file)
    return
  endif
  let lines = readfile(file)
  call filter(lines, 'stridx(v:val, g:SDK_DIR) >= 0')
  if empty(lines)
    call init#Warn('Detected old CMake build directory!')
  endif
endfunction

function! s:CheckProjectFiles()
  if !exists('s:checked_repos')
    let s:checked_repos = #{}
  endif
  let repo = FugitiveWorkTree()
  if !has_key(s:checked_repos, repo)
    call s:CheckClangd(repo)
    call s:CheckCMakeCache(repo)
    let s:checked_repos[repo] = 1
  endif
endfunction

" TODO this needs to be improved/fixed
" autocmd BufReadPost * call s:CheckProjectFiles()

function! s:OpenCompileCommands()
  let repo = FugitiveWorkTree()
  let curr_file = expand("%:p")
  let json_file = printf("%s/%s/compile_commands.json", repo, g:BUILD_TYPE)
  if !filereadable(json_file)
    echo "Does not exist!"
    return
  endif
  let json = json_decode(readfile(json_file))
  for entry in json
    if !has_key(entry, 'file') || !has_key(entry, 'command')
      continue
    endif
    let entry_file = fnamemodify(entry['file'], ':p')
    if entry_file == curr_file
      let flags = split(entry['command'])
      return init#CustomBottomBuffer('Flags', flags)
    endif
  endfor
  let relative_file = fnamemodify(json_file, ":.")
  echom printf("File not found in %s!", relative_file)
  exe "edit " .. relative_file
  return bufnr()
endfunction

command! -nargs=0 CompileCommands call s:OpenCompileCommands()

function! s:OpenCMakeCache()
  let repo = FugitiveWorkTree()
  let cache_file = printf("%s/%s/CMakeCache.txt", repo, g:BUILD_TYPE)
  if !filereadable(cache_file)
    return
  endif
  exe "e " .. cache_file
endfunction

command! -nargs=0 Cache call s:OpenCMakeCache()

function! s:FoldMotion()
  normal V[z]z
endfunction

onoremap az <cmd>call <SID>FoldMotion()<CR>
onoremap <silent> ab :<C-u>normal! [{V]}]<CR>
xnoremap <silent> ab :<C-u>normal! [{V]}]<CR>
onoremap <silent> ib :<C-u>normal! [{V]}]<CR>
xnoremap <silent> ib :<C-u>normal! [{V]}]<CR>

function s:OpenStackTrace()
  let repo = FugitiveWorkTree()
  if empty(repo)
    echo "Not inside repo!"
    return
  endif
  let old_map = #{}
  let files = s:GetSource(repo) + s:GetHeader(repo)
  for file in files
    let old_map[fnamemodify(file, ':t')] = file
  endfor

  let res = []
  let lines = split(@+, '\n')
  for line in lines
    let m = matchlist(line, 'at \([^:]\+\):\([0-9]\+\)$')
    if len(m) < 3
      call add(res, #{text: line, valid: 0})
    else
      let file = m[1]
      let lnum = m[2]
      if has_key(old_map, file)
        call add(res, #{filename: old_map[file], lnum: lnum, text: line})
      else
        call add(res, #{text: line, valid: 0})
      endif
    endif
  endfor
  call qutil#SetQuickfix(reverse(res), "Stack")
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
  let dir = printf("%s/%s", FugitiveWorkTree(), g:BUILD_TYPE)
  if !isdirectory(dir)
    return []
  endif
  let pat = "*" . a:ArgLead . "*"
  let cmd = ["find", dir, "(", "-path", "**/CMakeFiles", "-prune", "-false", "-o", "-name", pat, ")"]
  let cmd += ["-type", "f", "-executable"]
  let exes = systemlist(cmd)
  return map(exes, 'fnamemodify(v:val, ":.")')
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
" Other arguments:
" - wait: Don't start/run the inferior.
" - post_cmds. List of commands to execute after starting inferior.
" - ssh. Launch GDB over ssh with the given address.
" - br. Place a breakpoint at location and run inferior instead.
function! init#Debug(args)
  let required = ['exe', 'proc']
  let optional = ['wait', 'post_cmds', 'ssh', 'user', 'br']
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
    echo 'Terminal debugger already running, cannot run two'
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
  command! -nargs=0 Quickbreak call s:QuickfixToBreakpoints()
  command! -nargs=* -bang Mark call s:MarkInstruction("<bang>", <q-args>)

  nnoremap <silent> <leader>v <cmd>call PromptDebugEvaluate(expand('<cword>'))<CR>
  vnoremap <silent> <leader>v :<C-u>call PromptDebugEvaluate(init#GetRangeExpr())<CR>

  nnoremap <silent> <leader>br :call PromptDebugPlaceBreakpoint(#{pending: 1})<CR>
  nnoremap <silent> <leader>tbr :call PromptDebugPlaceBreakpoint(#{pending: 1, temp: 1})<CR>
  nnoremap <silent> <leader>pbr :call PromptDebugPlaceBreakpoint(#{pending: 1, thread: 1})<CR>
  nnoremap <silent> <leader>unt :call PromptDebugPlaceBreakpoint(#{pending: 1, until: 1})<CR>
  nnoremap <silent> <leader>pc :call PromptDebugGoToPC()<CR>

  " call PromptDebugEnableTimings()
  call PromptDebugSendCommand("set disable-randomization on")
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

  " Custom pretty printers
  call PromptDebugPrettyPrinter(['std::filesystem'], "PrettyPrinterFilesystem")
  call PromptDebugPrettyPrinter(['v4l2::Format'], "PrettyPrinterFormat")

  if has_key(a:args, "proc")
    call PromptDebugSendCommand("attach " . a:args["proc"])
    if has_key(a:args, "br")
      call PromptDebugSendCommand("tbr " . a:args['br'])
      call PromptDebugSendCommand("c")
    endif
  elseif has_key(a:args, "exe")
    let cmdArgs = split(a:args["exe"], " ")
    call PromptDebugSendCommand("file " . cmdArgs[0])
    if len(cmdArgs) > 1
      call PromptDebugSendCommand("set args " . join(cmdArgs[1:], " "))
    endif
    if has_key(a:args, "br")
      call PromptDebugSendCommand("tbr " . a:args['br'])
    endif
    if !has_key(a:args, "wait")
      if has_key(a:args, "br")
        call PromptDebugSendCommand("r")
      else
        call PromptDebugSendCommand("start")
      endif
    endif
  endif
  if has_key(a:args, 'post_cmds')
    for cmd in a:args['post_cmds']
      call PromptDebugSendCommand(cmd)
     endfor
  endif
endfunction

function! s:DebugRunPost()
  call PromptDebugSendCommand("set scheduler-locking step")
  if !s:is_work_pc
    call PromptDebugSendCommand("set disassembly-flavor intel")
  endif
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

function! s:QuickfixToBreakpoints()
  let str_mapper = '"br " .. fnamemodify(bufname(v:val.bufnr), ":t") .. ":" .. v:val.lnum'
  let cmd_list = map(getqflist(), str_mapper)
  for cmd in cmd_list
    call PromptDebugSendCommand(cmd)
  endfor
endfunction

function! s:MarkInstruction(bang, arg)
  if !empty(a:bang)
    call PromptDebugClearMarks()
  else
    call PromptDebugMarkInstruction(a:arg)
  endif
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

""""""""""""""""""""""""""""Disas"""""""""""""""""""""""""" {{{
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:objdump_exe = "objdump"

function! init#Disassemble(arg)
  call init#OnJobOutput(printf("nm --defined-only %s", a:arg), 's:OnSymbols', a:arg)
endfunction

function! s:OnSymbols(exe, funcs)
  let funcs = filter(a:funcs, '!empty(v:val)')
  let funcs = map(funcs, 'split(v:val)')
  call filter(funcs, 'toupper(v:val[1]) == "W" || toupper(v:val[1]) == "T"')
  call map(funcs, 'v:val[2]')
  if empty(funcs)
    echo "No symbols!"
    return
  endif

  " Note: Fast enough to call without using jobs
  let unmangled = systemlist("c++filt", funcs)
  call map(unmangled, 'v:val[:180]')
  let nr = qutil#CreateCustomQuickfix(unmangled, 'Symbols', 'init#SelectSymbol', a:exe)
  if nr >= 0
    " Much faster than binding it in above 'function'.
    let b:mangled_names = funcs
    call setbufvar(nr, '&modifiable', v:false)
    command! -buffer -nargs=1 -bang Cf call s:FilterSymbols("<bang>", <q-args>)
    command! -buffer -nargs=1 -bang Cff call s:FilterSymbols("<bang>", <q-args>)
  endif
endfunction

function! s:FilterSymbols(bang, arg)
  setlocal modifiable
  if empty(a:bang)
    let cmp = ' >= 0'
  else
    let cmp = ' < 0'
  endif
  let lines = getline(1, '$')
  call filter(b:mangled_names, 'stridx(lines[v:key], a:arg)' .. cmp)
  call filter(lines, 'stridx(v:val, a:arg)' .. cmp)
  call assert_true(len(lines) == len(b:mangled_names))
  call nvim_buf_set_lines(bufnr(), 0, -1, v:false, lines)
  setlocal nomodifiable
endfunction

function! init#SelectSymbol(exe)
  let idx = line('.') - 1
  let mangled = b:mangled_names[idx]
  echom "Showing symbol " .. mangled

  let cmd = printf('%s -M intel -Sl --disassemble=%s %s', g:objdump_exe, mangled, a:exe)
  call init#OnJobOutput(cmd, 's:OnDisassemble')
endfunction

function! s:OnDisassemble(disas)
  call init#OnJobProcess("c++filt", a:disas, 's:OnReadableDisassemble')
endfunction

function! s:OnReadableDisassemble(disas)
  " Create buffer
  let disas_nr = bufadd('Disassembly')
  call setbufvar(disas_nr, '&buftype', 'nofile')
  call setbufvar(disas_nr, '&bufhidden', 'wipe')
  call bufload(disas_nr)

  " Copy basic syntax highlight (from vim filetype)
  let file_line_map = #{}
  let curr_lines = []
  let disas = a:disas
  for i in range(len(disas))
    let m = matchlist(disas[i], '^\(/.*\):\([0-9]\+\)')
    if !empty(m)
      let curr_file = m[1]
      " Needed in order to get syntax (init#CopySyntax)
      exe "e " .. curr_file
      let curr_lines = getline(1, '$')
      let curr_pos = 0
    else
      let m = matchlist(disas[i], '^\s*\x\+:')
      if !empty(m)
        call init#AppendChunksAtEnd(disas_nr, [[disas[i], '@comment']])
      elseif !empty(curr_lines)
        let idx = index(curr_lines[curr_pos:], disas[i])
        if idx >= 0
          let curr_pos += idx + 1
          call init#CopySyntax(curr_pos, disas_nr)
          if !has_key(file_line_map, curr_file)
            let file_line_map[curr_file] = #{}
          endif
          let line_map = file_line_map[curr_file]
          if !has_key(line_map, curr_pos - 1)
            let line_map[curr_pos - 1] = []
          endif
          call add(line_map[curr_pos - 1], nvim_buf_line_count(disas_nr) - 1)
        else
          let curr_lines = []
        endif
      endif
    endif
  endfor

  call setbufvar(disas_nr, '&expandtab', v:false)
  call setbufvar(disas_nr, '&smarttab', v:false)
  call setbufvar(disas_nr, '&softtabstop', 0)
  call setbufvar(disas_nr, '&tabstop', 8)
  call setbufvar(disas_nr, 'file_line_map', file_line_map)

  " Copy main syntax highlight (from lsp)
  for filename in keys(file_line_map)
    " Needed by LSP to process file
    exe "e " .. filename
    let nr = bufnr()
    exe printf("lua GetSemanticTokens(%d, 'init#TransferExtmarks', {%d, %d})", nr, disas_nr, nr)
  endfor

  quit
  exe "b " .. disas_nr
  call setbufvar(disas_nr, '&list', v:false)
endfunction

function init#TransferExtmarks(dst_nr, src_nr, in_lnum, in_col, in_opt)
  let ns = nvim_create_namespace('semantic_tokens')
  let file_line_map = getbufvar(a:dst_nr, 'file_line_map')
  let src_pathname = fnamemodify(bufname(a:src_nr), ':p')
  let line_map = file_line_map[src_pathname]
  if has_key(line_map, a:in_lnum)
    let dst_lnums = line_map[a:in_lnum]
    for dst_lnum in dst_lnums
      call nvim_buf_set_extmark(a:dst_nr, ns, dst_lnum, a:in_col, a:in_opt)
    endfor
  endif
endfunction

function! s:GetDisassembleTargets()
  let dir = FugitiveWorkTree()
  if !isdirectory(dir)
    return []
  endif
  let dir = printf("%s/%s", dir, g:BUILD_TYPE)
  return systemlist(["find", dir, "-type", "f", "-executable"])
endfunction

command! -nargs=? -complete=customlist,DisassembleCompl Disassemble
      \ call s:GetDisassembleTargets()->qutil#CommandPass(<q-args>)->qutil#CreateOneShotQuickfix('Disassemble', 'init#Disassemble')

function! DisassembleCompl(ArgLead, CmdLine, CursorPos)
  if a:CursorPos < len(a:CmdLine)
    return []
  endif
  return s:GetDisassembleTargets()->qutil#FileCompletionPass(a:ArgLead)
endfunction
"}}}

""""""""""""""""""""""""""""LSP"""""""""""""""""""""""""""" {{{
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:TruncateLspLog()
  let logs = [$NVIM_LOG_FILE, luaeval("vim.lsp.get_log_path()")]
  for log in logs
    if filereadable(log)
      let size = getfsize(log)
      if size > 64 * 1024
        call writefile([], log)
      endif
    endif
  endfor
  if exists('$NVIM_LOG_FILE') && filereadable($NVIM_LOG_FILE)
    call delete($NVIM_LOG_FILE)
  endif
endfunction

autocmd VimEnter * call s:TruncateLspLog()

command! -nargs=0 LspStop lua vim.lsp.stop_client(vim.lsp.get_active_clients())
command! -nargs=0 LspProg lua print(vim.inspect(vim.lsp.status()))

command! -nargs=0 -range For lua vim.lsp.buf.format{ range = {start= {<line1>, 0}, ["end"] = {<line2>, 0}} }
nnoremap <expr> <leader>for init#Operator("For", 1)
vnoremap <silent> <leader>for :For<CR>

function! init#Operator(cmd, pending)
  let &operatorfunc = function('s:OperatorImpl', [a:cmd])
  if a:pending
    return 'g@'
  else
    return 'g@_'
  endif
endfunction

function! s:OperatorImpl(cmd, type)
  if a:type != "line"
    return
  endif
  let firstline = line("'[")
  let lastline = line("']")
  exe printf("%d,%d%s", firstline, lastline, a:cmd)
endfunction

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

command! -nargs=+ Grepo call qsearch#Grep(<q-args>, FugitiveWorkTree())

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
  return qsearch#GetFiles(dir, "-regex", regex)
endfunction

function! SourceCompl(ArgLead, CmdLine, CursorPos)
  if a:CursorPos < len(a:CmdLine)
    return []
  endif
  return s:GetSource()->qutil#FileCompletionPass(a:ArgLead)
endfunction

command! -nargs=? -complete=customlist,SourceCompl Source call s:GetSource()->qutil#CommandPass(<q-args>)->qutil#DropInQuickfix('Source')

command! -nargs=? -complete=customlist,SourceCompl S exe "Source " .. <q-args>

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
  return qsearch#GetFiles(dir, "-regex", regex)
endfunction

function! HeaderCompl(ArgLead, CmdLine, CursorPos)
  if a:CursorPos < len(a:CmdLine)
    return []
  endif
  return s:GetHeader()->qutil#FileCompletionPass(a:ArgLead)
endfunction

command! -nargs=? -complete=customlist,HeaderCompl Header call s:GetHeader()->qutil#CommandPass(<q-args>)->qutil#DropInQuickfix('Header')

command! -nargs=? -complete=customlist,HeaderCompl H exe "Header " .. <q-args>

function! s:GetWorkFiles()
  let dir = FugitiveWorkTree()
  if !isdirectory(dir)
    return []
  endif
  return qsearch#GetFiles(dir)
endfunction

function! WorkFilesCompl(ArgLead, CmdLine, CursorPos)
  if a:CursorPos < len(a:CmdLine)
    return []
  endif
  return s:GetWorkFiles()->qutil#ComponentCompletionPass(a:ArgLead)
endfunction

command! -nargs=? -complete=customlist,WorkFilesCompl Workfiles call s:GetWorkFiles()->qutil#CommandPass(<q-args>)->qutil#DropInQuickfix('Workfiles')

function! init#OnFindData(data)
  call qutil#DropInQuickfix(a:data, 'Find')
endfunction

" command! -nargs=? Find call )->qutil#CommandPass(<q-args>)->qutil#DropInQuickfix('Find')
command! -nargs=? Find call qsearch#OnFiles(getcwd(), ["-name", "*" . <q-args> . "*"], 'init#OnFindData')

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
    call qutil#DropInQuickfix(items, "Hierarchy")
  endif
endfunction

function! ReferenceContainerHandler(res)
  let items = map(a:res, "#{
        \ filename: v:lua.vim.uri_to_fname(v:val.uri),
        \ lnum: v:val.range.start.line + 1,
        \ col: v:val.range.start.character + 1,
        \ text: v:val.containerName}")
  call sort(items, {a, b -> a.lnum - b.lnum})
  call qutil#SetQuickfix(items, "References")
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
    call qutil#SetQuickfix(items, "Instances")
  endif
endfunction

command! -nargs=0 Instances call <SID>Instances()

if !exists('s:lsp_files_to_index')
  let s:lsp_files_to_index = #{}
endif

function! s:Index(dir)
  let not_indexed = keys(filter(copy(s:lsp_files_to_index), 'v:val == 1'))
  if !empty(not_indexed)
    echo "Clearing index!"
    let g:statusline_dict['lsp'] = ''
    let s:lsp_files_to_index = #{}
    return
  endif

  let files = s:GetSource(a:dir) + s:GetHeader(a:dir)
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

function! s:EditRecentSource()
  if &ft == 'c' || &ft == 'cpp'
    return
  endif

  let repo = FugitiveWorkTree()
  if empty(repo)
    return
  endif

  let sources = s:GetSource(repo)
  if !empty(sources)
    exe "edit " .. sources[0]
  endif
endfunction

function! s:SmartWorkspaceSymbol()
  call s:EditRecentSource()
  lua vim.lsp.buf.workspace_symbol()
endfunction

nnoremap <silent> gS <cmd>call <SID>SmartWorkspaceSymbol()<CR>
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

function! init#RemoteAttach(host, proc, ...)
  if a:proc =~ '^[0-9]\+$'
    let pid = a:proc
  else
    let pid = init#RemotePid(a:host, a:proc)
  endif
  if pid > 0
    let opts = #{ssh: a:host, proc: pid}
    if a:0 > 0 && a:1
      let opts['br'] = init#GetDebugLoc()
    endif
    call init#Debug(opts)
  endif
endfunction

function! init#SshTerm(remote)
  tabnew
  startinsert
  let id = termopen(["ssh", a:remote])
endfunction

function! init#Sshfs(remote, args)
  silent exe "drop scp://" . a:remote . "/" . a:args
endfunction

function! init#Scp(remote, bang, path)
  if empty(a:bang)
    let cmd = printf("rsync -pt %s %s:%s", expand("%:p"), a:remote, a:path)
  else
    let cmd = printf("rsync -pt %s:%s %s/Downloads", a:remote, a:path, $HOME)
  endif

  let ret = systemlist(cmd)
  if v:shell_error
    call init#ShowErrors(ret)
  elseif empty(a:bang)
    echo "Copied to " .. a:path .. "."
  else
    echo "Downloaded " .. a:path .. "."
  endif
endfunction

function! init#RemoteFindFiles(remote, p)
  let regex = '.*' .. a:p .. '.*'
  let file_args = printf('-type f -regex "%s"', regex)
  let cmd = printf('find / -path /proc -prune -type f -o -path /sys -prune -type f -o \( %s \)', file_args)
  let files = systemlist(["ssh", a:remote, cmd])
  return v:shell_error ? [] : files
endfunction

function! init#RemoteRecentFiles(remote, ...)
  let cmin = get(a:, 1, 5)
  let file_args = printf('-type f -cmin -%d', cmin)
  let cmd = printf('find / -path /proc -prune -type f -o -path /sys -prune -type f -o \( %s \)', file_args)
  let files = systemlist(["ssh", a:remote, cmd])
  return v:shell_error ? [] : files
endfunction
"}}}

" Go back to default autocommand group
augroup END
