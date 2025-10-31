" ~/.config/nvim/theme.vim
" theme and color scheme configuration

" enable true color support
if has('termguicolors')
    set termguicolors
endif

" set background
set background=dark

" try to set modern color scheme with fallbacks
try
    " first try catppuccin
    colorscheme catppuccin
catch /^Vim\%((\a\+)\)\=:E185/
    try
        " fallback to tokyonight
        colorscheme tokyonight-night
    catch /^Vim\%((\a\+)\)\=:E185/
        try
            " fallback to catppuccin (any variant)
            colorscheme catppuccin
        catch /^Vim\%((\a\+)\)\=:E185/
            try
                " fallback to tokyonight (any variant)
                colorscheme tokyonight
            catch /^Vim\%((\a\+)\)\=:E185/
                " ultimate fallback to built-in scheme
                colorscheme habamax
            endtry
        endtry
    endtry
endtry

" lua configuration for modern themes
lua << EOF
-- catppuccin configuration
local status_ok, catppuccin = pcall(require, "catppuccin")
if status_ok then
  catppuccin.setup({
    flavour = "mocha", -- latte, frappe, macchiato, mocha
    background = { -- :h background
        light = "latte",
        dark = "mocha",
    },
    transparent_background = false,
    show_end_of_buffer = false,
    term_colors = false,
    dim_inactive = {
        enabled = false,
        shade = "dark",
        percentage = 0.15,
    },
    no_italic = false,
    no_bold = false,
    no_underline = false,
    styles = {
        comments = { "italic" },
        conditionals = { "italic" },
        loops = {},
        functions = {},
        keywords = {},
        strings = {},
        variables = {},
        numbers = {},
        booleans = {},
        properties = {},
        types = {},
        operators = {},
    },
    color_overrides = {},
    custom_highlights = {},
    integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        treesitter = true,
        aerial = true,
        telescope = {
            enabled = true,
        },
        render_markdown = true,
        which_key = true,
    },
  })
end

-- tokyonight configuration
local status_ok_tokyo, tokyonight = pcall(require, "tokyonight")
if status_ok_tokyo then
  tokyonight.setup({
    style = "night", -- storm, moon, night, day
    light_style = "day",
    transparent = false,
    terminal_colors = true,
    styles = {
      comments = { italic = true },
      keywords = { italic = true },
      functions = {},
      variables = {},
      sidebars = "dark",
      floats = "dark",
    },
    sidebars = { "qf", "help", "terminal", "packer", "NvimTree" },
    day_brightness = 0.3,
    hide_inactive_statusline = false,
    dim_inactive = false,
    lualine_bold = false,
    on_colors = function(colors) end,
    on_highlights = function(highlights, colors) end,
  })
end

-- nightfox configuration
local status_ok_nightfox, nightfox = pcall(require, "nightfox")
if status_ok_nightfox then
  nightfox.setup({
    options = {
      compile_path = vim.fn.stdpath("cache") .. "/nightfox",
      compile_file_suffix = "_compiled",
      transparent = false,
      terminal_colors = true,
      dim_inactive = false,
      module_default = true,
      styles = {
        comments = "italic",
        conditionals = "NONE",
        constants = "NONE",
        functions = "NONE",
        keywords = "NONE",
        numbers = "NONE",
        operators = "NONE",
        strings = "NONE",
        types = "NONE",
        variables = "NONE",
      },
      inverse = {
        match_paren = false,
        visual = false,
        search = false,
      },
    },
  })
end

-- kanagawa configuration
local status_ok_kanagawa, kanagawa = pcall(require, "kanagawa")
if status_ok_kanagawa then
  kanagawa.setup({
    compile = false,
    undercurl = true,
    commentStyle = { italic = true },
    functionStyle = {},
    keywordStyle = { italic = true},
    statementStyle = { bold = true },
    typeStyle = {},
    transparent = false,
    dimInactive = false,
    terminalColors = true,
    colors = {
      palette = {},
      theme = { wave = {}, lotus = {}, dragon = {}, all = {} },
    },
    overrides = function(colors)
      return {}
    end,
    theme = "wave",
    background = {
      dark = "wave",
      light = "lotus"
    },
  })
end

-- rose-pine configuration
local status_ok_rose, rose_pine = pcall(require, "rose-pine")
if status_ok_rose then
  rose_pine.setup({
    variant = "auto",
    dark_variant = "main",
    bold_vert_split = false,
    dim_nc_background = false,
    disable_background = false,
    disable_float_background = false,
    disable_italics = false,
    groups = {
      background = 'base',
      background_nc = '_experimental_nc',
      panel = 'surface',
      panel_nc = 'base',
      border = 'highlight_med',
      comment = 'muted',
      link = 'iris',
      punctuation = 'subtle',
      error = 'love',
      hint = 'iris',
      info = 'foam',
      warn = 'gold',
      headings = {
        h1 = 'iris',
        h2 = 'foam',
        h3 = 'rose',
        h4 = 'gold',
        h5 = 'pine',
        h6 = 'foam',
      }
    },
  })
end

-- gruvbox-material configuration
vim.g.gruvbox_material_background = 'medium'
vim.g.gruvbox_material_better_performance = 1
vim.g.gruvbox_material_enable_italic = 1
vim.g.gruvbox_material_disable_italic_comment = 0
vim.g.gruvbox_material_transparent_background = 0
vim.g.gruvbox_material_foreground = 'material'
vim.g.gruvbox_material_ui_contrast = 'low'

