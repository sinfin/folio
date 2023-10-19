window.Folio.Stimulus.register('d-ui-boolean-toggle', class extends window.Stimulus.Controller {
  static values = {
    url: { type: String, default: '' },
    attribute: String,
    confirmation: { type: String, default: '' }
  }

  static classes = ['loading']

  onInput (e) {
    const input = e.target

    if (this.confirmationValue) {
      if (this.confirmationValue === 'true') {
        if (window.Folio.Confirm.confirm(() => { this.onInputInner(input) })) {
          return
        }
      } else {
        if (window.Folio.Confirm.message(() => { this.onInputInner(input) }, this.confirmationValue)) {
          return
        }
      }

      input.checked = !input.checked
      return
    }

    this.onInputInner(input)
  }

  onInputInner (input) {
    if (this.urlValue) {
      if (this.element.classList.contains(this.loadingClass)) return

      this.element.classList.add(this.loadingClass)

      const parts = input.name.replace(/\]/g, '').split('[')

      let data = { [parts[parts.length - 1]]: input.checked }

      for (let i = parts.length - 2; i >= 0; i -= 1) {
        data = { [parts[i]]: data }
      }

      data._trigger = 'd-ui-boolean-toggle'

      window.Folio.Api.apiPut(this.urlValue, data).then((res) => {
        this.element.classList.remove(this.loadingClass)

        if (res && res.data && res.data.f_c_catalogue_published_dates) {
          const row = this.element.closest('.f-c-catalogue__row')
          if (row) {
            const cell = row.querySelector('.f-c-catalogue__cell--published_dates .f-c-catalogue__cell-value')

            if (cell) {
              cell.innerHTML = res.data.f_c_catalogue_published_dates
            }
          }
        }
      }).catch((res) => {
        window.FolioConsole.Flash.alert(res.message)

        this.element.classList.remove(this.loadingClass)
        input.checked = !input.checked
      })
    }

    this.dispatch('changed', { detail: { attribute: this.attributeValue, checked: input.checked } })
  }
})
