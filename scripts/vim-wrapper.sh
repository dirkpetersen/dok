#!/bin/bash
# vim-wrapper.sh - Simple vim wrapper for easy editing
# Starts in insert mode and uses double-escape to save/quit

EDRRC="$HOME/.edrrc"
WRAPPER_PATH="${BASH_SOURCE[0]:-$0}"

# Create or update ~/.edrrc if needed
create_edrrc() {
    cat > "$EDRRC" << 'VIMRC'
" Easy editor config - starts in insert mode, double-escape to save/quit
" Version: 4
set nomore
set nocompatible
set t_u7=
set t_RV=
set esckeys
set ttimeoutlen=50

" Arrow key mappings for insert mode (needed when using -u)
inoremap <Esc>[A <Up>
inoremap <Esc>[B <Down>
inoremap <Esc>[C <Right>
inoremap <Esc>[D <Left>
inoremap <Esc>OA <Up>
inoremap <Esc>OB <Down>
inoremap <Esc>OC <Right>
inoremap <Esc>OD <Left>

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
            call EnterInsertMode(0)
        endif
    else
        q
    endif
endfunction

function! ResetEscPressed(timer)
    let g:esc_pressed = 0
endfunction

function! HandleEscape()
    if g:esc_pressed
        let g:esc_pressed = 0
        call SaveAndQuit()
    else
        let g:esc_pressed = 1
        if has('timers')
            call timer_start(500, 'ResetEscPressed')
        endif
        return "\<Esc>"
    endif
    return ''
endfunction

function! EnterInsertMode(timer)
    if mode() !=# 'i'
        call feedkeys('i', 'n')
    endif
endfunction

inoremap <expr> <Esc> HandleEscape()
nnoremap <Esc><Esc> :call SaveAndQuit()<CR>

" Start in insert mode - use timer for reliability if available
if has('timers')
    autocmd VimEnter * call timer_start(50, 'EnterInsertMode')
else
    autocmd VimEnter * call feedkeys('i', 'n')
endif
VIMRC
}

# Check if edrrc needs to be created or updated
# Recreate if: doesn't exist, doesn't have marker, or wrapper is newer
if [[ ! -f "$EDRRC" ]]; then
    create_edrrc
elif ! grep -q "Easy editor config" "$EDRRC" 2>/dev/null; then
    create_edrrc
elif [[ -f "$WRAPPER_PATH" ]] && [[ "$WRAPPER_PATH" -nt "$EDRRC" ]]; then
    create_edrrc
fi

# Run vim with our custom config
# -N = nocompatible, -n = no swap file, -u = use our rc file
vim -N -n -u "$EDRRC" "$@"
