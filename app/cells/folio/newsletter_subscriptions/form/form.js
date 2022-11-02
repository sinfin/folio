$(document).on('submit', '.f-newsletter-subscriptions-form__form', function (e) {
  e.preventDefault()

  const $form = $(this)

  if ($form.hasClass('f-newsletter-subscriptions-form--submitting')) return

  const $wrap = $form.closest('.f-newsletter-subscriptions-form')
  $form.addClass('f-newsletter-subscriptions-form-submitting')

  $.post($form.attr('action'), $form.serialize()).always((response) => {
    const $response = $(response)
    $wrap.replaceWith($response)

    $response.trigger('folio:submitted')

    if ($response.find('.f-newsletter-subscriptions-form__message').length) {
      $response.trigger('folio:success')
    } else {
      $response.trigger('folio:failure')
    }
  })
})
