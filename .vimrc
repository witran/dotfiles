call plug#begin('~/.vim/plugged')
Plug 'fatih/vim-go', { 'do': 'vim +GoInstallBinaries +qall' }
Plug 'scrooloose/syntastic'
Plug 'ternjs/tern_for_vim', { 'do': 'npm install' }
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
call plug#end()
