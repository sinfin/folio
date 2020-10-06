$ ->
  $(document).on 'submit', '.folio-newsletter-subscription-form', (e) ->
    e.preventDefault()

    $form = $(this)
    return if $form.hasClass('folio-newsletter-subscription-form-submitting')

    $wrap = $form.parent()
    $form.addClass('folio-newsletter-subscription-form-submitting')

    $.post($form.attr('action'), $form.serialize())
      .always((response) -> $wrap.replaceWith(response))
