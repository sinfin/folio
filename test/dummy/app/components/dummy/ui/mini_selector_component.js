window.Folio.Stimulus.register('d-ui-mini-selector', class extends window.Stimulus.Controller {
  static targets = ['selectedValueText', 'options', 'option']

  // TODO: pridat zavreni expanded options po kliku mimo komponentu
  // Zvazit/zjistit pouziti 'stimulus-use'

  selectedValueClick () {
    if (!this.element.classList.contains("d-ui-mini-selector--toggle")) {
      this.element.classList.toggle("d-ui-mini-selector--expanded")
    } else {
      this.setOptionAsSelectedValue("toggle")
    }
  }

  optionClick (option) {
    const $option = option.target.closest('.d-ui-mini-selector__option')
    const optionValue = $option.innerText
    this.setOptionAsSelectedValue("select", optionValue)
  }

  setOptionAsSelectedValue (functionality, option) {
    const options = this.element.dataset.options.split(",")

    if (functionality == "toggle") {
      const currentSelected = this.selectedValueTextTarget.innerText
      const index = options.indexOf(currentSelected)
      const nextIndex = index == 0 ? 1 : 0
      const nextSelected = options[nextIndex]

      this.selectedValueTextTarget.innerText = nextSelected
    } else if (functionality == "select") {  
      this.selectedValueTextTarget.innerText = option
      this.regenerateOptions(option, options)
      this.element.classList.remove("d-ui-mini-selector--expanded")
    }

    console.log("In " + this.element.dataset.type + " selector was selected: " + this.selectedValueTextTarget.innerText)
  }
  
  regenerateOptions (clickedOption, options) {
    this.optionsTarget.innerHTML = ""
    options.forEach((option) => {
      if (option != clickedOption) {
        this.optionsTarget.insertAdjacentHTML('beforeend', `<div class="d-ui-mini-selector__option" data-action="click->d-ui-mini-selector#optionClick keydown.enter->d-ui-mini-selector#optionClick" tabindex="0" data-option="${option}">${option}</div>`)
      }
    })
  }
})
