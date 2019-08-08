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

closeMobileControls = ($el) ->
  $el
    .closest('.f-c-atoms-previews__controls--active')
    .removeClass('f-c-atoms-previews__controls--active')

handleArrowClick = (e) ->
  e.preventDefault()
  $this = $(this)
  closeMobileControls($this)
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
  window.top.postMessage(data, window.origin)

handleEditClick = (e) ->
  e.preventDefault()
  $this = $(this)
  closeMobileControls($this)
  $wrap = $this.closest('.f-c-atoms-previews__atom')
  data =
    type: 'editAtom'
    rootKey: $wrap.data('root-key')
    index: $wrap.data('index')
  window.top.postMessage(data, window.origin)

handleOverlayClick = (e) ->
  $controls = $(this).closest('.f-c-atoms-previews__controls--active')
  if $controls.length
    e.preventDefault()
    $controls.removeClass('f-c-atoms-previews__controls--active')
  else
    handleEditClick.call(this, e)

handleRemoveClick = (e) ->
  e.preventDefault()
  $this = $(this)
  closeMobileControls($this)
  if window.confirm(window.FolioConsole.translations.removePrompt)
    $wrap = $(this).closest('.f-c-atoms-previews__atom')
    data =
      type: 'removeAtom'
      rootKey: $wrap.data('root-key')
      index: $wrap.data('index')
    window.top.postMessage(data, window.origin)

handleMobileclick = (e) ->
  e.preventDefault()
  e.stopPropagation()
  $(this)
    .closest('.f-c-atoms-previews__controls')
    .addClass('f-c-atoms-previews__controls--active')

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
    $atom = $insert.prev('.f-c-atoms-previews__atom')
    index = $atom.data('index') + 1
  else
    index = $atom.data('index')

  if $atom.length is 0
    $locale = $a.closest('.f-c-atoms-previews__locale')
    rootKey = $locale.data('root-key')
    index = 0
  else
    rootKey = $atom.data('root-key')

  data =
    type: 'newAtom'
    rootKey: rootKey
    index: index
    atomType: $a.data('type')
  window.top.postMessage(data, window.origin)

$(document)
  .on 'click', '.f-c-atoms-previews__button--arrow', handleArrowClick
  .on 'click', '.f-c-atoms-previews__button--edit', handleEditClick
  .on 'click', '.f-c-atoms-previews__controls-overlay', handleOverlayClick
  .on 'click', '.f-c-atoms-previews__button--remove', handleRemoveClick
  .on 'click', '.f-c-atoms-previews__insert-a', handleInsertClick
  .on 'click', '.f-c-atoms-previews__insert-hint', showInsertHint
  .on 'click', '.f-c-atoms-previews__controls-mobile-overlay', handleMobileclick
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
