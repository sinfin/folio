window.Folio = window.Folio || {}

window.Folio.debounce = (func, wait, immediate) => {
  let timeout = null

  if (wait === undefined) {
    wait = 150
  }

  if (immediate === undefined) {
    immediate = false
  }

  return function () {
    const context = this
    const args = arguments

    const later = () => {
      timeout = null
      if (!immediate) func.apply(context, args)
    }

    const callNow = immediate && !timeout

    if (timeout) window.clearTimeout(timeout)
    timeout = window.setTimeout(later, wait)

    if (callNow) func.apply(context, args)
  }
}
