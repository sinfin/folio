// Extracted from https://stackoverflow.com/a/27078401

window.folioThrottle = function (callback, limit) {
  if (!limit) {
    limit = 150;
  }

  var waiting = false;                  // Initially, we're not waiting

  return function () {                  // We return a throttled function
    if (!waiting) {                     // If we're not waiting
      callback.apply(this, arguments);  // Execute users function
      waiting = true;                   // Prevent future invocations

      setTimeout(function () {          // After a period of time
        waiting = false;                // And allow future invocations
      }, limit);
    }
  }
}
