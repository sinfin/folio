window.Folio.Stimulus.register('f-c-ui-tabs', class extends window.Stimulus.Controller {
  static targets = ['hiddenInput']

  onBeforeUnload () {
    const activeLink = this.element.querySelector('.f-c-ui-tabs__nav-link.active')

    if (activeLink) {
      const inFifteenSeconds = new Date(new Date().getTime() + 16 * 1000)

      window.Cookies.set('f-c-ui-tabs__selected-tab',
        activeLink.dataset.key,
        { expires: inFifteenSeconds, path: '' })
    }
  }
})
