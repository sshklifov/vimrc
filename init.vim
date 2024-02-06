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
Plug 'jackguo380/vim-lsp-cxx-highlight'
Plug 'sshklifov/debug'

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
nnoremap <silent> <Space> :nohlsearch <bar> LspCxxHighlight<cr>

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

""""""""""""""""""""""""""""Quickfix"""""""""""""""""""""""""""" {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:OpenQfResults()
  let len = getqflist({"size": 1})['size']
  if len == 0
    echo "No results"
  elseif len == 1
    cc
  else
    copen
  endif
endfunction

let g:exclude_dirs = ["ccls-cache", ".git", "Debug", "Release"]
let g:exclude_files = ["compile_commands.json", ".ccls"]

function! s:ExcludeFile(file)
  for dir in g:exclude_dirs
    if stridx(a:file, dir) >= 0
      return v:true
    endif
  endfor
  for file in g:exclude_files
    if a:file[-len(file):-1] == file
      return v:true
    endif
  endfor
  return v:false
endfunction

function! s:OldFiles(read_shada)
  if a:read_shada
    rsh!
  endif

  let items = deepcopy(v:oldfiles)
  let items = map(items, {_, f -> {"filename": f, "lnum": 1, 'text': fnamemodify(f, ":t")}})
  call setqflist([], ' ', {'title': 'Oldfiles', 'items': items})
  call s:OpenQfResults()
endfunction

command -nargs=0 -bang Old call s:OldFiles(<bang>0)

function! s:Grep(regex, where)
  call setqflist([], ' ', {'title' : 'Grep', 'items' : []})

  function! OnEvent(id, data, event)
    function! GetGrepItem(index, match)
      let sp = split(a:match, ":")
      if len(sp) < 3
        return {}
      endif
      if !filereadable(sp[0]) || s:ExcludeFile(sp[0])
        return {}
      endif
      if sp[1] !~ '^[0-9]\+$'
        return {}
      endif
      return {"filename": sp[0], "lnum": sp[1], 'text': join(sp[2:-1], ":")}
    endfunction
    let items = filter(map(a:data, function("GetGrepItem")), "!empty(v:val)")
    call setqflist([], 'a', {'items' : items})
  endfunction

  let cmd = ['grep']
  " Apply 'smartcase' to the regex
  if a:regex !~# "[A-Z]"
    let cmd = cmd + ['-i']
  endif
  let cmd = cmd + ['-I', '-H', '-n', a:regex]

  if type(a:where) == v:t_list
    let cmd = ['xargs'] + cmd
    let id = jobstart(cmd, {'on_stdout': function('OnEvent') } )
    call chansend(id, a:where)
  else
    let cmd = cmd + ['-R', a:where]
    let id = jobstart(cmd, {'on_stdout': function('OnEvent') } )
  endif

  call chanclose(id, 'stdin')
  call jobwait([id]) " Need to know length of items
  call s:OpenQfResults()
endfunction

function! s:GrepQuickfixFiles(regex)
  let files = map(getqflist(), 'expand("#" . v:val["bufnr"] . ":p")')
  let files = uniq(sort(files))
  call s:Grep(a:regex, files)
endfunction

" Current buffer
command! -nargs=1 Bgrep call <SID>Grep(<q-args>, [expand("%:p")])
" All files in quickfix
command! -nargs=1 Cgrep call <SID>GrepQuickfixFiles(<q-args>)
" Current path
command! -nargs=1 Rgrep call <SID>Grep(<q-args>, getcwd())

function! s:DeleteQfEntries(a, b)
  let qflist = filter(getqflist(), {i, _ -> i+1 < a:a || i+1 > a:b})
  call setqflist([], ' ', {'title': 'Cdelete', 'items': qflist})
endfunction

autocmd FileType qf command! -buffer -range Cdelete call <SID>DeleteQfEntries(<line1>, <line2>)

function! s:OpenJumpList()
  let jl = deepcopy(getjumplist())
  let entries = jl[0]
  let idx = jl[1]

  for i in range(len(entries))
    if !bufloaded(entries[i]['bufnr'])
      let entries[i] = #{text: "Not loaded"}
    else
      let lines = getbufline(entries[i]['bufnr'], entries[i]['lnum'])
      if len(lines) > 0
        let entries[i]['text'] = lines[0]
      endif
    endif
  endfor

  call setqflist([], 'r', {'title': 'Jump', 'items': entries})
  " Open quickfix at the relevant position
  if idx < len(entries)
    exe "keepjumps crewind " . (idx + 1)
  endif
  " Keep the same window focused
  let nr = winnr()
  keepjumps copen
  exec "keepjumps " . nr . "wincmd w"
endfunction

