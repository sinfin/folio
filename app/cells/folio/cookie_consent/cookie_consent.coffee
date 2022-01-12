#= require cookieconsent

if window.folioCookieConsentConfiguration
  bindTurbolinks = Turbolinks?

  if bindTurbolinks
    detached = null

    onLoad = ->
      if detached
        $('body').append(detached)
        detached = null

    onBeforeRender = ->
      $main = $('#cc--main')
      return unless $main.length
      detached = $main.detach()

  onAccept = (cookie) ->
    if bindTurbolinks
      bindTurbolinks = false

      $(document)
        .off 'turbolinks:load', onLoad
        .off 'turbolinks:before-render', onBeforeRender

    if window.dataLayer
      window.dataLayer.push
        event: 'cookieConsent'
        level: cookie.level

  window.folioCookieConsent = initCookieConsent()

  window.folioCookieConsent.run(Object.assign({}, window.folioCookieConsentConfiguration, { onAccept: onAccept }))

  if bindTurbolinks
    $(document)
      .on 'turbolinks:load', onLoad
      .on 'turbolinks:before-render', onBeforeRender

  $(document).on 'click', '.f-cookie-consent-link', (e) ->
    e.preventDefault()
    window.folioCookieConsent.showSettings()
