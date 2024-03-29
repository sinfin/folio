$(document)
  .on 'folioConsoleAasmEventModalTrigger', '.f-c-aasm-email-modal', (e, data) ->
    $modal = $(this)
    $form = $modal.find('.f-c-aasm-email-modal__form')
    # formData = $form.data('data')

    $title = $form.find('.f-c-aasm-email-modal__title')
    $title.text($title.data('title').replace('{STATE_NAME}', data.targetStateName))

    $checkbox = $('.f-c-aasm-email-modal__checkbox')
    $checkbox.siblings('.form-check-label').text($checkbox.data('label').replace('{EMAIL}', data.email))

    $form.data('trigger', data.trigger)

    ["klass", "aasm_event", "id", "email"].forEach (key) ->
      $form.find(".f-c-aasm-email-modal__hidden--#{key}").val(data[key])

    $form.find(".f-c-aasm-email-modal__subject").val(data.emailSubject)
    $form.find(".f-c-aasm-email-modal__text").val(data.emailText)

    $modal.modal('show')

    $subject = $modal.find('.f-c-aasm-email-modal__subject')
    if $subject.val()
      $modal.find('.f-c-aasm-email-modal__text').focus()
    else
      $subject.focus()

  .on 'change keyup', '.f-c-aasm-email-modal__form', (e) ->
    $form = $(this)

    if $form.find('.f-c-aasm-email-modal__checkbox').prop('checked')
      valid = not not $form.find('.f-c-aasm-email-modal__text').val()
    else
      valid = true

    $form
      .find('.f-c-aasm-email-modal__submit')
      .prop('disabled', not valid)

  .on 'submit', '.f-c-aasm-email-modal__form', (e) ->
    e.preventDefault()
    $form = $(this)

    $modal = $form.closest('.f-c-aasm-email-modal')
    $trigger = $form.data('trigger')

    $modal.addClass('f-c-aasm-email-modal--loading')

    $.ajax
      url: $form.prop('action')
      data: $form.serialize()
      method: 'POST'

      error: (jxHr) ->
        window.FolioConsole.Flash.flashMessageFromApiErrors(JSON.parse(jxHr.responseText))
        $modal.removeClass('f-c-aasm-email-modal--loading')

      success: (res) ->
        $trigger.closest('.f-c-state').replaceWith(res.data)

        window.FolioConsole.Flash.flashMessageFromMeta(res)

        $modal
          .removeClass('f-c-aasm-email-modal--loading')
          .modal('hide')

      complete: ->
        $form.data('trigger', null)
        $form[0].reset()
