// Extracted from https://stackoverflow.com/a/27078401

window.Folio = window.Folio || {}

window.Folio.throttle = function (callback, limit) {
  if (!limit) {
    limit = 150
  }

  let waiting = false // Initially, we're not waiting

  return function () { // We return a throttled function
    if (!waiting) { // If we're not waiting
      callback.apply(this, arguments) // Execute users function
      waiting = true // Prevent future invocations

      setTimeout(function () { // After a period of time
        waiting = false // And allow future invocations
      }, limit)
    }
  }
}
