window.folioDebounce = (func, wait = 150, immediate = false) =>
  timeout = null

  return ->
    context = this
    args = arguments

    later = ->
      timeout = null
      func.apply(context, args) unless immediate

    callNow = immediate and not timeout
    clearTimeout(timeout)
    timeout = setTimeout(later, wait)

    func.apply(context, args) if callNow
