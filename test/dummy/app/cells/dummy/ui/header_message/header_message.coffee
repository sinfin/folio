# TODO jQuery -> stimulus

unless Cookies?
  console.error("Missing Cookies dependency - add 'js-cookie' to application.js")

$(document).on 'click', '.d-ui-header-message__close', ->
  $wrap = $(this).closest('.d-ui-header-message')
  $wrap.slideUp(100)
  Cookies.set('hiddenHeaderMessage', $wrap.data('cookie')) if Cookies?
