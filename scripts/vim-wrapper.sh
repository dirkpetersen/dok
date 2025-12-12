#!/bin/bash
# vim-wrapper.sh - Simple vim wrapper for easy editing
# Starts in insert mode and uses double-escape to save/quit

EDRRC="$HOME/.edrrc"

# Create or update ~/.edrrc if needed
create_edrrc() {
    cat > "$EDRRC" << 'VIMRC'
" Easy editor config - starts in insert mode, double-escape to save/quit
set nomore
set nocompatible
set t_u7=

let g:esc_pressed = 0

function! SaveAndQuit()
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
endfunction

function! HandleEscape()
    if g:esc_pressed
        let g:esc_pressed = 0
        call SaveAndQuit()
    else
        let g:esc_pressed = 1
        if has('timers')
            call timer_start(500, {-> execute('let g:esc_pressed = 0')})
        endif
        return "\<Esc>"
    endif
    return ''
endfunction

inoremap <expr> <Esc> HandleEscape()
nnoremap <Esc><Esc> :call SaveAndQuit()<CR>

" Start in insert mode after vim fully loads
autocmd VimEnter * startinsert
VIMRC
}

# Check if edrrc needs to be created or updated
SCRIPT_VERSION="v2"
if [[ ! -f "$EDRRC" ]] || ! grep -q "Easy editor config" "$EDRRC" 2>/dev/null; then
    create_edrrc
fi

# Run vim with our custom config
# -N = nocompatible, -n = no swap file, -u = use our rc file
vim -N -n -u "$EDRRC" "$@"
