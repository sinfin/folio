$ ->
  $wrap = $('.redactor')
  return if $wrap.length is 0
  $wrap.each ->
    $(this).redactor()
