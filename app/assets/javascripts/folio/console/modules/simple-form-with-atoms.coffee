sendMessage = (data) ->
  $('.f-c-simple-form-with-atoms__iframe').each ->
    @contentWindow.postMessage(data, window.origin)

$(document)
  .on 'submit', '.f-c-simple-form-with-atoms', (e) ->
    $(this).addClass('f-c-simple-form-with-atoms--submitting')

  .on 'click', '.f-c-simple-form-with-atoms__overlay-dismiss', (e) ->
    e.preventDefault()
    window.postMessage({ type: 'closeForm' }, window.origin)

  .on 'click', '.f-c-simple-form-with-atoms__form-toggle, .f-c-simple-form-with-atoms__title--clickable', (e) ->
    e.preventDefault()
    $('.f-c-simple-form-with-atoms').toggleClass('f-c-simple-form-with-atoms--expanded-form')

  .on 'keyup', '.f-c-js-atoms-placement-label', (e) ->
    e.preventDefault()
    $this = $(this)
    sendMessage
      type: 'updateLabel'
      locale: $this.data('locale') or null
      value: $this.val()

  .on 'keyup', '.f-c-js-atoms-placement-perex', (e) ->
    e.preventDefault()
    $this = $(this)
    sendMessage
      type: 'updatePerex'
      locale: $this.data('locale') or null
      value: $this.val()

editLabel = (locale) ->
  $label = $('.f-c-js-atoms-placement-label')
  $label = $label.filter("[data-locale='#{locale}']") if locale
  $label.focus()

editPerex = (locale) ->
  $('.f-c-simple-form-with-atoms').addClass('f-c-simple-form-with-atoms--expanded-form')
  $perex = $('.f-c-js-atoms-placement-perex')
  $perex = $perex.filter("[data-locale='#{locale}']") if locale
  $perex.focus()

setHeight = ->
  $iframes = $('.f-c-simple-form-with-atoms__iframe')
  minHeight = 0

  $iframes.each ->
    return unless @contentWindow.jQuery
    height = @contentWindow.jQuery('.f-c-atoms-previews').outerHeight(true)
    minHeight = Math.max(minHeight, height) if typeof height is 'number'

  $iframes.css('min-height', minHeight)

receiveMessage = (e) ->
  return if e.origin isnt window.origin
  switch e.data.type
    when 'setHeight' then setHeight()
    when 'editLabel' then editLabel(e.data.locale)
    when 'editPerex' then editPerex(e.data.locale)

window.addEventListener('message', receiveMessage, false)
