// Extracted from https://stackoverflow.com/a/44779316

window.Folio = window.Folio || {}

window.Folio.raf = function (fn, throttle) {
  let isRunning
  let that
  let args

  const run = function () {
    isRunning = false
    fn.apply(that, args)
  }

  return function () {
    that = this
    args = arguments

    if (isRunning && throttle) {
      return
    }

    isRunning = true
    window.requestAnimationFrame(run)
  }
}
