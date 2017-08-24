$ ->
  $wrap = $('.redactor')
  return if $wrap.length is 0
  $wrap.each ->
    $(this).redactor()

  $(document).on 'cocoon:after-insert', (e, insertedItem) ->
    $(insertedItem).find('.redactor').each ->
      $(this).redactor()
