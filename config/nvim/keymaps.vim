" ~/.config/nvim/keymaps.vim
" key mappings and shortcuts

" leader key
let mapleader = " "
let maplocalleader = ","

" general mappings
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>x :x<CR>

" window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" buffer navigation
nnoremap <leader>bn :bnext<CR>
nnoremap <leader>bp :bprev<CR>
nnoremap <leader>bd :bdelete<CR>

" tab navigation
nnoremap <leader>tn :tabnew<CR>
nnoremap <leader>tc :tabclose<CR>
nnoremap <leader>tm :tabmove<CR>

" search and replace
nnoremap <leader>h :nohlsearch<CR>
nnoremap <leader>r :%s//g<Left><Left>
vnoremap <leader>r :s//g<Left><Left>

" file operations
nnoremap <leader>e :edit<Space>
nnoremap <leader>s :split<Space>
nnoremap <leader>v :vsplit<Space>

" toggle features
nnoremap <leader>n :set number!<CR>
nnoremap <leader>l :set list!<CR>
nnoremap <leader>p :set paste!<CR>

" plugin-specific mappings
" nvim-tree
nnoremap <leader>t :NvimTreeToggle<CR>
nnoremap <leader>f :NvimTreeFindFile<CR>

" aerial (symbol outline)
nnoremap <F8> :AerialToggle<CR>

" telescope
nnoremap <leader><leader> :Telescope find_files<CR>
nnoremap <leader>b :Telescope buffers<CR>
nnoremap <leader>g :Telescope live_grep<CR>
nnoremap <leader>m :Telescope marks<CR>
nnoremap <leader>/ :Telescope current_buffer_fuzzy_find<CR>
nnoremap <leader>: :Telescope command_history<CR>
nnoremap <leader>? :Telescope search_history<CR>

" telescope git integration
nnoremap <leader>gf :Telescope git_files<CR>
nnoremap <leader>gb :Telescope git_branches<CR>
nnoremap <leader>gt :Telescope git_status<CR>
nnoremap <leader>gh :Telescope git_commits<CR>

" telescope lsp integration
nnoremap <leader>lr :Telescope lsp_references<CR>
nnoremap <leader>ls :Telescope lsp_document_symbols<CR>
nnoremap <leader>lw :Telescope lsp_workspace_symbols<CR>
nnoremap <leader>ld :Telescope diagnostics<CR>

" git (fugitive)
nnoremap <leader>gs :Git status<CR>
nnoremap <leader>gc :Git commit<CR>
nnoremap <leader>gp :Git push<CR>
nnoremap <leader>gl :Git log<CR>

" terminal mode mappings
if has('nvim')
    tnoremap <leader><Esc> <C-\><C-n>
endif


" gitsigns navigation
nnoremap <leader>hn :lua require('gitsigns').next_hunk()<CR>
nnoremap <leader>hp :lua require('gitsigns').prev_hunk()<CR>
nnoremap <leader>hs :lua require('gitsigns').stage_hunk()<CR>
nnoremap <leader>hr :lua require('gitsigns').reset_hunk()<CR>
nnoremap <leader>hS :lua require('gitsigns').stage_buffer()<CR>
nnoremap <leader>hR :lua require('gitsigns').reset_buffer()<CR>
nnoremap <leader>hu :lua require('gitsigns').undo_stage_hunk()<CR>
nnoremap <leader>hd :lua require('gitsigns').preview_hunk()<CR>
nnoremap <leader>hb :lua require('gitsigns').blame_line{full=true}<CR>
nnoremap <leader>htb :lua require('gitsigns').toggle_current_line_blame()<CR>
nnoremap <leader>htd :lua require('gitsigns').toggle_deleted()<CR>

" luasnip navigation
inoremap <silent> <C-k> <cmd>lua require('luasnip').expand_or_jump()<CR>
inoremap <silent> <C-j> <cmd>lua require('luasnip').jump(-1)<CR>
snoremap <silent> <C-k> <cmd>lua require('luasnip').expand_or_jump()<CR>
snoremap <silent> <C-j> <cmd>lua require('luasnip').jump(-1)<CR>

" disable arrow keys in normal mode (for good habits)
nnoremap <Up> <Nop>
nnoremap <Down> <Nop>
nnoremap <Left> <Nop>
nnoremap <Right> <Nop>

" make y behave like c and d
nnoremap Y y$

" center search results
nnoremap n nzz
nnoremap N Nzz