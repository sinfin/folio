sendMessage = (data) ->
  $('.f-c-simple-form-with-atoms__iframe, .f-c-merges-form-row__atoms-iframe').each ->
    @contentWindow.postMessage(data, window.origin)

$(document)
  .one 'click', '.f-c-simple-form-with-atoms__form', (e) ->
    $('.f-c-simple-form-with-atoms').addClass('f-c-simple-form-with-atoms--expanded-form')

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

  .on 'change folioCustomChange', '.f-c-js-atoms-placement-setting', (e) ->
    window.postMessage({ type: 'refreshPreview' }, window.origin)

selectTab = ($el) ->
  $tab = $el.closest('.tab-pane')

  if $tab.length and !$tab.hasClass('active')
    id = $tab.attr('id')
    $('.nav-tabs .nav-link').filter(-> @href.split('#').pop() is id).click()

editSetting = (locale, key) ->
  $('.f-c-simple-form-with-atoms').addClass('f-c-simple-form-with-atoms--expanded-form')
  if key == 'label'
    $setting = $('.f-c-js-atoms-placement-label')
  else if key == 'perex'
    $setting = $('.f-c-js-atoms-placement-perex')
  else
    $setting = $('.f-c-js-atoms-placement-setting').filter("[data-atom-setting='#{key}']")
  $setting = $setting.filter("[data-locale='#{locale}']") if locale
  selectTab($setting)
  if $setting.hasClass('selectized')
    $setting[0].selectize.focus()
  else
    $setting.focus()

setHeight = ->
  $iframes = $('.f-c-simple-form-with-atoms__iframe, .f-c-merges-form-row__atoms-iframe')
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
    when 'editSetting' then editSetting(e.data.locale, e.data.setting)


window.addEventListener('message', receiveMessage, false)
