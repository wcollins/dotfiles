" utf-8 encoding by default
set enc=utf-8

" lines
set number | set cursorline | set cursorcolumn

" no sounds
set visualbell

" no word wrap
set nowrap

" always show status bar
set ls=2

" 3 line screen border
set scrolloff=3

" turn off swap files
set noswapfile | set nobackup | set nowb

" searching
set hlsearch | set incsearch

" autocomplete files & commands
set wildmode=list:longest

" tab navigation
nnoremap th  :tabfirst<CR>
nnoremap tk  :tabnext<CR>
nnoremap tj  :tabprev<CR>
nnoremap tl  :tablast<CR>
nnoremap tt  :tabedit<Space>
nnoremap tn  :tabnext<Space>
nnoremap tm  :tabm<Space>
nnoremap td  :tabclose<CR>
