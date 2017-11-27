$ ->
  $(document).on 'submit', '.folio-newsletter-subscription-form', (e) ->
    e.preventDefault()
    $form = $(this)
    $wrap = $form.parent()
    data = {}
    for input in $form.serializeArray()
      data[input.name] = input.value

    $form.addClass('folio-newsletter-subscription-form-submitting')

    $.post($form.attr('action'), data)
      .always((response) -> $wrap.replaceWith(response))
