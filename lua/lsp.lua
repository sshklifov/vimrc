-- vim: set sw=2 ts=2 sts=2 foldmethod=marker:

local lspconfig = require('lspconfig')
local api = vim.api
local uv = vim.uv
local util = require('vim.lsp.util')

-- Retrieve lsp highlight
-- XXX: Copied from semantic_tokens.lua in runtime, so it's not the most stable code
local function modifiers_from_number(x, modifiers_table)
  local modifiers = {} ---@type table<string,boolean>
  local idx = 1
  while x > 0 do
    if bit.band(x, 1) == 1 then
      modifiers[modifiers_table[idx]] = true
    end
    x = bit.rshift(x, 1)
    idx = idx + 1
  end
  return modifiers
end

local function tokens_to_ranges(data, bufnr, client)
  local legend = client.server_capabilities.semanticTokensProvider.legend
  local token_types = legend.tokenTypes
  local token_modifiers = legend.tokenModifiers
  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local ranges = {} ---@type STTokenRange[]

  local line ---@type integer?
  local start_char = 0
  for i = 1, #data, 5 do
    local delta_line = data[i]
    line = line and line + delta_line or delta_line
    local delta_start = data[i + 1]
    start_char = delta_line == 0 and start_char + delta_start or delta_start

    -- data[i+3] +1 because Lua tables are 1-indexed
    local token_type = token_types[data[i + 3] + 1]
    local modifiers = modifiers_from_number(data[i + 4], token_modifiers)

    local function _get_byte_pos(col)
      if col > 0 then
        local buf_line = lines[line + 1] or ''
        local ok, result
        ok, result = pcall(util._str_byteindex_enc, buf_line, col, client.offset_encoding)
        if ok then
          return result
        end
        return math.min(#buf_line, col)
      end
      return col
    end

    local start_col = _get_byte_pos(start_char)
    local end_col = _get_byte_pos(start_char + data[i + 2])

    if token_type then
      ranges[#ranges + 1] = {
        line = line,
        start_col = start_col,
        end_col = end_col,
        type = token_type,
        modifiers = modifiers,
        marked = false,
      }
    end
  end

  return ranges
end

local function parse_highlights(highlights, ft)
  local line_marks = {}
  local set_mark = function(token, hl_group, delta)
    local opts = {
      hl_group = hl_group,
      end_col = token.end_col,
      priority = vim.highlight.priorities.semantic_tokens + delta,
      strict = false
    }
    table.insert(line_marks, {token.line, token.start_col, opts})
  end
  for i = 1, #highlights do
    local token = highlights[i]
    if not token.marked then
      set_mark(token, string.format('@lsp.type.%s.%s', token.type, ft), 0)
      for modifier, _ in pairs(token.modifiers) do
        set_mark(token, string.format('@lsp.mod.%s.%s', modifier, ft), 1)
        set_mark(token, string.format('@lsp.typemod.%s.%s.%s', token.type, modifier, ft), 2)
      end
      token.marked = true
    end
  end
  return line_marks
end

-- Make sure there is a client
local function on_attached(bufnr, callback)
  if vim.tbl_isempty(vim.lsp.get_clients({ bufnr = bufnr })) then
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = callback,
      pattern = vim.api.nvim_buf_get_name(bufnr),
      once = true
    })
  else
    callback()
  end
end

function GetSemanticTokens(bufnr, callback, args)
  on_attached(bufnr, function()
    args = args or {}
    local num_args = #args

    local params = {textDocument = vim.lsp.util.make_text_document_params(bufnr)}
    vim.lsp.buf_request(bufnr, "textDocument/semanticTokens/full", params, function(err, result, ctx, _)
      if err or not result or not result.data then
        local bufname = vim.api.nvim_buf_get_name(bufnr)
        vim.api.nvim_err_writeln("No semantic tokens for " .. bufname)
        return
      end

      local client = vim.lsp.get_client_by_id(ctx.client_id)
      local tokens = result.data
      local highlights = tokens_to_ranges(tokens, bufnr, client)
      local ft = vim.bo[bufnr].filetype
      local items = parse_highlights(highlights, ft)

      for _, item in ipairs(items) do
        for i = 1, 3 do
          args[num_args + i] = item[i]
        end
        vim.call(callback, unpack(args))
      end
    end)
  end)
end

-- Clangd extensions

vim.lsp.handlers["textDocument/clangd.fileStatus"] = function(_, res, _, _)
  local file = vim.uri_to_fname(res.uri)
  vim.fn.UpdateLspStatus(file, res.state)
end

