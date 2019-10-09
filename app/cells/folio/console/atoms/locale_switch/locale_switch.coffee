$ ->
  $localeButtons = $('.f-c-atoms-locale-switch__button')
  return if $localeButtons.length is 0
  $localeButtons.on 'click', (e) ->
    e.preventDefault()
    $localeButtons.removeClass('f-c-atoms-locale-switch__button--active')
    $button = $(this)
    $button.addClass('f-c-atoms-locale-switch__button--active')
    msg =
      type: 'selectLocale'
      locale: $button.data('locale')
    document
      .getElementById('f-c-simple-form-with-atoms__iframe')
      .contentWindow
      .postMessage(msg, window.origin)
