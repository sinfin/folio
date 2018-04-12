$(document).on 'click', '.folio-console-boolean-toggle', (e) ->
  e.preventDefault()
  $btn = $(this)
  return if $btn.hasClass('folio-console-loading')
  $btn.addClass('folio-console-loading')
  $btn.blur()

  $input = $btn.find('input')

  url = $btn.data('boolean-toggle')

  data = {}
  data[$input.prop('name')] = !$input.prop('checked')

  $.ajax url,
    data: data
    method: 'PATCH'
    success: ->
      $btn.removeClass('folio-console-loading')
      $input.prop('checked', !$input.prop('checked'))
    error: ->
      $btn.removeClass('folio-console-loading')
