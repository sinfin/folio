window.Folio.Stimulus.register('f-c-ui-boolean-toggle', class extends window.Stimulus.Controller {
  static values = {
    url: { type: String, default: '' },
    confirmation: { type: String, default: '' },
    static: { type: Boolean, default: false }
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
    this.dispatch('input', { detail: { checked: input.checked } })
    input.dispatchEvent(new CustomEvent('folioConsoleCustomChange', { bubbles: true }))

    if (this.staticValue) return

    if (this.element.classList.contains(this.loadingClass)) return

    this.element.classList.add(this.loadingClass)

    const parts = input.name.replace(/\]/g, '').split('[')

    let data = { [parts[parts.length - 1]]: input.checked }

    for (let i = parts.length - 2; i >= 0; i -= 1) {
      data = { [parts[i]]: data }
    }

    data._trigger = 'f-c-ui-boolean-toggle'

    window.Folio.Api.apiPatch(this.urlValue, data).then((res) => {
      this.dispatch('updated', { detail: { name: parts[parts.length - 1], console_ui_boolean_toggle_data: res && res.data && res.data.console_ui_boolean_toggle_data } })
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

  stopPropagation (e) {
    e.stopPropagation()
  }
})
