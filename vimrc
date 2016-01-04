" vim {{{
" vim:foldmethod=marker:foldlevel=0
set nocompatible
" }}}
" vundle {{{
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'
Plugin 'scrooloose/syntastic'
Plugin 'jelera/vim-javascript-syntax'
Plugin 'Raimondi/delimitMate'
" Plugin 'bling/vim-airline'
Plugin 'tpope/vim-commentary'
Plugin 'airblade/vim-gitgutter'
call vundle#end()
filetype plugin indent on
" plugin settings
let delimitMate_expand_cr = 1
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
let g:syntastic_python_checkers = ['flake8']
let g:syntastic_javascript_checkers = ['eslint']
" let g:airline_powerline_fonts = 1
" let g:airline#extensions#tabline#enabled = 1
" let g:airline_theme = 'zenburn'
let python_highlight_all = 1
" }}}
" system {{{
set hidden              " hide files with unsaved changes
set history=1000        " keep 1000 lines of command history
set undolevels=1000     " more undo
set mouse=a             " use mouse in visual mode
set confirm             " get a dialog when :q, :w, or :wq fails
set nobackup            " no backup~ files.
set noswapfile          " use git
set undofile            " keep undo history after quitting
set undodir=~/.vim/undo " store undo files in ~/.vim/undo
set autochdir           " cd to the directory fo file
" }}}
" editor {{{
set backspace=indent,eol,start " allow backspacing
set pastetoggle=<F2>    " F2 to enable paste
" }}}
" colors {{{
set t_Co=256
syntax enable           " enable syntax highlighting
set background=dark     " enable for dark terminals
colorscheme solarized   " precision colors for machines and people
" }}}
" spaces & tabs {{{
set tabstop=4           " spaces per tab
set softtabstop=4       " spaces per tab when editing
set expandtab           " tabs are spaces
set shiftwidth=4        " number of spaces for autoindenting
set shiftround          " use multiple of shiftwidth when indenting with '<' and '>'
" }}}
" visual {{{
set number              " show line numbers
set cursorline          " highlight current line
set lazyredraw          " no redraw during macros
set scrolloff=2         " 2 lines above/below cursor when scrolling
" status line
set showmode            " mode
set showcmd             " command
set ruler               " cursor position
" show matching bracket for 0.2 seconds
set showmatch
set matchtime=2
" completion menu
set wildmenu
set wildignore=*.o,*.obj,*.bak,*.exe,*.py[co],*.swp,*~,*.pyc,.svn
" highlight trailing whitespace
set list
set listchars=tab:>.,trail:.,extends:#,nbsp:.
" don't beep
set visualbell
set noerrorbells
" }}}
" searching {{{
set incsearch           " show search matches as you type
set hlsearch            " highlight search terms
set ignorecase          " case insensitive searching
set smartcase           " but become case sensitive if you type uppercase characters
set magic               " change the way backslashes are used in search patterns
" }}}
" folding {{{
set foldenable         " enable folding
set foldlevelstart=10  " open some folds by default
set foldnestmax=10     " nested fold max
set foldmethod=indent  " fold on indent
" open/close folds
nnoremap <space> za
" }}}
" movement {{{
" visual lines
nnoremap j gj
nnoremap k gk
" beginning/end of line
nnoremap B ^
nnoremap E $
nnoremap ^ B
nnoremap $ E
" highlight last inserted text
nnoremap gV `[v`]
" }}}
" leader shortcuts {{{
let mapleader=","
" edit/reload the vimrc file
nmap <silent> <leader>, :tabe $MYVIMRC<CR>
nmap <silent> <leader>sv :source $MYVIMRC<CR>
" toggle comment
map <silent> <leader>/ gcc
" enclosure mappings
nnoremap <silent> <leader>' f'ci'
nnoremap <silent> <leader>" f"ci"
nnoremap <silent> <leader>( f(ci(
nnoremap <silent> <leader>) f)ci)
nnoremap <silent> <leader>[ f[ci[
nnoremap <silent> <leader>] f]ci]
" toggle line numbers
nmap <silent> <leader>n :call ToggleNumber()<CR>
" clear search highlights
nnoremap <silent> <leader>. :nohlsearch<CR>
" syntastic toggle
nmap <silent> <leader>m :lclose<CR>
" }}}
" mappings {{{
nnoremap ; :
" save file
noremap <C-s> :update<CR>
inoremap <C-s> <C-o>:update<CR>
vnoremap <C-s> <C-c>:update<CR>
" copy/paste
noremap <C-c> ddkp
inoremap <C-c> <C-o>dd<C-o>k<C-o>p
vnoremap <C-c> <C-c>dd<C-c>k<C-c>p
noremap <C-p> p
inoremap <C-p> <C-o>p
vnoremap <C-p> <C-c>p
" tabs
map <C-Left> <Esc>:tabprev<CR>
map <C-Right> <Esc>:tabnext<CR>
map <C-Up> <Esc>:tabe<Space>
" windows
map <C-h> <C-w>h
map <C-j> <C-w>j
map <C-k> <C-w>k
map <C-l> <C-w>l
" cr expand
inoremap <C-x> <CR><C-o>k<C-o>o
" auto indent on paste
nnoremap p p=`]<C-o>
nnoremap P P=`]<C-o>
" post factum sudo vim
cmap w!! w !sudo tee % >/dev/null
" }}}
" autogroups {{{
augroup vimrc
    autocmd filetype html,xml set listchars-=tab:>. smartindent smarttab softtabstop=4 shiftwidth=4 expandtab
    autocmd filetype javascript set smartindent smarttab softtabstop=4 shiftwidth=4 expandtab
    autocmd filetype javascript nmap <silent> <leader>l oconsole.log();<Esc>F(a
augroup END
" }}}
" functions {{{
" toggle between actual and relative line numbers
function! ToggleNumber()
    if(&relativenumber == 1)
        set norelativenumber
        set number
    else
        set relativenumber
    endif
endfunction
" }}}
" about {{{
" vimrc
" Brandon Freitag, 2015
" Ideas borrowed from 'A Good Vimrc' by Doug Black
" http://dougblack.io/words/a-good-vimrc.html#colors
" }}}
