call vim_xai_config#load()

let s:plugin_root = expand('<sfile>:p:h:h')
let s:vim_xai_maxlines = 10000
let s:vim_xai_test = s:plugin_root . "/perl/test.pl"
let s:vim_xai_args = ""

function! vim_xai#Testi(...)
    if g:vim_xai_is_selection_pending == 0
        " echo "Nothing selected."
    endif

    let s:vim_xai_args = join(a:000, '')
    let l:selection = s:GetVisualSelection()

    " Read perl script in and execute.
    let l:output = ""
    for l:line in readfile(s:vim_xai_test, '', s:vim_xai_maxlines)
        let l:output .= l:line . "\n"
    endfor

    execute "perl " . output
endfunction

function! s:GetVisualSelection()
    let [line_start, column_start] = getpos("'<")[1:2]
    let [line_end, column_end] = getpos("'>")[1:2]
    let lines = getline(line_start, line_end)

    if len(lines) == 0
        return ''
    endif

    " The exclusive mode means that the last character of the selection 
    " area is not included in the operation scope.
    let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
    let lines[0] = lines[0][column_start - 1:]
    return join(lines, "\n")
endfunction
