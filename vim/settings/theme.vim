" syntax hl
syntax on

" better color map for syntax hl
set background=dark

" use 256 colors when possible
if &term =~? 'mlterm\|xterm\|xterm-256\|screen-256'
    let &t_Co = 256
    colorscheme spacegray
    set termguicolors
    let g:spacegray_underline_search = 1
    let g:spacegray_italicize_comments = 1
    set guifont=Sauce\ Code\ Pro\ Medium\ Nerd\ Font\ Complete\ 14
    set encoding=utf-8
else
    colorscheme gruvbox
endif
