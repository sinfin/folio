$(document)
  .on 'click', '.f-devise-modal-aware-link', (e) ->
    $dialog = $(this).closest('.f-devise-modal__dialog--active')

    if $dialog.length
      e.preventDefault()
      $dialog
        .removeClass('f-devise-modal__dialog--active')
        .siblings('.f-devise-modal__dialog')
        .first()
        .addClass('f-devise-modal__dialog--active')

  .on 'shown.bs.modal', '.f-devise-modal', (e) ->
    $(this).find('[autofocus]:visible').first().focus()

  .on 'show.bs.modal', '.f-devise-modal', (e) ->
    $btn = $(e.relatedTarget)
    $modal = $(this)

    if $btn.data('after-sign-in-path')
      $modal.data('after-sign-in-path', $btn.data('after-sign-in-path'))

    if $btn.data('action')
      if $btn.data('action') is 'sign_in'
        $modal
          .find('.f-devise-modal__dialog')
          .removeClass('f-devise-modal__dialog--active')
          .filter('.f-devise-modal__dialog--sessions')
          .addClass('f-devise-modal__dialog--active')
      else if $btn.data('action') is 'sign_up'
        $modal
          .find('.f-devise-modal__dialog')
          .removeClass('f-devise-modal__dialog--active')
          .filter('.f-devise-modal__dialog--registrations')
          .addClass('f-devise-modal__dialog--active')

  .on 'submit', '.f-devise-modal__form', (e) ->
    e.preventDefault()
    $form = $(this)
    $form.addClass('f-devise-modal__form--loading')

    $.ajax
      method: @method
      url: @action
      data: $form.serialize()
      dataType: 'JSON'
      success: (res) ->
        path = $form.closest('.n-devise-modal').data('after-sign-in-path')
        if path
          window.location.href = path
        else if res.data and res.data.url
          window.location.href = res.data.url
        else
          window.location.reload()

      error: (jxHr) ->
        $form
          .closest('.f-devise-sessions-new, .f-devise-registrations-new')
          .replaceWith(jxHr.responseJSON.data)
