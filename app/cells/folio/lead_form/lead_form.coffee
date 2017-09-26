$ ->
  $(document).on 'submit', '.folio-lead-form', (e) ->
    e.preventDefault()
    $form = $(this)
    $wrap = $form.parent()
    $wrap.addClass('folio-lead-form-submitting')

    $.post($form.attr('action'), $form.serialize())
      .always((response) -> $wrap.replaceWith(response))
