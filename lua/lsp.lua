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
  local handler = function(_, res, ctx, _)
    if not res or vim.tbl_isempty(res) then
      vim.notify('No results')
    else
      api.nvim_call_function("ReferenceContainerHandler", {res})
    end
  end
  vim.lsp.buf_request(0, 'textDocument/references', params, handler)
end

local RequestSwitchSourceHeader = function()
  local params = vim.lsp.util.make_text_document_params(0)
  local handler = function(_, res, ctx, _)
    if not res then
      vim.notify('No results')
    else
      api.nvim_call_function("SwitchSourceHeaderHandler", {res})
    end
  end
  vim.lsp.buf_request(0, 'textDocument/switchSourceHeader', params, handler)
end

-- Auto completion

function ShowAutoCompletion()
  local bufnr = api.nvim_get_current_buf()
  local pos = api.nvim_win_get_cursor(0)
  local cursor_pos = pos[2]
  local line = api.nvim_get_current_line()
  local prefix = vim.fn.matchstr(string.sub(line, 1, cursor_pos), '\\k*$')
  if string.len(prefix) == 0 then
    return ClearAutoCompletion()
  end

  local params = vim.lsp.util.make_position_params()
  local handler = function(err, res, ctx)
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
    if end_of_line then
      -- Display inline
      local text = string.sub(new_text, string.len(old_text) + 1, -1)
      local line_pos = pos[1] - 1
      local opts = {virt_text = {{text, "NonText"}}, virt_text_win_col = col_end}
      local ns = api.nvim_create_namespace("autocomplete")
      local mark = api.nvim_buf_set_extmark(0, ns, line_pos, -1, opts)
    else
      -- Display whole completion in pum
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
  local res = GetAutoCompletion()
  ClearAutoCompletion()

  if vim.fn.pumvisible() == 1 then
    return vim.fn.nr2char(25) -- <C-y>
  else
    return res
  end
end

-- Keymaps and registration

local OnAttach = function(client, bufnr)
  local function buf_set_keymap(...) api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) api.nvim_buf_set_option(bufnr, ...) end
  local function user_command(...) api.nvim_buf_create_user_command(bufnr, ...) end

  -- Enable completion triggered by <c-x><c-o>
  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings
  local opts = { noremap=true, silent=true }

  buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('i', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  buf_set_keymap('n', '<leader>qf', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)

  buf_set_keymap('n', '<leader>sym', '<cmd>lua vim.lsp.buf.document_symbol()<CR>', opts)
  buf_set_keymap('n', '<leader>gsym', '<cmd>lua vim.lsp.buf.workspace_symbol()<CR>', opts)
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_set_keymap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev({severity = vim.diagnostic.severity.ERROR;})<CR>', opts)
  buf_set_keymap('n', ']d', '<cmd>lua vim.diagnostic.goto_next({severity = vim.diagnostic.severity.ERROR;})<CR>', opts)
  buf_set_keymap('n', '<leader>dig', '<cmd>lua vim.diagnostic.setqflist()<CR>', opts)

  -- Commands
  local opts = { nargs=0 }

  user_command("Base", RequestBaseClass, opts)
  user_command("Derived", RequestDerivedClass, opts)
  user_command("Reference", RequestReferenceContainer, opts)

  -- Autocommands for highlight
  vim.cmd('autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()')
  vim.cmd('autocmd CursorHoldI <buffer> lua vim.lsp.buf.document_highlight()')
  vim.cmd('autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()')

  vim.cmd('autocmd TextChangedI <buffer> lua ShowAutoCompletion()')
  vim.cmd('autocmd InsertLeave <buffer> lua ClearAutoCompletion()')
  vim.cmd('autocmd CompleteChanged <buffer> lua ClearAutoCompletion()')
  vim.cmd('inoremap <expr> <Tab> luaeval("AcceptAutoCompletion()")')
end

lspconfig.clangd.setup {
  on_attach = OnAttach,
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
