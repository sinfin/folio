window.Folio.Stimulus.register('f-c-catalogue', class extends window.Stimulus.Controller {
  static targets = ['collectionBar']

  connect () {
    this.syncCollectionBar()
  }

  onRowCheckboxChange () {
    this.syncCollectionBar()
  }

  onCheckboxAllChange (event) {
    const checked = event.target.checked

    for (const cb of this.element.querySelectorAll('.f-c-catalogue__collection-actions-checkbox')) {
      cb.checked = checked
    }

    this.syncCollectionBar()
  }

  clearCollectionCheckboxes () {
    for (const cb of this.element.querySelectorAll('.f-c-catalogue__collection-actions-checkbox')) {
      cb.checked = false
    }

    this.syncCollectionBar()
  }

  syncCollectionBar () {
    if (!this.hasCollectionBarTarget) return

    const ids = []

    for (const cb of this.element.querySelectorAll('.f-c-catalogue__collection-actions-checkbox')) {
      if (cb.checked) ids.push(cb.value)
    }

    const bar = this.collectionBarTarget
    bar.dataset.ids = ids.join(',')
    bar.hidden = ids.length === 0

    const countEl = bar.querySelector('.f-c-catalogue__collection-actions-bar-count')

    if (countEl) countEl.textContent = String(ids.length)

    const qs = ids.join(',')

    for (const link of bar.querySelectorAll('[data-url-base]')) {
      const base = link.dataset.urlBase

      if (base) link.setAttribute('href', `${base}?ids=${qs}`)
    }

    const rowBoxes = this.element.querySelectorAll('.f-c-catalogue__collection-actions-checkbox')
    const allCb = this.element.querySelector('.f-c-catalogue__collection-actions-checkbox-all')

    if (allCb && rowBoxes.length) {
      allCb.checked = [...rowBoxes].every((cb) => cb.checked)
    }
  }

  submitCollectionBarForm (event) {
    const form = event.target
    const ids = this.collectionBarTarget.dataset.ids

    if (!ids) {
      event.preventDefault()
      return
    }

    for (const el of form.querySelectorAll('.f-c-catalogue__collection-actions-bar-input')) {
      el.remove()
    }

    const input = document.createElement('input')
    input.type = 'hidden'
    input.className = 'f-c-catalogue__collection-actions-bar-input'
    input.name = 'ids'
    input.value = ids
    form.appendChild(input)
  }
})
