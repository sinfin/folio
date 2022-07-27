$(document).on('submit', '.f-newsletter-subscriptions-form__form', function (e) {
  e.preventDefault()

  const $form = $(this)

  if ($form.hasClass('f-newsletter-subscriptions-form--submitting')) return

  const $wrap = $form.closest('.f-newsletter-subscriptions-form')
  $form.addClass('f-newsletter-subscriptions-form-submitting')

  $form
    .find(`input[name="${window.Folio.Csrf.tokenParam}"]`)
    .val(window.Folio.Csrf.token)

  $.post($form.attr('action'), $form.serialize()).always((response) => {
    $wrap.replaceWith(response)
  })
})