function! s:Jump(scope)
  if s:IsBufferQf()
    if a:scope == "i"
      try
        silent cnew
      catch
        echo "Hit newest list"
      endtry
    elseif a:scope == "o"
      try
        silent cold
      catch
        echo "Hit oldest list"
      endtry
    endif
    return
  endif

  " Pass 1 to normal so vim doesn't interpret ^i as a TAB (they use the same keycode of 9)
  if a:scope == "i"
    exe "normal! 1" . "\<c-i>"
  elseif a:scope == "o"
    exe "normal! 1" . "\<c-o>"
  endif

  " Refresh jump list
  if s:IsQfOpen()
    let title = getqflist({'title': 1})['title']
    if title == "Jump"
      call s:OpenJumpList()
    endif
  endif
endfunction

nnoremap <silent> <leader>ju :call <SID>OpenJumpList()<CR>
nnoremap <silent> <c-i> :call <SID>Jump("i")<CR>
nnoremap <silent> <c-o> :call <SID>Jump("o")<CR>

function! s:ShowBuffers(pat)
  let pat = ".*" . a:pat . ".*"
  if a:pat !~# "[A-Z]"
    let pat = '\c' . pat
  else
    let pat = '\C' . pat
  endif

  function! s:GetBufferItem(_, n) closure
    let name = expand('#' . a:n . ':p')
    if !filereadable(name) || match(name, pat) < 0
      return {}
    endif

    let bufinfo = getbufinfo(a:n)[0]
    let text = "" . a:n
    if bufinfo["changed"]
      let text = text . " (modified)"
    endif
    return {"bufnr": a:n, "text": text, "lnum": bufinfo["lnum"]}
  endfunction

  let items = map(range(1, bufnr('$')), function("s:GetBufferItem"))
  let items = filter(items, "!empty(v:val)")
  call setqflist([], 'r', {'title' : 'Buffers', 'items' : items})
  call s:OpenQfResults()
endfunction

nnoremap <silent> <leader>buf :call <SID>ShowBuffers("")<CR>

function! BufferCompl(ArgLead, CmdLine, CursorPos)
  if a:CursorPos < len(a:CmdLine)
    return []
  endif

  let pat = ".*" . a:ArgLead . ".*"
  if pat !~# "[A-Z]"
    let pat = '\c' . pat
  else
    let pat = '\C' . pat
  endif

  let names = map(range(1, bufnr('$')), "bufname(v:val)")
  let names = filter(names, "filereadable(v:val)")
  let compl = []
  for name in names
    let parts = split(name, "/")
    for part in parts
      if match(part, pat) >= 0
        call add(compl, part)
      endif
    endfor
  endfor
  return uniq(sort(compl))
endfunction

command! -nargs=? -complete=customlist,BufferCompl Buffer call <SID>ShowBuffers(<q-args>)

function! s:IsBufferQf()
  let tabnr = tabpagenr()
  let bufnr = bufnr()
  let wins = filter(getwininfo(), {_, w -> w['tabnr'] == tabnr && w['quickfix'] == 1 && w['bufnr'] == bufnr})
  return !empty(wins)
endfunction

function! s:IsQfOpen()
  let tabnr = tabpagenr()
  let wins = filter(getwininfo(), {_, w -> w['tabnr'] == tabnr && w['quickfix'] == 1 && w['loclist'] == 0})
  return !empty(wins)
endfunction

function! s:ToggleQf()
  if s:IsQfOpen()
    cclose
  else
    copen
  endif
endfunction

nnoremap <silent> <leader>cc :call <SID>ToggleQf()<CR>
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

  "Default to using FindInWorkspace
  let nobang = ""
  call s:FindInWorkspace(nobang, expand("%:t:r") . ".c")
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

  "Default to using FindInWorkspace
  let nobang = ""
  call s:FindInWorkspace(nobang, expand("%:t:r") . ".h")
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

function! s:Find(bang, dir, arglist, Cb)
  if empty(a:dir)
    return
  endif

  " Add exclude paths flags
  let flags = []
  " Bang means to force more results and not take into accound exclude paths.
  if a:bang != "!"
    for dir in g:exclude_dirs
      let flags = flags + ["-path", "**/" . dir, "-prune", "-false", "-o"]
    endfor
    for file in g:exclude_files
      let flags = flags + ["-not", "-name", file]
    endfor
  endif

  " Exclude directorties from results
  let flags = flags + ["-type", "f"]
  " Add user flags
  let flags = flags + a:arglist
  " Add actions (ignore binary files)
  let flags = flags + [
        \ "-exec", "grep", "-Iq", ".", "{}", ";",
        \ "-print"
        \ ]

  let cmd = ["find",  fnamemodify(a:dir, ':p')] + flags
  let id = jobstart(cmd, {'on_stdout': a:Cb})
  call chanclose(id, 'stdin')
  return id
