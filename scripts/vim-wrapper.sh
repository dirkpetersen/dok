#!/bin/bash
# vim-wrapper.sh - Simple vim wrapper for easy editing
# Starts in insert mode and uses double-escape to save/quit

vim -c "startinsert" \
    -c "let g:esc_pressed = 0" \
    -c "function! SaveAndQuit()
        if &modified
            let choice = confirm('Save changes?', \"&Yes\n&No\n&Cancel\", 1)
            if choice == 1
                wq
            elseif choice == 2
                q!
            endif
        else
            q
        endif
    endfunction" \
    -c "function! HandleEscape()
        if g:esc_pressed
            let g:esc_pressed = 0
            call SaveAndQuit()
        else
            let g:esc_pressed = 1
            call timer_start(500, {-> execute('let g:esc_pressed = 0')})
            return \"\\<Esc>\"
        endif
        return ''
    endfunction" \
    -c "inoremap <expr> <Esc> HandleEscape()" \
    -c "nnoremap <Esc><Esc> :call SaveAndQuit()<CR>" \
    "$@"
