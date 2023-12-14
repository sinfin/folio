# see app/cells/folio/console/atoms/previews/previews.coffee
# code is here as it would get included by a wildcard import

#= require folio/stimulus

#= require jquery
#= require jquery-ui/jquery-ui
#= require justified-layout
#= require folio/atoms
#= require folio/message_bus
#= require folio/lazyload
#= require folio/debounce
#= require folio/lightbox
#= require folio/console/atoms/previews/main_app
#= require folio/console/file/preview_reloader/preview_reloader

lazyloadAll = ->
  window.folioLazyloadInstances.forEach (instance) ->
    instance.update()
    instance.loadAll()

selectLocale = (locale) ->
  $('.f-c-atoms-previews__locale').each ->
    $this = $(this)
    $this.prop('hidden', $this.data('locale') and $this.data('locale') isnt locale)

closeMobileControls = ($el) ->
  $el
    .closest('.f-c-atoms-previews__controls--active')
    .removeClass('f-c-atoms-previews__controls--active')

handleArrowClick = (e) ->
  e.preventDefault()
  $this = $(this)
  closeMobileControls($this)
  $wrap = $this.closest('.f-c-atoms-previews__preview')
  indices = $wrap.data('indices')
  if $this.hasClass('f-c-atoms-previews__button--arrow-up')
    $prev = $wrap.prevAll('.f-c-atoms-previews__preview').first()
    return if $prev.length is 0
    targetIndex = $prev.data('indices')[0]
    action = 'prepend'
  else
    $next = $wrap.nextAll('.f-c-atoms-previews__preview').first()
    return if $next.length is 0
    nextIndices = $next.data('indices')
    targetIndex = nextIndices[nextIndices.length - 1]
    action = 'append'

  data =
    rootKey: $wrap.data('root-key')
    indices: indices
    targetIndex: targetIndex
    action: action
    type: 'moveAtomsToIndex'

  window.top.postMessage(data, window.origin)

handleEditClick = (e) ->
  e.preventDefault()
  $this = $(this)
  closeMobileControls($this)
  $wrap = $this.closest('.f-c-atoms-previews__preview')
  if $wrap.length
    data =
      rootKey: $wrap.data('root-key')
      indices: $wrap.data('indices')
      type: 'editAtoms'

    window.top.postMessage(data, window.origin)
  else
    $wrap = $this.closest('.f-c-atoms-previews__setting')
    if $wrap.length
      data =
        type: 'editSetting'
        setting: $wrap.data('setting-key')
        locale: $wrap.closest('.f-c-atoms-previews__locale').data('locale')
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
    $wrap = $(this).closest('.f-c-atoms-previews__preview')
    data =
      rootKey: $wrap.data('root-key')
      indices: $wrap.data('indices')
      type: 'removeAtoms'

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
    .closest('.f-c-atoms-previews__locale')
    .addClass('f-c-atoms-previews__locale--active-insert')

hideInsert = ($insert) ->
  $insert
    .removeClass('f-c-atoms-previews__insert--active')
    .closest('.f-c-atoms-previews__locale')
    .removeClass('f-c-atoms-previews__locale--active-insert')

handleInsertClick = (e) ->
  e.preventDefault()
  $a = $(this)
  $insert = $a.closest('.f-c-atoms-previews__insert')
  hideInsert($insert)
  $wrap = $insert.next('.f-c-atoms-previews__preview')
  indices = $wrap.data('indices')
  action = 'splice'

  if $wrap.length is 0
    $wrap = $insert.prev('.f-c-atoms-previews__preview')

    if $wrap.length is 0
      action = 'prepend'
      indices = [0]
    else
      action = 'append'
      indices = $wrap.data('indices')

  $locale = $a.closest('.f-c-atoms-previews__locale')
  rootKey = $locale.data('root-key')

  data =
    type: 'newAtoms'
    rootKey: rootKey
    action: action
    indices: indices
    atomType: $a.data('type')
    contentable: $a.attr('data-contentable') is 'true'
  window.top.postMessage(data, window.origin)

handleSplitableJoinTriggerClick = (e) ->
  e.preventDefault()
  e.stopPropagation()
  $trigger = $(this)
  $insert = $trigger.closest('.f-c-atoms-previews__insert')
  hideInsert($insert)
  $previous = $insert.prev('.f-c-atoms-previews__preview')
  $next = $insert.next('.f-c-atoms-previews__preview')
  field = $previous.data('atom-splittable')
  return if field isnt $next.data('atom-splittable')
  indices = []

  $previous.data('indices').forEach (index) => indices.push(index)
  $next.data('indices').forEach (index) => indices.push(index)

  $locale = $trigger.closest('.f-c-atoms-previews__locale')
  rootKey = $locale.data('root-key')

  data =
    type: 'splittableJoinAtomsPrompt'
    rootKey: rootKey
    indices: indices
    field: field

  window.top.postMessage(data, window.origin)

sendResizeMessage = ->
  data =
    type: 'setHeight'
  window.top.postMessage(data, window.origin)

sendMediaQueryRequest = ->
  data =
    type: 'requestMediaQuery'
  window.top.postMessage(data, window.origin)

