if &compatible || (exists('g:loaded_replace') && g:loaded_replace)
  finish
endif
let g:loaded_replace = 1

aug replace
  au!
  au FileType qf com! -buffer -range=%
        \ Replace call replace#ReplaceWithPrompt(<line1>, <line2>)
aug END
