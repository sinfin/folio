$(document).on 'change', '.f-c-boolean-toggle__input', (e) ->
  e.preventDefault()
  $input = $(this)
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
    success: ->
      $wrap.removeClass('f-c-boolean-toggle--loading')
    error: (jXHR) ->
      $wrap.removeClass('f-c-boolean-toggle--loading')
      $input.prop('checked', !$input.prop('checked'))
      window.FolioConsole.flashMessageFromApiErrors(jXHR.responseJSON)
