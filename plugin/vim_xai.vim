if !has('perl')
    echoerr "Perl support is required for vim-xai plugin"
    finish
endif

let g:vim_xai_is_selection_pending = 0
augroup vim_xai
    autocmd!
        autocmd CursorMoved *
            \ let g:vim_xai_is_selection_pending = mode() =~# "^[vV\<C-v>]"
augroup END

command! -range   -nargs=?            Xai    call vim_xai#Testi(<q-args>)
