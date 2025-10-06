window.Folio = window.Folio || {}

window.Folio.intersectionObserver = (options = {}) => {
  const manager = { count: 0 }

  manager.handleIntersect = (entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        if (options.callback) {
          options.callback(entry)
        } else {
          entry.target.dispatchEvent(new CustomEvent('f-observer:intersect'))
        }

        manager.unobserve(entry.target)
      }
    })
  }

  manager.observe = (element) => {
    if (!manager.intersectionObserver) {
      manager.intersectionObserver = new window.IntersectionObserver(manager.handleIntersect, {
        threshold: options.threshold || [0]
      })
    }

    manager.intersectionObserver.observe(element)
    manager.count += 1
    element.boundIntersectionObserver = true
  }

  manager.unobserve = (element) => {
    if (!manager.intersectionObserver) return
    if (!element.boundIntersectionObserver) return

    manager.intersectionObserver.unobserve(element)
    manager.count -= 1
    delete element.boundIntersectionObserver

    if (manager.count < 1) {
      manager.intersectionObserver.disconnect()
      manager.intersectionObserver = null
      manager.count = 0
    }
  }

  return manager
}
