" require iMproved & disable filetypes
set nocompatible | filetype off

" set runtime path & call initialization function
set rtp+=~/.vim/bundle/Vundle.vim | call vundle#begin()

" plugins
Plugin 'gmarik/Vundle.vim'
Plugin 'scrooloose/syntastic'
Plugin 'SirVer/ultisnips'
Plugin 'majutsushi/tagbar'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'tpope/vim-surround'
Plugin 'hynek/vim-python-pep8-indent'
" Plugin 'Valloric/YouCompleteMe'
Plugin 'xolox/vim-misc'
Plugin 'chriskempson/base16-vim'
Plugin 'junegunn/fzf'
Plugin 'junegunn/fzf.vim'
Plugin 'godlygeek/tabular'
Plugin 'plasticboy/vim-markdown'

" Color schemes
Plugin 'ajh17/Spacegray.vim'

" call end function & enable filetypes
call vundle#end() | filetype plugin indent on