endfunction

function! s:FindInQuickfix(bang, dir, pat, ...)
  function! PopulateQuickfix(id, data, event)
    let files = filter(a:data, "filereadable(v:val)")
    let items = map(files, {_, f -> {'filename': f, 'lnum': 1, 'col': 1, 'text': fnamemodify(f, ':t')} })
    call setqflist([], 'a', {'items' : items})
  endfunction

  let flags = []
  if !empty(a:pat)
    let regex = ".*" . a:pat . ".*"
    " Apply 'smartcase' to the regex
    if regex =~# "[A-Z]"
      let flags = ["-regex", regex]
    else
      let flags = ["-iregex", regex]
    endif
  endif
  " Add user args
  let flags += get(a:, 1, [])

  " Perform find operation
  call setqflist([], ' ', {'title' : 'Find', 'items' : []})
  let id = s:Find(a:bang, a:dir, flags, function("PopulateQuickfix"))

  call jobwait([id]) " Need to know length of items
  call s:OpenQfResults()
endfunction

function! s:GetWorkspace()
  return FugitiveWorkTree()
endfunction

function! s:FindInWorkspace(bang, pat)
  let ws = s:GetWorkspace()
  if empty(ws)
    echo "Not in workspace"
    return
  endif
  call s:FindInQuickfix(a:bang, ws, a:pat)
endfunction

command! -nargs=0 -bang List call <SID>FindInQuickfix("<bang>", getcwd(), "", ['-maxdepth', 1])
command! -nargs=1 -bang -complete=dir Find call <SID>FindInQuickfix("<bang>", <q-args>, "")
command! -nargs=? -bang Workspace call <SID>FindInWorkspace("<bang>", <q-args>)

function! s:Index(arg)
  let ws = s:GetWorkspace()
  if ws == ""
    echo "Not in workspace"
    return
  endif
  let cache = luaeval("GetCachePath()")
  let hierarchy = s:Join(cache, ws[1:])
  if !isdirectory(hierarchy)
    echo "No cache found"
    return
  endif

  let pat = ".*" . a:arg . ".*blob"
  " Apply 'smartcase' to the regex
  if pat =~# "[A-Z]"
    let regex = "-regex"
  else
    let regex = "-iregex"
  endif

  let res = system(["find", hierarchy, "-type", "f", regex, pat, "-printf", "%P\n"])
  let res = split(res, nr2char(10))
  let res = map(res, {_, v -> s:Join(ws, v[0:-6])})
  let items = map(res, "#{filename: v:val, lnum: 1, text: fnamemodify(v:val, ':t')}")
  call setqflist([], ' ', #{title: "Index", items: items})
  call s:OpenQfResults()
endfunction

command! -nargs=? Index call <SID>Index(<q-args>)

function! s:ShowWorkspaces(bang)
  if !empty(a:bang)
    let names = deepcopy(v:oldfiles)
  else
    let names = map(range(1, bufnr('$')), "bufname(v:val)")
    let names = filter(names, "filereadable(v:val)")
  endif
  let git = filter(map(names, "FugitiveExtractGitDir(v:val)"), "!empty(v:val)")
  let git = uniq(sort(git))
  let repos = map(git, "fnamemodify(v:val, ':h')")
  let items = map(repos, {_, f -> {"filename": f, "lnum": 1, 'text': fnamemodify(f, ":t")}})
  call setqflist([], ' ', {'title': 'Git', 'items': items})
  call s:OpenQfResults()
endfunction

command! -nargs=0 -bang Repos call <SID>ShowWorkspaces('<bang>')
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

" Available modes:
" - exe. Pass executable + arguments
" - pname. Process name to attach. Will be resolved to a pid.
" Other arguments:
" - symbols. Whether to load symbols or not. Used for faster loading of gdb.
" - ssh. Launch GDB over ssh with the given address.
" - br. Works only with exe mode. Will run process and place a breakpoint.
function! s:Debug(args)
  if TermDebugIsOpen()
    echoerr 'Terminal debugger already running, cannot run two'
    return
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
  
  if has_key(a:args, "pname")
    let pname = a:args["pname"]
    let pid = s:GetProcessID(pname, get(a:args, 'ssh', ''))
    if pid >= 0
      call TermDebugSendCommand("attach " . pid)
    endif
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
lua vim.highlight.priorities.user = 9999

" Class highlight
highlight LspCxxHlGroupMemberVariable guifg=LightGray
highlight! link LspCxxHlGroupNamespace LspCxxHlSymClass

lua require('lsp')

autocmd User LspProgressUpdate redrawstatus
autocmd User LspRequest redrawstatus
"}}}