local RequestBaseClass = function()
  local params = vim.lsp.util.make_position_params()
  params.resolve = 1
  params.direction = 1

  local handler = function(_, res, ctx, _)
    if not res or vim.tbl_isempty(res) then
      vim.notify('No results')
    else
      local client = vim.lsp.get_client_by_id(ctx.client_id)
      if client then
        api.nvim_call_function("TypeHierarchyHandler", {res, client.offset_encoding})
      end
    end
  end
  vim.lsp.buf_request(0, 'textDocument/typeHierarchy', params, handler)
end

local RequestDerivedClass = function()
  local params = vim.lsp.util.make_position_params()
  params.resolve = 1
  params.direction = 0

  local handler = function(_, res, ctx, _)
    if not res or vim.tbl_isempty(res) then
      vim.notify('No results')
    else
      local client = vim.lsp.get_client_by_id(ctx.client_id)
      if client then
        api.nvim_call_function("TypeHierarchyHandler", {res, client.offset_encoding})
      end
    end
  end
  vim.lsp.buf_request(0, 'textDocument/typeHierarchy', params, handler)
end

local RequestReferenceContainer = function()
  local params = vim.lsp.util.make_position_params()
  local handler = function(_, res, _, _)
    if not res or vim.tbl_isempty(res) then
      vim.notify('No results')
    else
      api.nvim_call_function("ReferenceContainerHandler", {res})
    end
  end
  vim.lsp.buf_request(0, 'textDocument/references', params, handler)
end

-- Auto completion

function ShowAutoCompletion(...)
  if not vim.fn.pumvisible() == 0 then
    return
  end
  local vargs = ({...})[1]
  local force_full = vargs ~= nil

  local bufnr = api.nvim_get_current_buf()
  local pos = api.nvim_win_get_cursor(0)
  local cursor_pos = pos[2]
  local line = api.nvim_get_current_line()
  local prefix = vim.fn.matchstr(string.sub(line, 1, cursor_pos), '\\k*$')
  if string.len(prefix) == 0 and not force_full then
    return
  end

  local params = vim.lsp.util.make_position_params()
  local handler = function(err, res, _)
    if err or not res or vim.tbl_isempty(res) then
      return
    end
    local complete_items = vim.lsp.completion._lsp_to_complete_items(res, prefix)
    if vim.tbl_isempty(complete_items) then
      return
    end

    local text_edit = complete_items[1].user_data.nvim.lsp.completion_item.textEdit
    local col_start = text_edit.range.start.character
    local col_end = text_edit.range['end'].character
    local new_text = text_edit.newText
    local old_text = string.sub(line, col_start + 1, col_end)
    if old_text == new_text then
      return
    end
    if force_full then
      -- Display whole completion in pop up menu
      local insert_pos = cursor_pos + 1 - string.len(prefix)
      vim.fn.complete(insert_pos, complete_items)
    else
      -- Display a single completion (what will be TAB completed) in pum
      local insert_pos = cursor_pos + 1 - string.len(prefix)
      vim.fn.complete(insert_pos, {complete_items[1]})
    end
  end

  vim.lsp.buf_request(bufnr, 'textDocument/completion', params, handler)
end

function GetAutoCompletion()
  local ns = api.nvim_create_namespace("autocomplete")
  local extmarks = api.nvim_buf_get_extmarks(0, ns, 0, -1, {details = true})
  if not vim.tbl_isempty(extmarks) then
    local details = extmarks[1][4]
    local text = details.virt_text[1][1]
    return text
  end
  return vim.fn.nr2char(9)
end

-- Keymaps and registration

