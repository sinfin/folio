$(document).on 'click', '.f-c-state__state--trigger', (e) ->
  $this = $(this)

  if $this.data('confirmation')
    return unless window.confirm($this.data('confirmation'))

  modal = $this.data('modal')
  if modal
    data =
      event: $this.data('event-name')
      id: $this.data('id')
      url: $this.data('url')
      klass: $this.data('klass')
      trigger: $this

    $(modal).trigger('folioConsoleAasmTrigger', data)
  else
    $this.closest('.f-c-state').addClass('f-c-state--loading')

    $.ajax
      url: $this.data('url')
      method: 'POST'
      error: (jxHr) ->
        window.FolioConsole.flashMessageFromApiErrors(JSON.parse(jxHr.responseText))
        $this.closest('.f-c-state').removeClass('f-c-state--loading')
      success: (res) ->
        $this.closest('.f-c-state').replaceWith(res.data)
        window.FolioConsole.flashMessageFromMeta(res)
