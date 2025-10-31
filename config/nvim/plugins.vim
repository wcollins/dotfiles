" ~/.config/nvim/plugins.vim
" plugin-specific configurations

" ensure lua configuration is loaded
lua << EOF
-- treesitter configuration
require('nvim-treesitter.configs').setup {
  ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "python", "javascript", "typescript", "bash", "json", "yaml", "markdown", "go", "rust" },
  sync_install = false,
  auto_install = true,
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
  indent = {
    enable = true
  }
}

-- lsp configuration (must be loaded first)
local lspconfig = require('lspconfig')

-- mason setup (must be after lspconfig is loaded)
local mason_ok, mason = pcall(require, 'mason')
if mason_ok then
  mason.setup({
    ui = {
      icons = {
        package_installed = "✓",
        package_pending = "➜",
        package_uninstalled = "✗"
      }
    }
  })
end

local mason_lsp_ok, mason_lspconfig = pcall(require, 'mason-lspconfig')
if mason_lsp_ok then
  mason_lspconfig.setup({
    ensure_installed = {
      'pyright',
      'ts_ls',
      'lua_ls',
      'rust_analyzer',
      'bashls',
      'jsonls',
      'yamlls',
    },
    automatic_installation = true,
    automatic_enable = false,  -- disable automatic_enable feature (requires newer Neovim)
    handlers = {
      -- default handler for all servers
      function(server_name)
        lspconfig[server_name].setup({
          capabilities = require('cmp_nvim_lsp').default_capabilities()
        })
      end,
      -- custom lua_ls setup
      ['lua_ls'] = function()
        lspconfig.lua_ls.setup({
          capabilities = require('cmp_nvim_lsp').default_capabilities(),
          settings = {
            Lua = {
              runtime = { version = 'LuaJIT' },
              diagnostics = { globals = {'vim'} },
              workspace = { library = vim.api.nvim_get_runtime_file("", true) },
              telemetry = { enable = false },
            },
          },
        })
      end,
    },
  })
end

-- completion setup
local cmp = require('cmp')
local luasnip = require('luasnip')

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  }),
  sources = cmp.config.sources({
    { name = 'luasnip' },
  }, {
    { name = 'buffer' },
  })
})

-- cmdline completion
cmp.setup.cmdline({ '/', '?' }, {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = 'buffer' }
  }
})

cmp.setup.cmdline(':', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    { name = 'path' }
  }, {
    { name = 'cmdline' }
  })
})

-- lsp servers are now automatically configured by mason-lspconfig.setup_handlers() above

-- lualine (statusline) setup
require('lualine').setup({
  options = {
    icons_enabled = true,
    theme = 'auto',
    component_separators = { left = '', right = ''},
    section_separators = { left = '', right = ''},
    disabled_filetypes = {
      statusline = {},
      winbar = {},
    },
    ignore_focus = {},
    always_divide_middle = true,
    globalstatus = false,
    refresh = {
      statusline = 1000,
      tabline = 1000,
      winbar = 1000,
    }
  },
  sections = {
    lualine_a = {'mode'},
    lualine_b = {'branch', 'diff', 'diagnostics'},
    lualine_c = {'filename'},
    lualine_x = {'encoding', 'fileformat', 'filetype'},
    lualine_y = {'progress'},
    lualine_z = {'location'}
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {'filename'},
    lualine_x = {'location'},
    lualine_y = {},
    lualine_z = {}
  },
  tabline = {},
  winbar = {},
  inactive_winbar = {},
  extensions = {'nvim-tree', 'fugitive'}
})

-- nvim-tree setup
require('nvim-tree').setup({
  sort = {
    sorter = "case_sensitive",
  },
  view = {
    width = 30,
  },
  renderer = {
    group_empty = true,
  },
  filters = {
    dotfiles = false,
    git_ignored = false,
    custom = { "^\\.git$", "^\\.DS_Store$", "__pycache__", "\\.pyc$" },
  },
  git = {
    enable = true,
    ignore = false,
    timeout = 400,
  },
})

