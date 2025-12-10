// TODO jQuery -> stimulus

$(document).on('submit', '.f-newsletter-subscriptions-form__form', function (e) {
  e.preventDefault()

  const $form = $(this)

  if ($form.hasClass('f-newsletter-subscriptions-form--submitting')) return

  const $wrap = $form.closest('.f-newsletter-subscriptions-form')
  $form.addClass('f-newsletter-subscriptions-form-submitting')

  $.post($form.attr('action'), $form.serialize()).always((response) => {
    const $response = $(response)
    $wrap.replaceWith($response)

    // Re-render reCAPTCHA if present
    const $recaptcha = $response.find('.g-recaptcha')
    if (typeof grecaptcha !== 'undefined' && $recaptcha.length) {
      grecaptcha.render($recaptcha[0])
    }

    $response.trigger('folio:submitted')

    if ($response.find('.f-newsletter-subscriptions-form__message').length) {
      $response.trigger('folio:success')
    } else {
      $response.trigger('folio:failure')
    }
  })
})

// Initialize reCAPTCHA on page load
$(document).on('turbolinks:load turbo:load', function () {
  if (typeof grecaptcha !== 'undefined' && grecaptcha.render) {
    $('.f-newsletter-subscriptions-form__recaptcha .g-recaptcha').each(function () {
      if ($(this).html() === '') {
        grecaptcha.render(this)
      }
    })
  }
})
