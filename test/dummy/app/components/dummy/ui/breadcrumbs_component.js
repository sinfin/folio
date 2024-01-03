window.Folio.Stimulus.register('d-ui-breadcrumbs', class extends window.Stimulus.Controller {
  static targets = ['pagyPageLink']

  connect () {
    this.getPageNumber()
  }

  getPageNumber () {
    this.pagyPageLinkTargets.forEach((i, el) => {
      const match = window.location.search.match(/page=(\d+)/)

      if (match && match[1] && parseInt(match[1]) > 1) {
        const joiner = el.href.indexOf('?') === -1 ? '?' : '&'
        el.href = `${el.href}${joiner}${match[0]}`
      }
    })
  }
})
