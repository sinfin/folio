export function confirmed (callback) {
  if (window.confirm(window.FolioConsole.translations.removePrompt)) {
    callback()
  }
}

export function makeConfirmed (callback) {
  return () => confirmed(callback)
}

export default confirmed
