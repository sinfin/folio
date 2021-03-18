$(document)
  .on 'submit', '.f-leads-form__form', (e) ->
    e.preventDefault()

    $form = $(this)
    $wrap = $form.closest('.f-leads-form')
    return if $wrap.hasClass('f-leads-form--submitting')

    $wrap.addClass('f-leads-form--submitting')

    $.post($form.attr('action'), $form.serialize())
      .then (response) ->
        $response = $(response)
        $wrap.replaceWith($response)

        $recaptcha = $response.find('.g-recaptcha')
        if grecaptcha? and $recaptcha.length
          grecaptcha.render $recaptcha[0]

        $response.trigger('folio:submitted')

        if $response.find('.f-leads-form__message').length
          $response.trigger('folio:success')
        else
          $response.trigger('folio:failure')

      .fail ->
        alert($wrap.data('failure'))
        $wrap.find('.f-leads-form__submit').prop('disabled', false)
        $wrap.removeClass('f-leads-form--submitting')

  .on 'turbolinks:load', ->
    if grecaptcha? and grecaptcha.render
      $('.f-leads-form__recaptcha .g-recaptcha').each ->
        grecaptcha.render(this) if $(this).html() is ''
