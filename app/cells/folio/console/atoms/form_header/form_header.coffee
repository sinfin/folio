$ ->
  $localeButtons = $('.f-c-atoms-form-header__button--locale')
  return if $localeButtons.length is 0
  $localeButtons.on 'click', (e) ->
    $localeButtons.removeClass('f-c-atoms-form-header__button--active')
    $button = $(this)
    $button.addClass('f-c-atoms-form-header__button--active')
    e.preventDefault()
    msg =
      type: 'selectLocale'
      locale: $button.data('locale')
    document
      .getElementById('f-c-simple-form-with-atoms__iframe')
      .contentWindow
      .postMessage(msg, window.origin)

