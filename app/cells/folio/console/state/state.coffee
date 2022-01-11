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
  else if typeof $this.data('aasm-email-modal') isnt 'undefined'
    data =
      id: $this.data('id')
      klass: $this.data('klass')
      email: $this.data('email')
      targetStateName: $this.data('event-target-human-name')
      aasm_event: $this.data('event-name')
      trigger: $this
      emailSubject: $this.data('email-subject')
      emailText: $this.data('email-text')

    $('.f-c-aasm-email-modal').trigger('folioConsoleAasmEventModalTrigger', data)
  else
    $this.closest('.f-c-state').addClass('f-c-state--loading')

    $.ajax
      url: $this.data('url')
      method: 'POST'
      error: (jxHr) ->
        window.FolioConsole.Flash.flashMessageFromApiErrors(JSON.parse(jxHr.responseText))
        $this.closest('.f-c-state').removeClass('f-c-state--loading')
      success: (res) ->
        $this.closest('.f-c-state').replaceWith(res.data)
        window.FolioConsole.Flash.flashMessageFromMeta(res)
