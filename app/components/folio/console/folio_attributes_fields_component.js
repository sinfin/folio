window.Folio.Stimulus.register('f-c-folio-attributes-fields', class extends window.Stimulus.Controller {
  static targets = ['attribute']

  reorderAttributes = Folio.debounce((callback) => {
    // reorder attribute targets by data position in DOM
    const attributesParent = this.element.querySelector('.f-nested-fields__fields-wrap')

    let didSort = false

    const sorted = this.attributeTargets.sort((a, b) => {
      const ao = this.getSelectedOption(a.querySelector('.f-c-folio-attributes-fields__type-select'))
      const bo = this.getSelectedOption(b.querySelector('.f-c-folio-attributes-fields__type-select'))

      const aa = parseInt(ao.dataset.position)
      const bb = parseInt(bo.dataset.position)

      if (aa > bb) {
        didSort = true
      }

      return aa - bb
    })

    if (didSort) {
      sorted.forEach((attributeTarget) => {
        const attributeWrap = attributeTarget.closest('.f-nested-fields__fields')
        attributesParent.appendChild(attributeWrap)
      })
    }

    if (callback) callback()
  })

  attributeTargetConnected (attributeTarget) {
    const select = attributeTarget.querySelector('.f-c-folio-attributes-fields__type-select')
    this.onTypeChange(select)
  }

  onNestedFieldsAdd (e) {
    this.reorderAttributes(() => {
      if (e && e.detail && e.detail.field) {
        window.setTimeout(() => {
          e.detail.field.querySelector('.f-c-folio-attributes-fields__type-select').focus()
        }, 0)
      }
    })
  }

  onTypeChange (e) {
    if (!e || !e.target) return
    this.handleSelectChange(e.target)
    this.reorderAttributes()
  }

  getSelectedOption (select) {
    return select.selectedOptions[0] || select.options[0]
  }

  handleSelectChange (select) {
    const selectedOption = this.getSelectedOption(select)
    const dataType = selectedOption.dataset.dataType

    const wrap = select.closest('.f-c-folio-attributes-fields__attribute')

    for (const byType of wrap.querySelectorAll('.f-c-folio-attributes-fields__value-inputs-by-type')) {
      const disabled = byType.dataset.dataType !== dataType

      if (disabled && byType.tagName !== 'TEMPLATE') {
        this.convertTo(byType, 'template')
      } else if (!disabled && byType.tagName !== 'DIV') {
        this.convertTo(byType, 'div')
      }
    }
  }

  convertTo (node, targetTag) {
    node.outerHTML = node.outerHTML.replace(/^<(div|template)/, `<${targetTag}`).replace(/(div|template>)$/, `${targetTag}>`)
  }

  onIntegerInputChange (e) {
    const input = e.target
    const value = input.folioInputNumeralCleave ? input.folioInputNumeralCleave.getRawValue() : input.value
    const wrap = input.closest('.f-c-folio-attributes-fields__value-inputs-by-type')
    const hiddenInputs = wrap.querySelectorAll('.f-c-folio-attributes-fields__value-hidden-input')

    for (const hiddenInput of hiddenInputs) {
      hiddenInput.value = value
    }
  }
})
