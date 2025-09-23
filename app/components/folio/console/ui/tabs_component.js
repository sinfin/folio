window.Folio.Stimulus.register('f-c-ui-tabs', class extends window.Stimulus.Controller {
  static targets = ['hiddenInput']

  static values = {
    useCookiesForActive: Boolean
  }

  onBeforeUnload () {
    if (!this.useCookiesForActiveValue) return

    const activeLink = this.element.querySelector('.f-c-ui-tabs__nav-link.active')

    if (activeLink) {
      const inFifteenSeconds = new Date(new Date().getTime() + 16 * 1000)

      window.Cookies.set('f-c-ui-tabs__selected-tab',
        activeLink.dataset.key,
        { expires: inFifteenSeconds, path: '' })
    }
  }

  connect () {
    const activeLink = this.element.querySelector('.f-c-ui-tabs__nav-link.active')

    if (activeLink) {
      this.propagateEventToTabPane(activeLink, 'show')
      this.propagateEventToTabPane(activeLink, 'shown')
    }
  }

  onShow (e) {
    this.propagateEventToTabPane(e.target, 'show')
  }

  onShown (e) {
    this.propagateEventToTabPane(e.target, 'shown')
  }

  onHide (e) {
    this.propagateEventToTabPane(e.target, 'hide')
  }

  onHidden (e) {
    this.propagateEventToTabPane(e.target, 'hidden')
  }

  propagateEventToTabPane (target, eventName) {
    const selector = target.dataset.bsTarget || target.dataset.href

    if (selector) {
      const tabPane = document.getElementById(selector.replace('#', ''))
      if (tabPane) {
        tabPane.dispatchEvent(new CustomEvent(`f-c-ui-tabs:${eventName}`, { bubbles: true }))
      }
    }
  }

  onClick (e) {
    e.preventDefault()
    e.target.blur()
  }
})
