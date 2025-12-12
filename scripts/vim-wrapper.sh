#!/bin/bash
# vim-wrapper.sh - Simple vim wrapper for easy editing
# Starts in insert mode and uses double-escape to save/quit

# Check vim version for timer support (vim 8.0+)
vim_version=$(vim --version 2>/dev/null | head -1 | grep -oP '\d+\.\d+' | head -1)
vim_major=$(echo "$vim_version" | cut -d. -f1)

if [[ "$vim_major" -ge 8 ]]; then
    # Vim 8+ with timer support
    vim -c "set nomore" \
        -c "set t_u7=" \
        -c "let g:esc_pressed = 0" \
        -c "function! SaveAndQuit()
            stopinsert
            if &modified
                echohl Question | echo 'Save changes? (y/n/c): ' | echohl None
                let c = nr2char(getchar())
                if c ==? 'y'
                    silent! wq
                elseif c ==? 'n'
                    q!
                else
                    startinsert
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
        -c "autocmd VimEnter * startinsert" \
        "$@"
else
    # Vim 7.x fallback without timer (uses simple double-escape in normal mode)
    vim -c "set nomore" \
        -c "set t_u7=" \
        -c "function! SaveAndQuit()
            stopinsert
            if &modified
                echohl Question | echo 'Save changes? (y/n/c): ' | echohl None
                let c = nr2char(getchar())
                if c ==? 'y'
                    silent! wq
                elseif c ==? 'n'
                    q!
                else
                    startinsert
                endif
            else
                q
            endif
        endfunction" \
        -c "nnoremap <Esc><Esc> :call SaveAndQuit()<CR>" \
        -c "autocmd VimEnter * startinsert" \
        "$@"
fi
