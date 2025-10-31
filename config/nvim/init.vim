" ~/.config/nvim/init.vim
" modern neovim configuration using vim-plug

" auto-install vim-plug if not present
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" plugin configuration
call plug#begin()

" core neovim enhancements
Plug 'nvim-lua/plenary.nvim'  " required for many lua plugins
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

" lsp and completion
Plug 'williamboman/mason.nvim'
Plug 'williamboman/mason-lspconfig.nvim'
Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'

" snippets
Plug 'L3MON4D3/LuaSnip'
Plug 'saadparwaiz1/cmp_luasnip'


" ui enhancements
Plug 'nvim-lualine/lualine.nvim'
Plug 'nvim-tree/nvim-web-devicons'
Plug 'nvim-tree/nvim-tree.lua'
Plug 'stevearc/aerial.nvim'

" fuzzy finding
Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.5' }
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }

" git integration
Plug 'lewis6991/gitsigns.nvim'
Plug 'tpope/vim-fugitive'

" text manipulation
Plug 'tpope/vim-surround'
Plug 'numToStr/Comment.nvim'
Plug 'windwp/nvim-autopairs'
Plug 'godlygeek/tabular'

" color schemes
Plug 'catppuccin/nvim', { 'as': 'catppuccin' }
Plug 'folke/tokyonight.nvim'
Plug 'EdenEast/nightfox.nvim'
Plug 'rebelot/kanagawa.nvim'
Plug 'rose-pine/neovim', { 'as': 'rose-pine' }
Plug 'sainnhe/gruvbox-material'
Plug 'navarasu/onedark.nvim'
Plug 'Mofiqul/dracula.nvim'
Plug 'nordtheme/vim', { 'as': 'nord' }
Plug 'sainnhe/everforest'
Plug 'shaunsingh/nord.nvim'
Plug 'projekt0n/github-nvim-theme'

" markdown and documentation
Plug 'MeanderingProgrammer/render-markdown.nvim'

call plug#end()

" source additional configuration files
let config_files = [
    \ 'settings.vim',
    \ 'theme.vim',
    \ 'keymaps.vim',
    \ 'plugins.vim'
\]

for file in config_files
    let config_path = stdpath('config') . '/' . file
    if filereadable(config_path)
        execute 'source ' . config_path
    endif
endfor
