$(document)
  .on('click', '.f-devise-modal-aware-link', function (e) {
    const $dialog = $(this).closest('.f-devise-modal__dialog--active')

    if ($dialog.length) {
      e.preventDefault()
      $dialog.removeClass('f-devise-modal__dialog--active').siblings('.f-devise-modal__dialog').first().addClass('f-devise-modal__dialog--active')
    }
  })

  .on('shown.bs.modal', '.f-devise-modal', function (e) {
    $(this).find('[autofocus]:visible').first().focus()
  })

  .on('show.bs.modal', '.f-devise-modal', function (e) {
    const $btn = $(e.relatedTarget)
    const $modal = $(this)

    if ($btn.data('after-sign-in-path')) {
      $modal.data('after-sign-in-path', $btn.data('after-sign-in-path'))
    }

    if ($btn.data('action')) {
      if ($btn.data('action') === 'sign_in') {
        $modal.find('.f-devise-modal__dialog').removeClass('f-devise-modal__dialog--active').filter('.f-devise-modal__dialog--sessions').addClass('f-devise-modal__dialog--active')
      } else if ($btn.data('action') === 'sign_up') {
        $modal.find('.f-devise-modal__dialog').removeClass('f-devise-modal__dialog--active').filter('.f-devise-modal__dialog--registrations').addClass('f-devise-modal__dialog--active')
      }
    }
  })

  .on('submit', '.f-devise-modal__form', function (e) {
    e.preventDefault()
    const $form = $(this)
    $form.addClass('f-devise-modal__form--loading')

    $.ajax({
      method: this.method,
      url: this.action,
      data: $form.serialize(),
      dataType: 'JSON',
      success: (res) => {
        const path = $form.closest('.f-devise-modal').data('after-sign-in-path')
        if (path) {
          window.location.href = path
        } else if (res.data && res.data.url) {
          window.location.href = res.data.url
        } else {
          window.location.reload()
        }
      },
      error: (jxHr) => {
        const json = jxHr.responseJSON

        if (json) {
          if (json.error) {
            window.alert(json.error)
            return $form.removeClass('f-devise-modal__form--loading')
          } else if (json.data) {
            $form.trigger('folioDeviseBeforeHtmlReplace')
            const $wrap = $form.closest('.f-devise-sessions-new, .f-devise-invitations-new')
            const $parent = $wrap.parent()
            $wrap.replaceWith(jxHr.responseJSON.data)
            return $parent.find('.f-devise-modal__form').trigger('folioDeviseAfterHtmlReplace')
          }
        }

        window.alert($form.data('failure'))
        return $form.removeClass('f-devise-modal__form--loading')
      }
    })
  })
