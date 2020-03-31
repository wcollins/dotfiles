" =====================
" FZF =================
" =====================
let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }

" Default fzf layout
" - down / up / left / right
let g:fzf_layout = { 'down': '~40%' }

" Change default trigger
nnoremap <silent> <C-p> :FZF<CR>


" ======================
" vim-airline ==========
" ======================
"
" let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1
let g:airline_theme = 'hybrid'
let g:hybrid_custom_term_colors = 1
let g:hybrid_reduced_contrast = 1


" ====================
" UltiSnips ==========
" ====================

" use tab for snippets
let g:UltiSnipsExpandTrigger="<Tab>"
let g:UltiSnipsJumpForwardTrigger="<Tab>"
let g:UltiSnipsJumpBackwardTrigger="<q-Tab>"
let g:UltiSnipsSnippetsDir = '~/.vim/snips/'
let g:UltiSnipsSnippetDirectories = ['UltiSnips', 'snips']

" ====================
" Tagbar =============
" ====================

" toggle display
nmap ,b :TagbarToggle<CR>

" Autofocus when opened
let g:tagbar_autofocus = 1

" ====================
" YouCompleteMe ======
" ====================

" use ctrl for completion
let g:ycm_key_list_select_completion=['<C-j>', '<Down>']
let g:ycm_key_list_previous_completion=['<C-k>', '<Up>']

" ====================
" Syntastic ==========
" ====================

" use flake8 for style & error checking
let g:syntastic_python_checkers = ['flake8']

" check upon launching file
let g:syntastic_check_on_open = 1

" no icons on sign column
let g:syntastic_enable_signs = 0

" show list of errors & warnings on current file
nmap <leader>e :Errors<CR>

" ignore these errors
let g:syntastic_python_flake8_args = '--ignore="F401,F811,E501,F841"'
