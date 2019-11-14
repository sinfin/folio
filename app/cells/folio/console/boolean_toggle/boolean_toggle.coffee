$(document).on 'change', '.f-c-boolean-toggle__input', (e) ->
  e.preventDefault()
  $input = $(this)
  $form = $input.closest('.f-c-boolean-toggle')
  return if $form.hasClass('f-c-boolean-toggle--loading')
  $form.addClass('f-c-boolean-toggle--loading')

  url = $form.prop('action')

  data = {}
  data[$input.prop('name')] = $input.prop('checked')

  $.ajax url,
    data: data
    method: 'PATCH'
    success: ->
      $form.removeClass('f-c-boolean-toggle--loading')
    error: ->
      $form.removeClass('f-c-boolean-toggle--loading')
      $input.prop('checked', !$input.prop('checked'))
