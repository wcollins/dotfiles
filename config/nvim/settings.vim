" ~/.config/nvim/settings.vim

" general settings
set nocompatible
filetype plugin indent on
syntax enable

" editor appearance
set number
set norelativenumber
set cursorline
set colorcolumn=
set showmatch
set laststatus=2
set showcmd
set wildmenu
set wildmode=list:longest,full

" indentation and formatting
set autoindent
set smartindent
set expandtab
set shiftwidth=4
set tabstop=4
set softtabstop=4
set smarttab

" search settings
set incsearch
set hlsearch
set ignorecase
set smartcase

" file handling
set autoread
set autowrite
set hidden
set backup
set backupdir=~/.cache/nvim/backup//
set directory=~/.cache/nvim/swap//
set undofile
set undodir=~/.cache/nvim/undo//

" create backup directories if they don't exist
if !isdirectory($HOME.'/.cache/nvim/backup')
    call mkdir($HOME.'/.cache/nvim/backup', 'p', 0700)
endif
if !isdirectory($HOME.'/.cache/nvim/swap')
    call mkdir($HOME.'/.cache/nvim/swap', 'p', 0700)
endif
if !isdirectory($HOME.'/.cache/nvim/undo')
    call mkdir($HOME.'/.cache/nvim/undo', 'p', 0700)
endif

" performance
set updatetime=300
set timeoutlen=500
set ttimeoutlen=0
set lazyredraw

" mouse and clipboard
if has('mouse')
    set mouse=a
endif
if has('clipboard')
    set clipboard=unnamed,unnamedplus
endif

" folding
set foldmethod=indent
set foldlevel=99
set nofoldenable

" completion (optimized for nvim-cmp)
set completeopt=menu,menuone,noselect,noinsert
set pumheight=15
set shortmess+=c

" modern neovim-specific settings
if has('nvim-0.8')
    " enable global statusline
    set laststatus=3
    
    " enable winblend for floating windows
    set winblend=10
    set pumblend=10
endif

" lsp and diagnostic settings
set signcolumn=yes:2
set updatetime=100

" terminal settings
if has('nvim')
    set inccommand=split
    tnoremap <Esc> <C-\><C-n>
endif

" modern neovim features
if has('nvim-0.9')
    " enable treesitter-based folding
    set foldmethod=expr
    set foldexpr=nvim_treesitter#foldexpr()
    set foldtext=substitute(getline(v:foldstart),'\\t',repeat('\ ',&tabstop),'g').'...'.trim(getline(v:foldend))
endif

" improved diff settings
set diffopt=internal,filler,closeoff,hiddenoff,algorithm:patience

" better splitting
set splitbelow
set splitright

" disable providers we don't need for performance
let g:loaded_python_provider = 0
let g:loaded_ruby_provider = 0
let g:loaded_perl_provider = 0
let g:loaded_node_provider = 0

" disable some built-in plugins for faster startup
let g:loaded_gzip = 1
let g:loaded_zip = 1
let g:loaded_zipPlugin = 1
let g:loaded_tar = 1
let g:loaded_tarPlugin = 1
let g:loaded_getscript = 1
let g:loaded_getscriptPlugin = 1
let g:loaded_vimball = 1
let g:loaded_vimballPlugin = 1
let g:loaded_2html_plugin = 1
let g:loaded_logipat = 1
let g:loaded_rrhelper = 1
let g:loaded_spellfile_plugin = 1
let g:loaded_matchit = 1

" treesitter-aware navigation
if has('nvim-0.8')
    lua << EOF
    -- configure diagnostic display
    vim.diagnostic.config({
      virtual_text = {
        prefix = '●',
        source = 'if_many',
      },
      float = {
        source = 'always',
        border = 'rounded',
      },
      signs = true,
      underline = true,
      update_in_insert = false,
      severity_sort = true,
    })

    -- configure lsp handlers
    vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, {
      border = 'rounded',
    })

    vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(vim.lsp.handlers.signature_help, {
      border = 'rounded',
    })

    -- set up some globals for better lua development
    vim.g.mapleader = ' '
    vim.g.maplocalleader = ','
EOF
endif
