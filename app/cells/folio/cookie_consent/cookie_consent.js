//= require cookieconsent

window.Folio = window.Folio || {}
window.Folio.CookieConsent = window.Folio.CookieConsent || {}

window.Folio.CookieConsent.runAfterAccept = window.Folio.CookieConsent.runAfterAccept || []

if (window.Folio.CookieConsent.configuration) {
  window.Folio.CookieConsent.bindTurbolinks = typeof Turbolinks !== 'undefined'

  if (window.Folio.CookieConsent.bindTurbolinks) {
    window.Folio.CookieConsent.detached = null

    window.Folio.CookieConsent.onLoad = () => {
      if (window.Folio.CookieConsent.detached) {
        $('body').append(window.Folio.CookieConsent.detached)
        window.Folio.CookieConsent.detached = null
      }
    }

    window.Folio.CookieConsent.onBeforeRender = () => {
      const $main = $('#cc--main')
      if (!$main.length) return
      window.Folio.CookieConsent.detached = $main.detach()
    }
  }

  window.Folio.CookieConsent.onAccept = (cookie) => {
    if (window.Folio.CookieConsent.bindTurbolinks) {
      window.Folio.CookieConsent.bindTurbolinks = false

      $(document)
        .off('turbolinks:load', window.Folio.CookieConsent.onLoad)
        .off('turbolinks:before-render', window.Folio.CookieConsent.onBeforeRender)
    }

    if (window.dataLayer) {
      window.dataLayer.push({
        event: 'cookieConsent',
        level: cookie.level
      })
    }

    if (window.Folio.CookieConsent.runAfterAccept.length) {
      window.Folio.CookieConsent.runAfterAccept.forEach((callback) => {
        callback()
      })
      window.Folio.CookieConsent.runAfterAccept = []
    }
  }

  window.Folio.CookieConsent.cookieConsent = window.initCookieConsent()

  window.Folio.CookieConsent.cookieConsent.run(Object.assign({},
    window.Folio.CookieConsent.configuration,
    { onAccept: window.Folio.CookieConsent.onAccept }))

  if (window.Folio.CookieConsent.bindTurbolinks) {
    $(document)
      .on('turbolinks:load', window.Folio.CookieConsent.onLoad)
      .on('turbolinks:before-render', window.Folio.CookieConsent.onBeforeRender)
  }

  $(document).on('click', '.f-cookie-consent-link', (e) => {
    e.preventDefault()
    window.Folio.CookieConsent.cookieConsent.showSettings()
  })
}