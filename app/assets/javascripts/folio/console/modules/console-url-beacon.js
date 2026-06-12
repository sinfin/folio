//
// Clears the current user's console editing presence when they leave a console
// page (closing the tab, navigating away) so that other users don't see a
// stale "this page is being edited" warning for up to 5 minutes.
//
// The clear removes all of the user's presence rows (no URL or record needed).
// The surviving heartbeat controller re-creates the presence row within 10 s.
//
window.FolioConsole = window.FolioConsole || {}

window.FolioConsole.ConsoleUrlBeacon = {
  apiUrl (name) {
    const meta = document.querySelector(`meta[name="folio-console-api-${name}-url"]`)
    return (meta && meta.getAttribute('content')) || null
  },

  beacon (url) {
    if (!url || !navigator.sendBeacon) return

    const data = new URLSearchParams()
    const csrfMeta = document.querySelector('meta[name="csrf-token"]')
    if (csrfMeta) data.append('authenticity_token', csrfMeta.getAttribute('content'))

    navigator.sendBeacon(url, data)
  },

  onPagehide () {
    window.FolioConsole.ConsoleUrlBeacon.beacon(window.FolioConsole.ConsoleUrlBeacon.apiUrl('console-presence-clear'))
  },

  onPageshow (e) {
    if (!e.persisted) return
    window.FolioConsole.ConsoleUrlBeacon.beacon(window.FolioConsole.ConsoleUrlBeacon.apiUrl('console-presence-ping'))
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
