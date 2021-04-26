$ ->
  $(document).on 'submit', '.f-newsletter-subscriptions-form__form', (e) ->
    e.preventDefault()

    $form = $(this)
    return if $form.hasClass('f-newsletter-subscriptions-form--submitting')

    $wrap = $form.closest('.f-newsletter-subscriptions-form')
    $form.addClass('f-newsletter-subscriptions-form-submitting')

    $.post($form.attr('action'), $form.serialize())
      .always((response) -> $wrap.replaceWith(response))
