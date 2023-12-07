window.Folio.Stimulus.register('d-ui-mini-select', class extends window.Stimulus.Controller {
  static targets = ['selectedValueText', 'option']

  static values = {
    type: String,
    options: Array,
    toggleSelect: Boolean
  }

  // TODO: pridat zavreni expanded options po kliku mimo komponentu
  // Zvazit/zjistit pouziti 'stimulus-use'

  connect () {
    this.updateLastVisibleOption()
  }

  selectedValueClick () {
    if (!this.toggleSelectValue) {
      this.element.classList.toggle("d-ui-mini-select--expanded")
    } else {
      this.setOptionAsSelectedValue("toggle")
    }
  }

  optionClick (option) {
    const $option = option.target.closest('.d-ui-mini-select__option')
    const optionValue = $option.innerText
    this.setOptionAsSelectedValue("select", optionValue)
  }

  setOptionAsSelectedValue (functionality, option) {
    const options = this.optionsValue

    if (functionality === "toggle") {
      const currentSelected = this.selectedValueTextTarget.innerText
      const index = options.indexOf(currentSelected)
      const nextIndex = index == 0 ? 1 : 0
      const nextSelected = options[nextIndex]

      this.selectedValueTextTarget.innerText = nextSelected
    } else if (functionality === "select") {  
      this.selectedValueTextTarget.innerText = option
      this.refreshOptions(option)
      this.element.classList.remove("d-ui-mini-select--expanded")
    }

    console.log("In " + this.typeValue + " select was selected: " + this.selectedValueTextTarget.innerText)
  }
  
  refreshOptions (clickedOption) {
    this.optionTargets.forEach((option) => {
      if (option.innerText != clickedOption) {
        option.classList.remove("d-ui-mini-select__option--selected")
      } else {
        option.classList.add("d-ui-mini-select__option--selected")
      }
    })

    this.updateLastVisibleOption()
  }

  updateLastVisibleOption () {
    if (this.toggleSelectValue) return

    const lastElement = this.optionTargets[this.optionTargets.length - 1]
    const secondLastElement = this.optionTargets[this.optionTargets.length - 2]

    this.optionTargets.forEach((option) => {
      option.classList.remove("d-ui-mini-select__option--last-visible")
    })

    if (!lastElement.classList.contains('d-ui-mini-select__option--selected')) {
      lastElement.classList.add('d-ui-mini-select__option--last-visible')
    } else {
      secondLastElement.classList.add('d-ui-mini-select__option--last-visible')
    }
  }
})
