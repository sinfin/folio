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

    if $btn.data('action')
      if $btn.data('action') is 'sign_in'
        $(this)
          .find('.f-devise-modal__content')
          .removeClass('f-devise-modal__content--active')
          .filter('.f-devise-modal__content--sessions')
          .addClass('f-devise-modal__content--active')
      else if $btn.data('action') is 'sign_up'
        $(this)
          .find('.f-devise-modal__content')
          .removeClass('f-devise-modal__content--active')
          .filter('.f-devise-modal__content--registrations')
          .addClass('f-devise-modal__content--active')
