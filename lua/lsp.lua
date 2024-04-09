-- vim: set sw=2 ts=2 sts=2 foldmethod=marker:

local lspconfig = require('lspconfig')
local api = vim.api

-- Clangd extensions

local RequestBaseClass = function()
  local params = vim.lsp.util.make_position_params()
  params.resolve = 1
  params.direction = 1

  local handler = function(_, res, ctx, _)
    if not res or vim.tbl_isempty(res) then
      vim.notify('No results')
    else
      local client = vim.lsp.get_client_by_id(ctx.client_id)
      api.nvim_call_function("TypeHierarchyHandler", {res, client.offset_encoding})
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
      api.nvim_call_function("TypeHierarchyHandler", {res, client.offset_encoding})
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
  local vargs = ({...})[1]
  local force_pum = vim.fn.pumvisible() ~= 0 or vargs ~= nil

  if not vim.fn.pumvisible() == 0 then
    return ClearAutoCompletion()
  end

  local bufnr = api.nvim_get_current_buf()
  local pos = api.nvim_win_get_cursor(0)
  local cursor_pos = pos[2]
  local line = api.nvim_get_current_line()
  local prefix = vim.fn.matchstr(string.sub(line, 1, cursor_pos), '\\k*$')
  if string.len(prefix) == 0 and not force_pum then
    return ClearAutoCompletion()
  end

  local params = vim.lsp.util.make_position_params()
  local handler = function(err, res, _)
    -- Clear the autocompletion as late as possible. Avoids the delay with in the LSP response
    ClearAutoCompletion()
    if err or not res or vim.tbl_isempty(res) then
      return
    end
    local complete_items = vim.lsp.util.text_document_completion_list_to_complete_items(res, prefix)
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

    local end_of_line = (cursor_pos == string.len(line))
    if force_pum then
      -- Display whole completion in pop up menu
      local insert_pos = cursor_pos + 1 - string.len(prefix)
      vim.fn.complete(insert_pos, complete_items)
    elseif end_of_line then
      -- Display inline
      local text = string.sub(new_text, string.len(old_text) + 1, -1)
      local line_pos = pos[1] - 1
      local opts = {virt_text = {{text, "NonText"}}, virt_text_win_col = col_end}
      local ns = api.nvim_create_namespace("autocomplete")
      api.nvim_buf_set_extmark(0, ns, line_pos, -1, opts)
    else
      -- Display a single completion (what will be TAB completed) in pum
      local insert_pos = cursor_pos + 1 - string.len(prefix)
      vim.fn.complete(insert_pos, {complete_items[1]})
    end
  end

  vim.lsp.buf_request(bufnr, 'textDocument/completion', params, handler)
end

function ClearAutoCompletion()
  local ns = api.nvim_create_namespace("autocomplete")
  api.nvim_buf_clear_namespace(0, ns, 0, -1)
end

function GetAutoCompletion()
  local ns = api.nvim_create_namespace("autocomplete")
  local extmarks = api.nvim_buf_get_extmarks(0, ns, 0, -1, {details = 1})
  if not vim.tbl_isempty(extmarks) then
    local details = extmarks[1][4]
    local text = details.virt_text[1][1]
    return text
  end
  return vim.fn.nr2char(9)
end

function AcceptAutoCompletion()
  -- TODO just apply the text edit dummy!
  local res = GetAutoCompletion()
  ClearAutoCompletion()

  if vim.fn.pumvisible() == 1 then
    -- Return <C-y>
    return vim.fn.nr2char(25)
  else
    return res
  end
end

-- Keymaps and registration

local OnCclsAttach = function(_, bufnr)
  local function buf_set_keymap(...) api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) api.nvim_buf_set_option(bufnr, ...) end
  local function user_command(...) api.nvim_buf_create_user_command(bufnr, ...) end
  local function autocmd(event, cb) api.nvim_create_autocmd({event}, {buffer=bufnr, callback = cb}) end

  -- Mappings
  local opts = { noremap=true, silent=true }

  buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('i', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  buf_set_keymap('n', '<leader>qf', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)

  buf_set_keymap('n', 'gs', '<cmd>lua vim.lsp.buf.document_symbol()<CR>', opts)
  buf_set_keymap('n', 'gS', '<cmd>lua vim.lsp.buf.workspace_symbol()<CR>', opts)
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
  autocmd('InsertLeave', function() ClearAutoCompletion() end)

  buf_set_keymap('i', '<C-space>', '<cmd>lua ShowAutoCompletion({force_pum=true})<CR>', {noremap=true})
  buf_set_keymap('i', '<Tab>', 'luaeval("AcceptAutoCompletion()")', {noremap=true, silent=true, expr=true})
end

lspconfig.clangd.setup {
  on_attach = OnCclsAttach,
  init_options = {
    -- Trash, don't try it again
    clangdFileStatus = false
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

local OnLuaInit = function(client)
  local path = client.workspace_folders[1].name
  if vim.loop.fs_stat(path..'/.luarc.json') or vim.loop.fs_stat(path..'/.luarc.jsonc') then
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
  local function buf_set_option(...) api.nvim_buf_set_option(bufnr, ...) end

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
  return {vim.fn.split(vim.fn.getreg(''), '\n'), vim.fn.getregtype('')}
end

if vim.fn.eval("$SSH_TTY") ~= "" then
  vim.g.clipboard = {
    name = 'osc52',
    copy = {['+'] = copy, ['*'] = copy},
    paste = {['+'] = paste, ['*'] = paste},
  }
end
