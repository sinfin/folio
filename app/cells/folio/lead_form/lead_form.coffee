$ ->
  $(document).on 'submit', '.folio-lead-form', (e) ->
    e.preventDefault()
    $form = $(this)
    $wrap = $form.parent()
    $wrap.addClass('folio-lead-form-submitting')

    $.post($form.attr('action'), $form.serialize())
      .always (response) ->
        $response = $(response)
        $wrap.replaceWith($response)
        $response.trigger('folio:submitted')
        if $response.find('.folio-lead-form-message').length
          $response.trigger('folio:success')
        else
          $response.trigger('folio:failure')
