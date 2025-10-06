//= require autosize/dist/autosize
//= require folio/intersection-observer

window.Folio = window.Folio || {}
window.Folio.Input = window.Folio.Input || {}

window.Folio.Input.Autosize = {}
window.Folio.Input.Autosize.intersectionObserver = window.Folio.intersectionObserver({
  callback: (entry) => {
    entry.target.dispatchEvent(new CustomEvent('autosize:update'))
  }
})

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
    window.Folio.Input.Autosize.intersectionObserver.observe(this.element)
  }

  unbindIntersectionObserver () {
    window.Folio.Input.Autosize.intersectionObserver.unobserve(this.element)
  }
})
