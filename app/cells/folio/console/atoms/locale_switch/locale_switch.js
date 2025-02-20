// converted via https://coffeescript.org/#try
// once you update it, remove it from package.json standard js ignored files
window.jQuery(function () {
  let $localeButtons
  $localeButtons = window.jQuery('.f-c-atoms-locale-switch__button')
  if ($localeButtons.length === 0) {
    return
  }
  return $localeButtons.on('click', function (e) {
    let $button, iframe, locale, msg
    e.preventDefault()
    $button = window.jQuery(this)
    $button.siblings().removeClass('f-c-atoms-locale-switch__button--active')
    $button.addClass('f-c-atoms-locale-switch__button--active')
    locale = $button.data('locale')
    msg = {
      type: 'selectLocale',
      locale
    }
    iframe = $button.closest('.f-c-atoms-locale-switch').parent().find('.f-c-simple-form-with-atoms__iframe')[0]
    iframe.contentWindow.postMessage(msg, window.origin)
    return window.dispatchEvent(new CustomEvent('atomsLocaleSwitch', {
      detail: {
        locale
      }
    }))
  })
})
