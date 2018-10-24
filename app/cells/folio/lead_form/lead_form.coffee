#= require folio/csrf

$ ->
  $(document).one 'focus', '.folio-lead-form', ->
    window.folioFreshCsrfToken.preloadToken()

  $(document).on 'submit', '.folio-lead-form', (e) ->
    e.preventDefault()
    return if window.folioFreshCsrfToken.loading

    $form = $(this)
    $wrap = $form.parent()
    return if $wrap.hasClass('folio-lead-form-submitting')

    $wrap.addClass('folio-lead-form-submitting')

    window.folioFreshCsrfToken.withToken (token) ->
      $form
        .find("input[name=\"#{window.folioFreshCsrfToken.tokenParam}\"]")
        .val(token)

      $.post($form.attr('action'), $form.serialize())
        .then (response) ->
          $response = $(response)
          $wrap.replaceWith($response)
          $response.trigger('folio:submitted')
          if $response.find('.folio-lead-form-message').length
            $response.trigger('folio:success')
          else
            $response.trigger('folio:failure')

        .catch ->
          alert($wrap.data('failure'))
          $wrap.find('input[type="submit"]').prop('disabled', false)
          $wrap.removeClass('folio-lead-form-submitting')
