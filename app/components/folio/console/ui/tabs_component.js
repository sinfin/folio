window.Folio.Stimulus.register('f-c-ui-tabs', class extends window.Stimulus.Controller {
  static targets = ['link']

  static values = {
    remember: { type: String, default: '' }
  }

  connect () {
    if (this.rememberValue) {
      const href = window.localStorage.getItem(`f-c-ui-tabs-open-tab-${this.rememberValue}`)

      if (href) {
        this.linkTargets.forEach((link) => {
          if (link.dataset.href.replace('/edit', '') === href) {
            const li = link.closest('.f-c-ui-tabs__nav-item')

            if (!li.hidden) {
              link.click()
            }
          }
        })
      }
    }
  }

  onLinkClick (e) {
    if (this.rememberValue) {
      window.localStorage.setItem(`f-c-ui-tabs-open-tab-${this.rememberValue}`, e.currentTarget.dataset.href.replace('/edit', ''))
    }
  }
})