-- telescope setup
require('telescope').setup({
  defaults = {
    mappings = {
      i = {
        ["<C-n>"] = require('telescope.actions').cycle_history_next,
        ["<C-p>"] = require('telescope.actions').cycle_history_prev,
        ["<C-j>"] = require('telescope.actions').move_selection_next,
        ["<C-k>"] = require('telescope.actions').move_selection_previous,
      },
    },
  },
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case",
    }
  }
})

-- load telescope extensions
require('telescope').load_extension('fzf')

-- aerial (symbol outline) setup
require('aerial').setup({
  backends = { "lsp", "treesitter", "markdown", "man" },
  layout = {
    max_width = { 40, 0.2 },
    width = nil,
    min_width = 10,
    win_opts = {},
    default_direction = "prefer_right",
    placement = "window",
  },
  attach_mode = "window",
  close_automatic_events = {},
  keymaps = {
    ["?"] = "actions.show_help",
    ["g?"] = "actions.show_help",
    ["<CR>"] = "actions.jump",
    ["<2-LeftMouse>"] = "actions.jump",
    ["<C-v>"] = "actions.jump_vsplit",
    ["<C-s>"] = "actions.jump_split",
    ["p"] = "actions.scroll",
    ["<C-j>"] = "actions.down_and_scroll",
    ["<C-k>"] = "actions.up_and_scroll",
    ["{"] = "actions.prev",
    ["}"] = "actions.next",
    ["[["] = "actions.prev_up",
    ["]]"] = "actions.next_up",
    ["q"] = "actions.close",
    ["o"] = "actions.tree_toggle",
    ["za"] = "actions.tree_toggle",
    ["O"] = "actions.tree_toggle_recursive",
    ["zA"] = "actions.tree_toggle_recursive",
    ["l"] = "actions.tree_open",
    ["zo"] = "actions.tree_open",
    ["L"] = "actions.tree_open_recursive",
    ["zO"] = "actions.tree_open_recursive",
    ["h"] = "actions.tree_close",
    ["zc"] = "actions.tree_close",
    ["H"] = "actions.tree_close_recursive",
    ["zC"] = "actions.tree_close_recursive",
    ["zr"] = "actions.tree_increase_fold_level",
    ["zR"] = "actions.tree_open_all",
    ["zm"] = "actions.tree_decrease_fold_level",
    ["zM"] = "actions.tree_close_all",
    ["zx"] = "actions.tree_sync_folds",
    ["zX"] = "actions.tree_sync_folds",
  },
  lazy_load = true,
  disable_max_lines = 10000,
  disable_max_size = 2000000,
  filter_kind = {
    "Class",
    "Constructor",
    "Enum",
    "Function",
    "Interface",
    "Module",
    "Method",
    "Struct",
  },
})

-- gitsigns setup
require('gitsigns').setup({
  signs = {
    add          = { text = '+' },
    change       = { text = '~' },
    delete       = { text = '_' },
    topdelete    = { text = '‾' },
    changedelete = { text = '~' },
    untracked    = { text = '┆' },
  },
  signcolumn = true,
  numhl      = false,
  linehl     = false,
  word_diff  = false,
  watch_gitdir = {
    follow_files = true
  },
  attach_to_untracked = true,
  current_line_blame = false,
  current_line_blame_opts = {
    virt_text = true,
    virt_text_pos = 'eol',
    delay = 1000,
    ignore_whitespace = false,
  },
  current_line_blame_formatter = '<author>, <author_time:%Y-%m-%d> - <summary>',
  sign_priority = 6,
  update_debounce = 100,
  status_formatter = nil,
  max_file_length = 40000,
  preview_config = {
    border = 'single',
    style = 'minimal',
    relative = 'cursor',
    row = 0,
    col = 1
  },
})

