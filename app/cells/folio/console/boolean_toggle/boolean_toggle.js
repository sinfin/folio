window.Folio.Stimulus.register('f-c-boolean-toggle', class extends window.Stimulus.Controller {
  static targets = ['input']
  static classes = ['loading']

  inputChange (e) {
    if (this.inputTarget.dataset.confirmation) {
      if (!window.confirm(this.inputTarget.dataset.confirmation)) {
        this.inputTarget.checked = !this.inputTarget.checked
        return
      }
    }

    if (this.element.classList.contains(this.loadingClass)) return

    this.element.classList.add(this.loadingClass)

    const parts = this.inputTarget.name.replace(/\]/g, '').split('[')

    let data = { [parts[parts.length - 1]]: this.inputTarget.checked }

    for (let i = parts.length - 2; i >= 0; i -= 1) {
      data = { [parts[i]]: data }
    }

    data._trigger = 'f-c-boolean-toggle'

    window
      .Folio
      .Api
      .apiPut(this.inputTarget.dataset.url, data)
      .then((res) => {
        this.element.classList.remove(this.loadingClass)

        if (res && res.data && res.data.f_c_catalogue_published_dates) {
          const cell = this
            .element
            .closest('.f-c-catalogue__row')
            .querySelector('.f-c-catalogue__cell--published_dates .f-c-catalogue__cell-value')

          if (cell) {
            cell.innerHTML = res.data.f_c_catalogue_published_dates
          }
        }
      })
      .catch(() => {
        this.element.classList.remove(this.loadingClass)
        this.inputTarget.checked = !this.inputTarget.checked
      })
  }
})
