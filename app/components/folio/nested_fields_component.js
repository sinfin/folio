window.Folio.Stimulus.register('f-nested-fields', class extends window.Stimulus.Controller {
  static values = {
    key: String
  }

  static targets = ['template', 'fieldsWrap', 'fields']

  onAddClick (e) {
    e.preventDefault()
    this.add()
  }

  add () {
    this.fieldsWrapTarget.insertAdjacentHTML("beforeend", this.htmlFromTemplate())
    this.dispatch('add')
  }

  htmlFromTemplate () {
    const html = this.templateTarget.innerHTML

    let rxp = new RegExp(`\\[f-nested-fields-template-${this.keyValue}\\]`, 'g')
    const newId = new Date().getTime()
    let newHtml = html.replace(rxp, `[${newId}]`)

    if (newHtml === html) {
      rxp = new RegExp(`\\[f-nested-fields-template-${this.keyValue}s\\]`, 'g')
      newHtml = html.replace(rxp, '[' + newId + ']')
    }

    return newHtml
  }

  onDestroyClick (e) {
    e.preventDefault()

    window.Folio.Confirm.confirm(() => {
      const fields = e.target.closest('.f-nested-fields__fields')
      const idInput = fields.querySelector("input[name*='[id]']")

      if (idInput && idInput.value) {
        const destroyInput = fields.querySelector("input[name*='[_destroy]']")
        destroyInput.value = "1"
        fields.hidden = true
      } else {
        fields.remove()
      }

      this.dispatch('destroyed')
    }, 'remove')
  }
})
