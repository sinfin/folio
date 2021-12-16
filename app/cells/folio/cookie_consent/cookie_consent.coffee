#= require cookieconsent

if window.folioCookieConsentConfiguration
  # TODO
  # if window.dataLayer
  #   window.dataLayer.push()

  window.folioCookieConsent = initCookieConsent()
  window.folioCookieConsent.run(window.folioCookieConsentConfiguration)

  detached = null

  $(document)
    .on 'turbolinks:load', ->
      if detached
        $('body').append(detached)
        detached = null

    .on 'turbolinks:before-render', ->
      $main = $('#cc--main')
      return unless $main.length
      detached = $main.detach()
