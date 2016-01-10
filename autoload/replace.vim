let s:save_cpo = &cpoptions
set cpoptions&vim

fu! replace#ReplaceWithPrompt(line1, line2) abort
  let old = input("Old word? ")
  let new = input("New word? ")
  call replace#Replace(a:line1, a:line2, old, new)
endfu

fu! replace#Replace(line1, line2, old, new) abort
  call s:replace(a:line1, a:line2, replace#qflisttype(), a:old, a:new)
endfu

" b:qflisttype is relatively new feature to distinguish quickfix from location.
fu! replace#qflisttype() abort
  if exists('b:qflisttype')
    return b:qflisttype
  else
    redir => bufinfo
    silent file
    redir END
    if bufinfo =~# '^.*\[Quickfix List\].*$'
      return 'quickfix'
    elseif bufinfo =~# '^.*\[Location List\].*$' 
      return 'location'
    else
      throw 'The current buffer is neither quickfix-list nor location-list'
    endif
  endif
endfu

fu! s:replace(line1, line2, type, old, new)
  " If ignorecase is set, 'Replace old new' means replacing even 'Old'
  " and 'OLD' with 'new'.
  let _ignorecase = &ignorecase
  set noignorecase
  try
    let files = {}
    if a:type == 'quickfix'
      let list = getqflist()
    elseif a:type == 'location'
      let list = getloclist(0)
    endif
    for d in list[(a:line1 - 1):(a:line2 - 1)]
      " Check if binary or not
      if match(d.text, '\VBinary file') != -1
        continue
      endif
      " Check if the grep result is valid.
      if d.lnum < 1
        throw "An error occurs by executing grep."
      endif
      let bufnr = d.bufnr
      let content = []
      if has_key(files, bufnr)
        let content = files[bufnr]
      elseif bufloaded(bufnr)
        if getbufvar(bufnr, '&modified')
          throw 'At least one buffer is modified.'
        elseif !getbufvar(bufnr, '&modifiable')
          throw 'At least one buffer is not modifiable.'
        elseif !filereadable(bufname(bufnr))
          throw 'At least one buffer is not existing file.'
        endif
        let content = getbufline(bufnr, 1, '$')
      elseif filereadable(bufname(bufnr))
        let content = readfile(bufname(bufnr))
      else
        throw 'At least one buffer does not exist any more.'
      endif
      let line = content[d.lnum - 1]
      if match(d.text, '\V'.substitute(line, '\', '\\\\', 'g')) == -1
        throw 'At least one buffer is changed after grep. Run grep again!'
      endif
      let new_line = substitute(line, a:old, a:new, 'g')
      let content[lnum - 1] = new_line
      let files[bufnr] = content
    endfor
    for [bufnr, content] in items(files)
      silent call writefile(content, bufname(str2nr(bufnr)))
    endfor
    for d in list
      if has_key(files, d.bufnr)
        let d.text = files[d.bufnr][d.lnum - 1]
      endif
    endfor
    if a:type == 'quickfix'
      call setqflist(list)
    elseif a:type == 'location'
      call setloclist(0, list)
    endif
    " NOTE: This leaves no undo history.
    checktime
  finally
    let &ignorecase = _ignorecase
  endtry
endfu

let &cpo = s:save_cpo
unlet s:save_cpo
