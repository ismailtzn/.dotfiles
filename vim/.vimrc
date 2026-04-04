if v:version < 802
    packadd! dracula
endif
syntax enable

" Colorscheme: prefer catppuccin_mocha, fall back silently if not installed
silent! colorscheme catppuccin_mocha
set nu rnu
set termguicolors


