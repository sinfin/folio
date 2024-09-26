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
    this.dispatch('add', { detail: { field: this.fieldsTargets[this.fieldsTargets.length - 1] } })
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
      const idInput = fields.querySelector('.f-nested-fields__id-input')

      if (idInput && idInput.value) {
        const destroyInput = fields.querySelector('.f-nested-fields__destroy-input')

        destroyInput.value = "1"
        fields.hidden = true
      } else {
        fields.remove()
      }

      this.dispatch('destroyed')
    }, 'remove')
  }

  onPositionUpClick (e) {
    e.preventDefault()
    const fields = e.target.closest('.f-nested-fields__fields')
    const target = fields.previousElementSibling

    if (target && target.classList.contains('f-nested-fields__fields')) {
      target.insertAdjacentElement('beforebegin', fields)
      this.redoPositions()
    }
  }

  onPositionDownClick (e) {
    e.preventDefault()
    const fields = e.target.closest('.f-nested-fields__fields')
    const target = fields.nextElementSibling

    if (target && target.classList.contains('f-nested-fields__fields')) {
      target.insertAdjacentElement('afterend', fields)
      this.redoPositions()
    }
  }

  redoPositions () {
    let position = 0

    this.fieldsTargets.forEach((fields) => {
      if (!fields.hidden) {
        const input = fields.querySelector('.f-nested-fields__position-input')

        if (input) {
          position += 1
          input.value = position
        }
      }
    })
  }
})
