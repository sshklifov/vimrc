-- vim: set sw=2 ts=2 sts=2 foldmethod=marker:

local lspconfig = require('lspconfig')

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
      vim.api.nvim_call_function("TypeHierarchyHandler", {res, client.offset_encoding})
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
      vim.api.nvim_call_function("TypeHierarchyHandler", {res, client.offset_encoding})
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
      vim.api.nvim_call_function("ReferenceContainerHandler", {res})
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
      vim.api.nvim_call_function("SwitchSourceHeaderHandler", {res})
    end
  end
  vim.lsp.buf_request(0, 'textDocument/switchSourceHeader', params, handler)
end

-- Keymaps and registration

local OnAttach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end
  local function user_command(...) vim.api.nvim_buf_create_user_command(bufnr, ...) end

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
  }
}