-- onedark configuration
local status_ok_onedark, onedark = pcall(require, "onedark")
if status_ok_onedark then
  onedark.setup {
    style = 'dark', -- dark, darker, cool, deep, warm, warmer
    transparent = false,
    term_colors = true,
    ending_tildes = false,
    cmp_itemkind_reverse = false,
    toggle_style_key = nil,
    code_style = {
      comments = 'italic',
      keywords = 'none',
      functions = 'none',
      strings = 'none',
      variables = 'none'
    },
    lualine = {
      transparent = false,
    },
    colors = {},
    highlights = {},
    diagnostics = {
      darker = true,
      undercurl = true,
      background = true,
    },
  }
end

-- dracula configuration
local status_ok_dracula, dracula = pcall(require, "dracula")
if status_ok_dracula then
  dracula.setup({
    colors = {},
    show_end_of_buffer = true,
    transparent_bg = false,
    lualine_bg_color = nil,
    italic_comment = true,
    overrides = {},
  })
end

-- everforest configuration
vim.g.everforest_background = 'medium'
vim.g.everforest_better_performance = 1
vim.g.everforest_enable_italic = 1
vim.g.everforest_disable_italic_comment = 0
vim.g.everforest_transparent_background = 0
vim.g.everforest_ui_contrast = 'low'
vim.g.everforest_spell_foreground = 'none'

-- github-nvim-theme configuration
local status_ok_github, github_theme = pcall(require, "github-theme")
if status_ok_github then
  github_theme.setup({
    options = {
      compile_path = vim.fn.stdpath('cache') .. '/github-theme',
      compile_file_suffix = '_compiled',
      hide_end_of_buffer = true,
      hide_nc_statusline = true,
      transparent = false,
      terminal_colors = true,
      dim_inactive = false,
      module_default = true,
      styles = {
        comments = 'italic',
        functions = 'NONE',
        keywords = 'NONE',
        variables = 'NONE',
        conditionals = 'NONE',
        constants = 'NONE',
        numbers = 'NONE',
        operators = 'NONE',
        strings = 'NONE',
        types = 'NONE',
      },
      inverse = {
        match_paren = false,
        visual = false,
        search = false,
      },
    },
  })
end
EOF

" customize highlights for better visibility
highlight Normal guibg=NONE ctermbg=NONE
highlight SignColumn guibg=NONE ctermbg=NONE
highlight GitSignsAdd guifg=#50C878 ctermfg=35
highlight GitSignsChange guifg=#FFA500 ctermfg=214
highlight GitSignsDelete guifg=#FF6B6B ctermfg=196

" ensure proper highlighting for diagnostics
highlight DiagnosticError guifg=#FF6B6B ctermfg=196
highlight DiagnosticWarn guifg=#FFA500 ctermfg=214
highlight DiagnosticInfo guifg=#87CEEB ctermfg=117
highlight DiagnosticHint guifg=#98FB98 ctermfg=120

" customize telescope highlights
highlight TelescopeSelection guibg=#3e4452 ctermbg=238
highlight TelescopeMatching guifg=#61afef ctermfg=75

" customize completion menu highlights
highlight CmpItemAbbrMatch guifg=#61afef ctermfg=75
highlight CmpItemAbbrMatchFuzzy guifg=#61afef ctermfg=75
highlight CmpItemKindText guifg=#98c379 ctermfg=114
highlight CmpItemKindMethod guifg=#c678dd ctermfg=176
highlight CmpItemKindFunction guifg=#c678dd ctermfg=176
highlight CmpItemKindConstructor guifg=#e06c75 ctermfg=168
highlight CmpItemKindField guifg=#e06c75 ctermfg=168
highlight CmpItemKindVariable guifg=#e06c75 ctermfg=168
highlight CmpItemKindClass guifg=#e5c07b ctermfg=180
highlight CmpItemKindInterface guifg=#e5c07b ctermfg=180
highlight CmpItemKindModule guifg=#61afef ctermfg=75
highlight CmpItemKindProperty guifg=#61afef ctermfg=75
highlight CmpItemKindUnit guifg=#d19a66 ctermfg=173
highlight CmpItemKindValue guifg=#d19a66 ctermfg=173
highlight CmpItemKindEnum guifg=#d19a66 ctermfg=173
highlight CmpItemKindKeyword guifg=#56b6c2 ctermfg=73
highlight CmpItemKindSnippet guifg=#98c379 ctermfg=114
highlight CmpItemKindColor guifg=#98c379 ctermfg=114
highlight CmpItemKindFile guifg=#98c379 ctermfg=114
highlight CmpItemKindReference guifg=#98c379 ctermfg=114
highlight CmpItemKindFolder guifg=#98c379 ctermfg=114
highlight CmpItemKindEnumMember guifg=#d19a66 ctermfg=173
highlight CmpItemKindConstant guifg=#d19a66 ctermfg=173
highlight CmpItemKindStruct guifg=#e5c07b ctermfg=180
highlight CmpItemKindEvent guifg=#e06c75 ctermfg=168
highlight CmpItemKindOperator guifg=#56b6c2 ctermfg=73
highlight CmpItemKindTypeParameter guifg=#e5c07b ctermfg=180
