function bindRaf (fn) {
  var isRunning, that, args

  var run = function () {
    isRunning = false
    fn.apply(that, args)
  }

  return function () {
    that = this
    args = arguments

    if (isRunning) { return }

    isRunning = true
    requestAnimationFrame(run)
  }
}
