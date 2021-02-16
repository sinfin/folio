$(document)
  .on 'click', '.f-devise-modal-aware-link', (e) ->
    $content = $(this).closest('.f-devise-modal__content--active')

    if $content.length
      e.preventDefault()
      $content
        .removeClass('f-devise-modal__content--active')
        .siblings('.f-devise-modal__content')
        .first()
        .addClass('f-devise-modal__content--active')

  .on 'show.bs.modal', '.f-devise-modal', (e) ->
    $btn = $(e.relatedTarget)
    $modal = $(this)

    if $btn.data('after-sign-in-path')
      $modal.data('after-sign-in-path', $btn.data('after-sign-in-path'))

    if $btn.data('action')
      if $btn.data('action') is 'sign_in'
        $modal
          .find('.f-devise-modal__content')
          .removeClass('f-devise-modal__content--active')
          .filter('.f-devise-modal__content--sessions')
          .addClass('f-devise-modal__content--active')
      else if $btn.data('action') is 'sign_up'
        $modal
          .find('.f-devise-modal__content')
          .removeClass('f-devise-modal__content--active')
          .filter('.f-devise-modal__content--registrations')
          .addClass('f-devise-modal__content--active')

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
        else
          window.location.reload()

      error: (jxHr) ->
        $form
          .closest('.f-devise-sessions-new')
          .replaceWith(jxHr.responseJSON.data)
