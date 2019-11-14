export function confirm (callback) {
  return window.confirm(window.FolioConsole.translations.removePrompt)
}

export function confirmed (callback) {
  if (confirm()) {
    callback()
  }
}

export function makeConfirmed (callback) {
  return () => confirmed(callback)
}

export default confirmed
