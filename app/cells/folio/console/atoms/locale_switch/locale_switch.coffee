$ ->
  $localeButtons = $('.f-c-atoms-locale-switch__button')
  return if $localeButtons.length is 0

  $localeButtons.on 'click', (e) ->
    e.preventDefault()
    $button = $(this)
    $button.siblings().removeClass('f-c-atoms-locale-switch__button--active')
    $button.addClass('f-c-atoms-locale-switch__button--active')

    locale = $button.data('locale')

    msg =
      type: 'selectLocale'
      locale: locale

    iframe = $button
      .closest('.f-c-atoms-locale-switch')
      .parent()
      .find('.f-c-simple-form-with-atoms__iframe')[0]

    iframe.contentWindow.postMessage(msg, window.origin)

    window.dispatchEvent(new CustomEvent('atomsLocaleSwitch', { detail: { locale: locale } }))
