" ~/.vimrc

" settings dir
let s:vimDir = '~/.vim/settings/'

" config list
let configs = [
  \ 'vundle.vim',
  \ 'main.vim',
  \ 'theme.vim',
  \ 'plugin_settings.vim'
\]

" source config files
for files in configs
    for f in split(glob(s:vimDir.files), '\n')
        exec 'source '.f
    endfor
endfor
