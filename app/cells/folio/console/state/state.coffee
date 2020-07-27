$(document).on 'click', '.f-c-state__state--trigger', (e) ->
  e.preventDefault()
  e.stopPropagation()

  $this = $(this)
  $this.closest('.f-c-state').addClass('f-c-state--loading')
  $this.closest('.dropdown').dropdown('hide')

  $.ajax
    url: $this.data('url')
    method: 'POST'
    error: (jxHr) ->
      window.FolioConsole.flashMessageFromApiErrors(JSON.parse(jxHr.responseText))
      $this.closest('.f-c-state').addClass('f-c-state--loading')
    success: (res) ->
      $this.closest('.f-c-state').replaceWith(res.data)
      window.FolioConsole.flashMessageFromMeta(res)
