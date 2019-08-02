#= require jquery
#= require folio/lazyload

lazyloadAll = ->
  window.folioLazyloadInstances.forEach (instance) ->
    instance.update()
    instance.loadAll()

selectLocale = (locale) ->
  $('.f-c-atoms-previews__locale').each ->
    $this = $(this)
    $this.prop('hidden', $this.data('locale') isnt locale)

handleArrowClick = (e) ->
  e.preventDefault()
  $this = $(this)
  $wrap = $this.closest('.f-c-atoms-previews__atom')
  index = $wrap.data('index')
  if $this.hasClass('f-c-atoms-previews__button--arrow-up')
    return if $wrap.is(':first-child')
    targetIndex = index - 1
  else
    return if $wrap.is(':last-child')
    targetIndex = index + 1
  data =
    type: 'moveAtomToIndex'
    rootKey: $wrap.data('root-key')
    index: index
    targetIndex: targetIndex
  window.parent.postMessage(data, window.origin)

handleEditClick = (e) ->
  e.preventDefault()
  $wrap = $(this).closest('.f-c-atoms-previews__atom')
  data =
    type: 'editAtom'
    rootKey: $wrap.data('root-key')
    index: $wrap.data('index')
  window.parent.postMessage(data, window.origin)

handleRemoveClick = (e) ->
  e.preventDefault()
  if window.confirm(window.FolioConsole.translations.removePrompt)
    $wrap = $(this).closest('.f-c-atoms-previews__atom')
    data =
      type: 'removeAtom'
      rootKey: $wrap.data('root-key')
      index: $wrap.data('index')
    window.parent.postMessage(data, window.origin)

showInsertHint = (e) ->
  e.preventDefault()
  $(this)
    .closest('.f-c-atoms-previews__insert')
    .addClass('f-c-atoms-previews__insert--active')

hideInsertHint = (e) ->
  e.preventDefault()
  $(this)
    .removeClass('f-c-atoms-previews__insert--active')

handleInsertClick = (e) ->
  e.preventDefault()
  $a = $(this)
  $insert = $a.closest('.f-c-atoms-previews__insert')
  $insert.removeClass('f-c-atoms-previews__insert--active')
  $atom = $insert.next('.f-c-atoms-previews__atom')
  if $atom.length is 0
    $atom = $insert.before('.f-c-atoms-previews__atom')
    index = $atom.data('index') + 1
  else
    index = $atom.data('index')
  data =
    type: 'newAtom'
    rootKey: $atom.data('root-key')
    index: index
    atomType: $a.data('type')
  window.parent.postMessage(data, window.origin)

$(document)
  .on 'click', '.f-c-atoms-previews__button--arrow', handleArrowClick
  .on 'click', '.f-c-atoms-previews__button--edit', handleEditClick
  .on 'click', '.f-c-atoms-previews__button--remove', handleRemoveClick
  .on 'click', '.f-c-atoms-previews__insert-a', handleInsertClick
  .on 'click', '.f-c-atoms-previews__insert-hint-btn', showInsertHint
  .on 'mouseleave', '.f-c-atoms-previews__insert', hideInsertHint
  .on 'click', 'a, button', (e) -> e.preventDefault()
  .on 'form', 'submit', (e) -> e.preventDefault()

receiveMessage = (e) ->
  return if e.origin isnt window.origin
  switch e.data.type
    when 'replacedHtml' then lazyloadAll()
    when 'selectLocale' then selectLocale(e.data.locale)

window.addEventListener('message', receiveMessage, false)

$ ->
  lazyloadAll()
