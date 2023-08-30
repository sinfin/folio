//= require cookieconsent

window.Folio = window.Folio || {}
window.Folio.CookieConsent = window.Folio.CookieConsent || {}

window.Folio.CookieConsent.runAfterAccept = window.Folio.CookieConsent.runAfterAccept || []

window.Folio.CookieConsent.didAccept = false

window.Folio.CookieConsent.changeRunAfterAcceptPushMethod = () => {
  // gets called after user accepts the consent
  // there's no point waiting for another onAccept
  // instead, execute the callbacks immediately without pushing to array
  // overriding the push method so that main_app code can stay the same no matter the state of cookie consent
  window.Folio.CookieConsent.runAfterAccept.push = function () {
    for (let i = 0; i < arguments.length; i++) {
      arguments[i]()
    }
  }
}

if (window.Folio.CookieConsent.configuration) {
  window.Folio.CookieConsent.bindTurbolinks = typeof Turbolinks !== 'undefined'

  if (window.Folio.CookieConsent.bindTurbolinks) {
    window.Folio.CookieConsent.detached = null

    window.Folio.CookieConsent.onLoad = () => {
      if (window.Folio.CookieConsent.detached) {
        document.body.appendChild(window.Folio.CookieConsent.detached)
        window.Folio.CookieConsent.detached = null
      }
    }

    window.Folio.CookieConsent.onBeforeRender = () => {
      const main = document.getElementById('cc--main')
      if (!main) return
      window.Folio.CookieConsent.detached = main
      main.parentNode.removeChild(main)
    }
  }

  window.Folio.CookieConsent.onAccept = (cookie) => {
    window.Folio.CookieConsent.didAccept = true

    if (window.Folio.CookieConsent.bindTurbolinks) {
      window.Folio.CookieConsent.bindTurbolinks = false

      document.removeEventListener('turbolinks:load', window.Folio.CookieConsent.onLoad)
      document.removeEventListener('turbolinks:before-render', window.Folio.CookieConsent.onBeforeRender)
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

    window.Folio.CookieConsent.changeRunAfterAcceptPushMethod()
  }

  window.Folio.CookieConsent.cookieConsent = window.initCookieConsent()

  window.Folio.CookieConsent.cookieConsent.run(Object.assign({},
    window.Folio.CookieConsent.configuration,
    { onAccept: window.Folio.CookieConsent.onAccept }))

  if (window.Folio.CookieConsent.bindTurbolinks) {
    document.addEventListener('turbolinks:load', window.Folio.CookieConsent.onLoad)
    document.addEventListener('turbolinks:before-render', window.Folio.CookieConsent.onBeforeRender)
  }

  window.Folio.Stimulus.register('f-cookie-consent-link', class extends window.Stimulus.Controller {
    connect () {
      this.element.dataset.action = "f-cookie-consent-link#click"
    }

    click (e) {
      e.preventDefault()
      window.Folio.CookieConsent.cookieConsent.showSettings()
    }
  })
}
