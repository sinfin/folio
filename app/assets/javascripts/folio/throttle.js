// Extracted from https://gist.github.com/msssk/b720a8bddf2ba595347820ac387751ce

window.Folio = window.Folio || {}

window.Folio.throttle = (callback, delay) => {
  let ready = true
  let args = null

  delay = delay || 100

  return function throttled () {
    const context = this

    if (ready) {
      ready = false

      setTimeout(function () {
        ready = true

        if (args) {
          throttled.apply(context)
        }
      }, delay)

      if (args) {
        callback.apply(this, args)
        args = null
      } else {
        callback.apply(this, arguments)
      }
    } else {
      args = arguments
    }
  }
}