setMediaQuery = (width) ->
  width ||= $(window).width()
  if width > 991
    $('html')
      .removeClass('media-breakpoint-down-md')
      .addClass('media-breakpoint-up-lg')
  else
    $('html')
      .addClass('media-breakpoint-down-md')
      .removeClass('media-breakpoint-up-lg')

bindSortables = ->
  scrollSensitivity = Math.max(200, $(window).height() / 6)

  $('.f-c-atoms-previews__locale').each ->
    $this = $(this)
    $this.sortable
      axis: 'y'
      helper: 'clone'
      handle: '.f-c-atoms-previews__button--handle'
      items: '.f-c-atoms-previews__preview'
      placeholder: 'f-c-atoms-previews__preview-placeholder'
      scrollSensitivity: scrollSensitivity
      tolerance: 'pointer'
      update: (e, ui) ->
        $wrap = ui.item
        indices = $wrap.data('indices')
        $prev = $wrap.prevAll('.f-c-atoms-previews__preview').first()
        if $prev.length
          prevIndices = $prev.data('indices')
          targetIndex = prevIndices[prevIndices.length - 1]
          action = 'append'
        else
          $next = $wrap.nextAll('.f-c-atoms-previews__preview').first()
          return if $next.length  is 0
          targetIndex = $next.data('indices')[0]
          action = 'prepend'

        data =
          rootKey: $wrap.data('root-key')
          indices: indices
          targetIndex: targetIndex
          action: action
          type: 'moveAtomsToIndex'

        window.top.postMessage(data, window.origin)

      start: (e, ui) ->
        ui.placeholder
          .html(ui.item.html())

        height = ui.placeholder.height()
        scale = Math.round(100 * 100 / height) / 100

        ui.placeholder
          .find('.f-c-atoms-previews__preview-inner')
          .css('transform', "scale(#{scale})")

        ui.placeholder
          .addClass('f-c-atoms-previews__preview-placeholder--scaled')

        $this.addClass('ui-sortable--dragging')

      stop: (e, ui) ->
        $this.removeClass('ui-sortable--dragging')

unbindSortables = ->
  $('.f-c-atoms-previews__locale.ui-sortable').each ->
    $(this).sortable('destroy')

handleNewHtml = ->
  bindSortables()
  lazyloadAll()
  sendResizeMessage()
  $(document).trigger('folioConsoleReplacedHtml')

handleWillReplaceHtml = ->
  unbindSortables()
  $(document).trigger('folioConsoleWillReplaceHtml')

updateLabel = (locale, value) ->
  if locale
    $label = $(".f-c-atoms-previews__locale[data-locale='#{locale}'] .f-c-atoms-previews__label")
  else
    $label = $(".f-c-atoms-previews__locale .f-c-atoms-previews__label")
  $label.prop('hidden', value.length is 0)
  $label.find('.f-c-atoms-previews__label-h1').text(value)
  $(document).trigger('folioConsoleUpdatedLabel')

updatePerex = (locale, value) ->
  if locale
    $perex = $(".f-c-atoms-previews__locale[data-locale='#{locale}'] .f-c-atoms-previews__perex")
  else
    $perex = $(".f-c-atoms-previews__locale .f-c-atoms-previews__perex")
  $perex.prop('hidden', value.length is 0)
  $perex.find('.f-c-atoms-previews__perex-p').html(value)
  $(document).trigger('folioConsoleUpdatedPerex')

$(document)
  .on 'click', '.f-c-atoms-previews__button--arrow', handleArrowClick
  .on 'click', '.f-c-atoms-previews__button--edit', handleEditClick
  .on 'click', '.f-c-atoms-previews__button--settings', handleEditClick
  .on 'click', '.f-c-atoms-previews__controls-overlay', handleOverlayClick
  .on 'click', '.f-c-atoms-previews__button--remove', handleRemoveClick
  .on 'click', '.f-c-atoms-previews__insert-a', handleInsertClick
  .on 'click', '.f-c-atoms-previews__insert-splittable-join-trigger', handleSplitableJoinTriggerClick
  .on 'click', '.f-c-atoms-previews__insert-hint', showInsertHint
  .on 'click', '.f-c-atoms-previews__controls-mobile-overlay', handleMobileclick
  .on 'click', 'a, button', (e) -> e.preventDefault()
  .on 'form', 'submit', (e) -> e.preventDefault()
  .on 'mouseleave', '.f-c-atoms-previews__insert', (e) ->
    hideInsert($(this))

$(window).on 'resize orientationchange', sendResizeMessage

receiveMessage = (e) ->
  return if e.origin isnt window.origin
  switch e.data.type
    when 'replacedHtml' then handleNewHtml()
    when 'willReplaceHtml' then handleWillReplaceHtml()
    when 'selectLocale' then selectLocale(e.data.locale)
    when 'setMediaQuery' then setMediaQuery(e.data.width)
    when 'updateLabel' then updateLabel(e.data.locale, e.data.value)
    when 'updatePerex' then updatePerex(e.data.locale, e.data.value)

window.addEventListener('message', receiveMessage, false)

$ ->
  setMediaQuery()
  handleNewHtml()
  sendMediaQueryRequest()
  $(window).one 'load', -> sendResizeMessage()
