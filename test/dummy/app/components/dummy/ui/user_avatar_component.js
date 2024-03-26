window.Folio.Stimulus.register('d-ui-user-avatar', class extends window.Stimulus.Controller {
  static targets = ['mq']

  static values = {
    active: { type: Boolean, default: false }
  }

  clicked (e) {
    e.target.blur()

    const isDesktop = window.Folio.isVisible(this.mqTarget)
    
    if (isDesktop) {
      if (e.type === "keydown" && e.key === "Escape" && !this.activeValue) return

      if (!this.activeValue) {
        this.activate()
      } else {
        this.deactivate()
      }
  
      this.dispatch("clicked")
    }else {
      window.location.href = "/"
    }
  }

  activate () {
    if (this.activeValue) return

    this.element.classList.add('d-ui-user-avatar--active')
    this.activeValue = true
  }

  deactivate () {
    if (!this.activeValue) return

    this.element.classList.remove('d-ui-user-avatar--active')
    this.activeValue = false
  }

  dropdownClosed ({ detail: { targetTrigger } }) {
    const $targetTrigger = document.querySelector(`.${targetTrigger}`)

    if ($targetTrigger !== this.element) return

    this.deactivate()
  }
})
