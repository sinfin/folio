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

$(document)
  .on 'click', '.f-c-atoms-previews__button--arrow', handleArrowClick
  .on 'click', '.f-c-atoms-previews__button--edit', handleEditClick
  .on 'click', '.f-c-atoms-previews__button--remove', handleRemoveClick
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
