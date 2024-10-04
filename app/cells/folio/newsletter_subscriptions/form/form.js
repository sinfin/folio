/* global turnstile */

const renderTurnstile = () => {
  if (!window.turnstileSiteKey) return
  if (typeof turnstile === 'undefined') return

  $('.f-newsletter-subscriptions-form__turnstile').each((i, el) => {
    turnstile.render(el, {
      sitekey: window.turnstileSiteKey,
      appearance: 'interaction-only'
    })
  })
}

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

    renderTurnstile()

    if ($response.find('.f-newsletter-subscriptions-form__message').length) {
      $response.trigger('folio:success')
    } else {
      $response.trigger('folio:failure')
    }
  })
})

window.onloadTurnstileCallback = () => {
  renderTurnstile()

  $(document).on('turbolinks:load', () => {
    renderTurnstile()
  })
}
