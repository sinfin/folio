$(document).on 'change', '.f-c-boolean-toggle__input', (e) ->
  e.preventDefault()
  $input = $(this)

  if $input.data('confirmation')
    unless window.confirm $input.data('confirmation')
      $input.prop('checked', !$input.prop('checked'))
      return

  $wrap = $input.closest('.f-c-boolean-toggle')
  return if $wrap.hasClass('f-c-boolean-toggle--loading')
  $wrap.addClass('f-c-boolean-toggle--loading')

  url = $input.data('url')

  data = {}
  data[$input.prop('name')] = $input.prop('checked')

  $.ajax
    url: url
    data: data
    dataType: 'json'
    method: 'PATCH'
    success: (res) ->
      $wrap.removeClass('f-c-boolean-toggle--loading')
      $input.trigger('folioConsoleBooleanToggleSuccess', res)
    error: (jXHR) ->
      $wrap.removeClass('f-c-boolean-toggle--loading')
      $input.prop('checked', !$input.prop('checked'))
      window.FolioConsole.Flash.flashMessageFromApiErrors(jXHR.responseJSON)
