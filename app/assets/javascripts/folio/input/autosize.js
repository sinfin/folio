//= require autosize/dist/autosize

window.Folio = window.Folio || {}
window.Folio.Input = window.Folio.Input || {}

window.Folio.Input.Autosize = {}
window.Folio.Input.Autosize.observedCount = 0

window.Folio.Input.Autosize.handleIntersect = (entries) => {
  entries.forEach((entry) => {
    if (entry.isIntersecting) {
      entry.target.dispatchEvent(new CustomEvent('autosize:update'))
      window.Folio.Input.Autosize.unobserve(entry.target)
    }
  })
}

window.Folio.Input.Autosize.observe = (element) => {
  if (!window.Folio.Input.Autosize.intersectionObserver) {
    window.Folio.Input.Autosize.intersectionObserver = new window.IntersectionObserver(window.Folio.Input.Autosize.handleIntersect, {
      threshold: [0]
    })
  }

  window.Folio.Input.Autosize.intersectionObserver.observe(element)
  window.Folio.Input.Autosize.observedCount += 1
  element.boundIntersectionObserver = true
}

window.Folio.Input.Autosize.unobserve = (element) => {
  if (!window.Folio.Input.Autosize.intersectionObserver) return
  if (!element.boundIntersectionObserver) return

  window.Folio.Input.Autosize.intersectionObserver.unobserve(element)
  window.Folio.Input.Autosize.observedCount -= 1
  delete element.boundIntersectionObserver

  if (window.Folio.Input.Autosize.observedCount < 1) {
    window.Folio.Input.Autosize.intersectionObserver.disconnect()
    window.Folio.Input.Autosize.intersectionObserver = null
    window.Folio.Input.Autosize.observedCount = 0
  }
}

window.Folio.Input.Autosize.bind = (input) => {
  window.autosize(input)
}

window.Folio.Input.Autosize.unbind = (input) => {
  window.autosize.destroy(input)
}

window.Folio.Stimulus.register('f-input-autosize', class extends window.Stimulus.Controller {
  connect () {
    window.Folio.Input.Autosize.bind(this.element)

    if (this.element.value) {
      this.bindIntersectionObserver()
    }
  }

  disconnect () {
    this.unbindIntersectionObserver()
    window.Folio.Input.Autosize.unbind(this.element)
  }

  bindIntersectionObserver () {
    window.Folio.Input.Autosize.observe(this.element)
  }

  unbindIntersectionObserver () {
    window.Folio.Input.Autosize.unobserve(this.element)
  }
})
