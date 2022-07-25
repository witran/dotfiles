if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source ~/.vimrc
endif

call plug#begin('~/.vim/plugged')
" Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
" Plug 'fatih/vim-go', { 'do': 'vim +GoInstallBinaries +qall' }
" Plug 'hdima/python-syntax'
" Plug 'elixir-editors/vim-elixir'
" Plug 'ternjs/tern_for_vim', { 'do': 'npm install' }
" Plug 'mhartington/oceanic-next'
" Plug 'jelera/vim-javascript-syntax'
" Plug 'prettier/vim-prettier', {
"   \ 'do': 'npm install',
"  \ 'for': ['javascript', 'typescript', 'css', 'less', 'scss', 'json', 'graphql', 'markdown', 'vue'] }
Plug 'scrooloose/syntastic'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'terryma/vim-multiple-cursors'
Plug 'Townk/vim-autoclose'
Plug 'joshdick/onedark.vim'
Plug 'flazz/vim-colorschemes'
Plug 'tomasiser/vim-code-dark'
Plug 'chriskempson/base16-vim'
Plug 'Yggdroot/indentLine'
call plug#end()

map <up> <nop>
map <down> <nop>
map <left> <nop>
map <right> <nop>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Search
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Set search case insensitive for lowercase,
" case sensitive if contains uppercase
set ignorecase
set smartcase

" inc buffers
set history=1000
set undolevels=1000

set wildignore=*.swp,*.bak,*.pyc,*.class

" change the terminal's title
set title

" don't beep
set visualbell
set noerrorbells

set hlsearch
" Ignore case of searches
set ignorecase
" Highlight dynamically as pattern is typed
set incsearch
" Always show status line
set laststatus=2

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Colors and Fonts
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Enable syntax highlighting
syntax enable

" Enable 256 colors palette in Gnome Terminal
if $COLORTERM == 'gnome-terminal'
    set t_Co=256
endif

" Set extra options when running in GUI mode
if has("gui_running")
    set guioptions-=T
    set guioptions-=e
    set t_Co=256
    set guitablabel=%M\ %t
endif

" color
set background=dark
colo onedark
"colorscheme OceanicNext
"colorscheme codedark
"colorscheme base16-eighties
"set background=light
"colorscheme breezy
let python_highlight_all = 1

" Set utf8 as standard encoding and en_US as the standard language
set encoding=utf8

" Use Unix as the standard file type
set ffs=unix,dos,mac

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Files, backups and undo
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Turn backup off, since most stuff is in SVN, git et.c anyway...
set nobackup
set nowb
set noswapfile


" Yank to OS X clipboard
set clipboard=unnamed


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => Text, tab and indent related
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Use spaces instead of tabs
set expandtab

" Be smart when using tabs ;)
set smarttab

" 1 tab == 2 spaces
set shiftwidth=2
set tabstop=2

" Linebreak on 500 characters
set lbr
set tw=500

set ai "Auto indent
set si "Smart indent
set wrap "Wrap lines

set number "Ruler"

" NERDTree
let mapleader = ","
nmap <leader>ne :NERDTreeToggle<cr>
