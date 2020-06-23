" Copied from 
" https://github.com/plasticboy/vim-markdown/blob/master/ftplugin/markdown.vim

function! s:Toc(...)
    if a:0 > 0
        let l:window_type = a:1
    else
        let l:window_type = 'vertical'
    endif


    let l:bufnr = bufnr('%')
    let l:cursor_line = line('.')
    let l:cursor_header = 0
    let l:fenced_block = 0
    let l:front_matter = 0
    let l:header_list = []
    let l:header_max_len = 0
    let l:vim_markdown_toc_autofit = get(g:, "vim_markdown_toc_autofit", 0)
    let l:vim_markdown_frontmatter = get(g:, "vim_markdown_frontmatter", 0)
    for i in range(1, line('$'))
        let l:lineraw = getline(i)
        let l:l1 = getline(i+1)
        let l:line = substitute(l:lineraw, "#", "\\\#", "g")
        if l:line =~ '````*' || l:line =~ '\~\~\~\~*'
            if l:fenced_block == 0
                let l:fenced_block = 1
            elseif l:fenced_block == 1
                let l:fenced_block = 0
            endif
        elseif l:vim_markdown_frontmatter == 1
            if l:front_matter == 1
                if l:line == '---'
                    let l:front_matter = 0
                endif
            elseif i == 1
                if l:line == '---'
                    let l:front_matter = 1
                endif
            endif
        endif
        if l:line =~ '^#\+' || (l:l1 =~ '^=\+\s*$' || l:l1 =~ '^-\+\s*$') && l:line =~ '^\S'
            let l:is_header = 1
        else
            let l:is_header = 0
        endif
        if l:is_header == 1 && l:fenced_block == 0 && l:front_matter == 0
            " append line to location list
            let l:item = {'lnum': i, 'text': l:line, 'valid': 1, 'bufnr': l:bufnr, 'col': 1}
            let l:header_list = l:header_list + [l:item]
            " set header number of the cursor position
            if l:cursor_header == 0
                if i == l:cursor_line
                    let l:cursor_header = len(l:header_list)
                elseif i > l:cursor_line
                    let l:cursor_header = len(l:header_list) - 1
                endif
            endif
            " keep track of the longest header size (heading level + title)
            let l:total_len = stridx(l:line, ' ') + strdisplaywidth(l:line)
            if l:total_len > l:header_max_len
                let l:header_max_len = l:total_len
            endif
        endif
    endfor
    call setloclist(0, l:header_list)
    if len(l:header_list) == 0
        echom "Toc: No headers."
        return
    endif

    if l:window_type ==# 'horizontal'
        lopen
    elseif l:window_type ==# 'vertical'
        vertical lopen
        " auto-fit toc window when possible to shrink it
        if (&columns/2) > l:header_max_len && l:vim_markdown_toc_autofit == 1
            execute 'vertical resize ' . (l:header_max_len + 1)
        else
            execute 'vertical resize ' . (&columns/2)
        endif
    elseif l:window_type ==# 'tab'
        tab lopen
    else
        lopen
    endif
    setlocal modifiable
    for i in range(1, line('$'))
        " this is the location-list data for the current item
        let d = getloclist(0)[i-1]
        " atx headers
        if match(d.text, "^#") > -1
            let l:level = len(matchstr(d.text, '#*', 'g'))-1
            let d.text = substitute(d.text, '\v^#*[ ]*', '', '')
            let d.text = substitute(d.text, '\v[ ]*#*$', '', '')
        " setex headers
        else
            let l:next_line = getbufline(d.bufnr, d.lnum+1)
            if match(l:next_line, "=") > -1
                let l:level = 0
            elseif match(l:next_line, "-") > -1
                let l:level = 1
            endif
        endif
        call setline(i, repeat('  ', l:level). d.text)
    endfor
    setlocal nomodified
    setlocal nomodifiable
    execute 'normal! ' . l:cursor_header . 'G'
endfunction
command! -buffer Toc call s:Toc()
command! -buffer Toch call s:Toc('horizontal')
command! -buffer Tocv call s:Toc('vertical')
command! -buffer Toct call s:Toc('tab')


" To reload :source ~/.vimrc
