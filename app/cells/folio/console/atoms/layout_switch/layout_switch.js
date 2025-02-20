// converted via https://coffeescript.org/#try
// once you update it, remove it from package.json standard js ignored files
window.jQuery(function () {
  let $layoutButtons, receiveMessage, sendMessage
  $layoutButtons = window.jQuery('.f-c-atoms-layout-switch__button')
  if ($layoutButtons.length === 0) {
    return
  }
  sendMessage = function () {
    let msg
    msg = {
      type: 'setMediaQuery'
    }
    if ($layoutButtons.is(':visible')) {
      msg.width = window.jQuery(window).width()
    }
    return window.jQuery('.f-c-simple-form-with-atoms__iframe').each(function () {
      return this.contentWindow.postMessage(msg, window.origin)
    })
  }
  $layoutButtons.on('click', function (e) {
    let $button, layout
    e.preventDefault()
    $button = window.jQuery(this)
    $button.siblings().removeClass('f-c-atoms-layout-switch__button--active')
    $button.addClass('f-c-atoms-layout-switch__button--active')
    layout = $button.data('layout')
    Cookies.set('f_c_atoms_layout_switch', layout)
    $button.closest('.f-c-simple-form-with-atoms').removeClass('f-c-simple-form-with-atoms--layout-vertical f-c-simple-form-with-atoms--layout-horizontal').addClass(`f-c-simple-form-with-atoms--layout-${layout}`)
    return sendMessage()
  })
  sendMessage()
  window.jQuery(window).on('resize orientationchange', function () {
    return sendMessage()
  })
  receiveMessage = function (e) {
    if (e.origin !== window.origin) {
      return
    }
    switch (e.data.type) {
      case 'requestMediaQuery':
        return sendMessage()
    }
  }
  return window.addEventListener('message', receiveMessage, false)
})