local OnCclsAttach = function(_, bufnr)
  local function buf_set_keymap(...) api.nvim_buf_set_keymap(bufnr, ...) end
  local function user_command(...) api.nvim_buf_create_user_command(bufnr, ...) end
  local function autocmd(event, cb) api.nvim_create_autocmd({event}, {buffer=bufnr, callback = cb}) end

  -- Mappings
  local opts = { noremap=true, silent=true }

  buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('i', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  buf_set_keymap('n', '<leader>qf', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)

  buf_set_keymap('n', 'gs', '<cmd>lua vim.lsp.buf.document_symbol({loclist = false})<CR>', opts)
  -- gS(workspace_symbol) is implemented in init.vim
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_set_keymap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev({severity = vim.diagnostic.severity.ERROR})<CR>', opts)
  buf_set_keymap('n', ']d', '<cmd>lua vim.diagnostic.goto_next({severity = vim.diagnostic.severity.ERROR})<CR>', opts)
  buf_set_keymap('n', '<leader>dig', '<cmd>lua vim.diagnostic.setqflist()<CR>', opts)

  -- Commands
  opts = { nargs=0 }

  user_command("Base", RequestBaseClass, opts)
  user_command("Derived", RequestDerivedClass, opts)
  user_command("Reference", RequestReferenceContainer, opts)

  -- Autocommands
  autocmd('CursorHold', function() vim.lsp.buf.document_highlight() end)
  autocmd('CursorHoldI', function() vim.lsp.buf.document_highlight() end)
  autocmd('CursorMoved', function() vim.lsp.buf.clear_references() end)

  autocmd('TextChangedI', function() ShowAutoCompletion() end)

  buf_set_keymap('i', '<C-space>', '<cmd>lua ShowAutoCompletion({force_pum=true})<CR>', {noremap=true})
end

-- C++ LSP Config

vim.diagnostic.config({
  virtual_text = true
})

lspconfig.clangd.setup {
  on_attach = OnCclsAttach,
  init_options = {
    clangdFileStatus = true
  },
  capabilities = {
    textDocument = {
      references = {
        container = true
      }
    }
  },
  filetypes = { 'c', 'cpp' }
}

-- Python LSP Config

local OnPythonAttach = function(_, bufnr)
  local function buf_set_keymap(...) api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(name, value) api.nvim_set_option_value(name, value, {buf = bufnr}) end

  -- Enable completion triggered by <c-x><c-o>
  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings
  local opts = { noremap=true, silent=true }

  buf_set_keymap('i', '<C-Space>', '<C-X><C-O>', opts)
  buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('i', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)

  buf_set_keymap('n', '<leader>sym', '<cmd>lua vim.lsp.buf.document_symbol()<CR>', opts)
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_set_keymap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev({severity = vim.diagnostic.severity.ERROR;})<CR>', opts)
  buf_set_keymap('n', ']d', '<cmd>lua vim.diagnostic.goto_next({severity = vim.diagnostic.severity.ERROR;})<CR>', opts)
  buf_set_keymap('n', '<leader>dig', '<cmd>lua vim.diagnostic.setqflist()<CR>', opts)
end

lspconfig.basedpyright.setup{
  cmd = {"/home/stef/.local/bin/basedpyright-langserver", "--stdio"},
  on_attach = OnPythonAttach,
}

-- Lua LSP Config

local OnLuaInit = function(client)
  local path = client.workspace_folders[1].name
  if uv.fs_stat(path..'/.luarc.json') or uv.fs_stat(path..'/.luarc.jsonc') then
    return
  end

  client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
    runtime = {
      -- Tell the language server which version of Lua you're using
      -- (most likely LuaJIT in the case of Neovim)
      version = 'LuaJIT'
    },
    -- Make the server aware of Neovim runtime files
    workspace = {
      checkThirdParty = false,
      library = {
        vim.env.VIMRUNTIME
        -- Depending on the usage, you might want to add additional paths here.
        -- "${3rd}/luv/library"
        -- "${3rd}/busted/library",
      }
      -- or pull in all of 'runtimepath'. NOTE: this is a lot slower
      -- library = vim.api.nvim_get_runtime_file("", true)
    }})
end

local OnLuaAttach = function(_, bufnr)
  local function buf_set_keymap(...) api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(name, value) api.nvim_set_option_value(name, value, {buf = bufnr}) end

  -- Enable completion triggered by <c-x><c-o>
  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings
  local opts = { noremap=true, silent=true }

  buf_set_keymap('i', '<C-Space>', '<C-X><C-O>', opts)
  buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('i', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)

  buf_set_keymap('n', '<leader>sym', '<cmd>lua vim.lsp.buf.document_symbol()<CR>', opts)
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_set_keymap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev({severity = vim.diagnostic.severity.ERROR;})<CR>', opts)
  buf_set_keymap('n', ']d', '<cmd>lua vim.diagnostic.goto_next({severity = vim.diagnostic.severity.ERROR;})<CR>', opts)
  buf_set_keymap('n', '<leader>dig', '<cmd>lua vim.diagnostic.setqflist()<CR>', opts)
end

lspconfig.lua_ls.setup {
  on_init = OnLuaInit,
  on_attach = OnLuaAttach,
  settings = {
    Lua = {}
  },
}

-- System clipboard

local function copy(lines, _)
  require('osc52').copy(table.concat(lines, '\n'))
end

local function paste()
  return {{}, ''}
end

if vim.fn.eval("$SSH_TTY") ~= "" then
  vim.g.clipboard = {
    name = 'osc52',
    copy = {['+'] = copy, ['*'] = copy},
    paste = {['+'] = paste, ['*'] = paste},
  }
end
