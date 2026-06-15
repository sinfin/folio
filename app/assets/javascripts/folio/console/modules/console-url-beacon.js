//
// Clears the current user's console_url when they leave a console page
// (closing the tab, navigating away) so that other users don't see
// a stale "this page is being edited" warning for up to 5 minutes.
//
// The clear is conditional server-side - it only happens when the user's
// stored console_url still matches the URL sent by the beacon. This avoids
// races with regular navigation inside the console where the next request
// already stored a new console_url.
//
window.FolioConsole = window.FolioConsole || {}

window.FolioConsole.ConsoleUrlBeacon = {
  currentUrl () {
    return window.location.href.split('?')[0]
  },

  apiUrl (name) {
    const meta = document.querySelector(`meta[name="folio-console-api-${name}-url"]`)
    return (meta && meta.getAttribute('content')) || null
  },

  beacon (url) {
    if (!url || !navigator.sendBeacon) return

    const data = new URLSearchParams()
    data.append('url', window.FolioConsole.ConsoleUrlBeacon.currentUrl())

    const csrfMeta = document.querySelector('meta[name="csrf-token"]')
    if (csrfMeta) data.append('authenticity_token', csrfMeta.getAttribute('content'))

    navigator.sendBeacon(url, data)
  },

  onPagehide () {
    window.FolioConsole.ConsoleUrlBeacon.beacon(window.FolioConsole.ConsoleUrlBeacon.apiUrl('console-url-clear'))
  },

  onPageshow (e) {
    // restore the lock when the page comes back from the back/forward cache
    if (!e.persisted) return

    window.FolioConsole.ConsoleUrlBeacon.beacon(window.FolioConsole.ConsoleUrlBeacon.apiUrl('console-url-ping'))
  },

  bind () {
    window.addEventListener('pagehide', window.FolioConsole.ConsoleUrlBeacon.onPagehide)
    window.addEventListener('pageshow', window.FolioConsole.ConsoleUrlBeacon.onPageshow)
  },

  unbind () {
    window.removeEventListener('pagehide', window.FolioConsole.ConsoleUrlBeacon.onPagehide)
    window.removeEventListener('pageshow', window.FolioConsole.ConsoleUrlBeacon.onPageshow)
  }
}

window.FolioConsole.ConsoleUrlBeacon.bind()
