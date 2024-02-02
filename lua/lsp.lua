-- vim: set sw=2 ts=2 sts=2 foldmethod=marker:

local lspconfig = require('lspconfig')

-- ccls LSP extensions

vim.lsp.handlers['$ccls/call'] = function(_, res, ctx, _)
  if not res or vim.tbl_isempty(res) then
    vim.notify('No methods found')
  else
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    vim.fn.setqflist({}, ' ', {
      title = 'Callees';
      items = vim.lsp.util.locations_to_items(res, client.offset_encoding);
      context = ctx;
    })
    vim.api.nvim_command("botright copen")
  end
end

local RequestCall = function()
  local params = vim.lsp.util.make_position_params()
  params.callee = true
  vim.lsp.buf_request(0, '$ccls/call', params)
end

vim.lsp.handlers['$ccls/member'] = function(_, res, ctx, _)
  if not res or vim.tbl_isempty(res) then
    vim.notify('No members found')
  else
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    vim.fn.setqflist({}, ' ', {
      title = 'Members';
      items = vim.lsp.util.locations_to_items(res, client.offset_encoding);
      context = ctx;
    })
    vim.api.nvim_command("botright copen")
  end
end

local RequestMemVar = function()
  local params = vim.lsp.util.make_position_params()
  params.kind = 0
  vim.lsp.buf_request(0, '$ccls/member', params)
end

local RequestMemFun = function()
  local params = vim.lsp.util.make_position_params()
  params.kind = 3
  vim.lsp.buf_request(0, '$ccls/member', params)
end

local RequestMemType = function()
  local params = vim.lsp.util.make_position_params()
  params.kind = 2
  vim.lsp.buf_request(0, '$ccls/member', params)
end

vim.lsp.handlers['$ccls/vars'] = function(_, res, ctx, _)
  if not res or vim.tbl_isempty(res) then
    vim.notify('No instances found')
  else
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    vim.fn.setqflist({}, ' ', {
      title = 'Instances';
      items = vim.lsp.util.locations_to_items(res, client.offset_encoding);
      context = ctx;
    })
    vim.api.nvim_command("botright copen")
  end
end

local RequestInstances = function()
  local params = vim.lsp.util.make_position_params()
  vim.lsp.buf_request(0, '$ccls/vars', params)
end

vim.lsp.handlers['$ccls/inheritance'] = function(_, res, ctx, _)
  if not res or vim.tbl_isempty(res) then
    vim.notify('No classes found')
  else
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    vim.fn.setqflist({}, ' ', {
      title = 'Classes';
      items = vim.lsp.util.locations_to_items(res, client.offset_encoding);
      context = ctx;
    })
    vim.api.nvim_command("botright copen")
  end
end

local RequestBaseClass = function()
  local params = vim.lsp.util.make_position_params()
  params.derived = false
  vim.lsp.buf_request(0, '$ccls/inheritance', params)
end

local RequestDerivedClass = function()
  local params = vim.lsp.util.make_position_params()
  params.derived = true
  vim.lsp.buf_request(0, '$ccls/inheritance', params)
end

local RequestRoleWrite = function()
  local params = vim.lsp.util.make_position_params()
  params.role = 16
  vim.lsp.buf_request(0, 'textDocument/references', params)
end

local RequestRoleRead = function()
  local params = vim.lsp.util.make_position_params()
  params.role = 8
  vim.lsp.buf_request(0, 'textDocument/references', params)
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

  user_command("CallGraph", RequestCall, opts)
  user_command("MemVars", RequestMemVar, opts)
  user_command("MemFuns", RequestMemFun, opts)
  user_command("MemTypes", RequestMemType, opts)
  user_command("Instances", RequestInstances, opts)
  user_command("Base", RequestBaseClass, opts)
  user_command("Derived", RequestDerivedClass, opts)
  user_command("WriteRefs", RequestRoleWrite, opts)
  user_command("ReadRefs", RequestRoleRead, opts)

  -- Autocommands for highlight
  vim.cmd('autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()')
  vim.cmd('autocmd CursorHoldI <buffer> lua vim.lsp.buf.document_highlight()')
  vim.cmd('autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()')
end

function GetCachePath()
  -- return ""
  return "/home/" .. os.getenv("USER") ..  "/ccls-cache"
end

lspconfig.ccls.setup {
  init_options = {
    cache = {
      directory = GetCachePath(),
      hierarchicalPath = true
    },
    highlight = {
      lsRanges = true
    },
  },
  on_attach = OnAttach,
  flags = {
    debounce_text_changes = 150
  },

  -- Uncomment for debug log
  -- cmd = { "/usr/bin/ccls", "-log-file=/tmp/ccls.log", "-v=1"}
}
