#= require folio/csrf

$ ->
  $(document).on 'submit', '.folio-newsletter-subscription-form', (e) ->
    e.preventDefault()
    return if window.folioFreshCsrfToken.loading

    $form = $(this)
    return if $form.hasClass('folio-newsletter-subscription-form-submitting')

    $wrap = $form.parent()
    $form.addClass('folio-newsletter-subscription-form-submitting')

    window.folioFreshCsrfToken.withToken (token) ->
      $form
        .find("input[name=\"#{window.folioFreshCsrfToken.tokenParam}\"]")
        .val(token)

      $.post($form.attr('action'), $form.serialize())
        .always((response) -> $wrap.replaceWith(response))