-- autopairs setup
require('nvim-autopairs').setup({
  check_ts = true,
  ts_config = {
    lua = {'string', 'source'},
    javascript = {'string', 'template_string'},
    java = false,
  },
  disable_filetype = { "TelescopePrompt", "spectre_panel" },
  disable_in_macro = true,
  disable_in_visualblock = false,
  disable_in_replace_mode = true,
  ignored_next_char = [=[[%w%%%'%[%"%.%`%$]]=],
  enable_moveright = true,
  enable_afterquote = true,
  enable_check_bracket_line = true,
  enable_bracket_in_quote = true,
  enable_abbr = false,
  break_undo = true,
  check_comma = true,
  map_cr = true,
  map_bs = true,
  map_c_h = false,
  map_c_w = false,
})

-- Comment.nvim setup
require('Comment').setup({
  padding = true,
  sticky = true,
  ignore = '^$',
  toggler = {
    line = 'gcc',
    block = 'gbc',
  },
  opleader = {
    line = 'gc',
    block = 'gb',
  },
  extra = {
    above = 'gcO',
    below = 'gco',
    eol = 'gcA',
  },
  mappings = {
    basic = true,
    extra = true,
  },
  pre_hook = nil,
  post_hook = nil,
})

-- render-markdown setup
require('render-markdown').setup({
  enabled = false,
  max_file_size = 10.0,
  debounce = 100,
  render_modes = { 'c' },
  anti_conceal = {
    enabled = true,
  },
  latex = {
    enabled = true,
    converter = 'latex2text',
    highlight = 'RenderMarkdownMath',
    top_pad = 0,
    bottom_pad = 0,
  },
  heading = {
    enabled = true,
    sign = true,
    position = 'overlay',
    icons = { '󰲡 ', '󰲣 ', '󰲥 ', '󰲧 ', '󰲩 ', '󰲫 ' },
    signs = { 'RenderMarkdownH1Sign', 'RenderMarkdownH2Sign', 'RenderMarkdownH3Sign', 'RenderMarkdownH4Sign', 'RenderMarkdownH5Sign', 'RenderMarkdownH6Sign' },
    width = 'full',
    left_pad = 0,
    right_pad = 0,
    min_width = 0,
    border = false,
    border_virtual = false,
    border_prefix = false,
    above = '▄',
    below = '▀',
    backgrounds = {
      'RenderMarkdownH1Bg',
      'RenderMarkdownH2Bg',
      'RenderMarkdownH3Bg',
      'RenderMarkdownH4Bg',
      'RenderMarkdownH5Bg',
      'RenderMarkdownH6Bg',
    },
    foregrounds = {
      'RenderMarkdownH1',
      'RenderMarkdownH2',
      'RenderMarkdownH3',
      'RenderMarkdownH4',
      'RenderMarkdownH5',
      'RenderMarkdownH6',
    },
  },
})

EOF

" lsp keybindings (set globally)
augroup LspKeymaps
  autocmd!
  autocmd LspAttach * nnoremap <buffer> gd <cmd>lua vim.lsp.buf.definition()<cr>
  autocmd LspAttach * nnoremap <buffer> gD <cmd>lua vim.lsp.buf.declaration()<cr>
  autocmd LspAttach * nnoremap <buffer> gi <cmd>lua vim.lsp.buf.implementation()<cr>
  autocmd LspAttach * nnoremap <buffer> go <cmd>lua vim.lsp.buf.type_definition()<cr>
  autocmd LspAttach * nnoremap <buffer> gr <cmd>lua vim.lsp.buf.references()<cr>
  autocmd LspAttach * nnoremap <buffer> gs <cmd>lua vim.lsp.buf.signature_help()<cr>
  autocmd LspAttach * nnoremap <buffer> <F2> <cmd>lua vim.lsp.buf.rename()<cr>
  autocmd LspAttach * nnoremap <buffer> <F4> <cmd>lua vim.lsp.buf.code_action()<cr>
  autocmd LspAttach * nnoremap <buffer> gl <cmd>lua vim.diagnostic.open_float()<cr>
  autocmd LspAttach * nnoremap <buffer> [d <cmd>lua vim.diagnostic.goto_prev()<cr>
  autocmd LspAttach * nnoremap <buffer> ]d <cmd>lua vim.diagnostic.goto_next()<cr>
augroup END
