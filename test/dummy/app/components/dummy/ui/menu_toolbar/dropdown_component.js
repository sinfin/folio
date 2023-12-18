window.Folio.Stimulus.register('d-ui-menu-toolbar-dropdown', class extends window.Stimulus.Controller {
  static values = {
    open: { type: Boolean, default: false },
    width: Number,
    dropdownTrigger: String,
  }

  // TODO: pridat zavreni po kliku mimo komponentu - zvazit/zjistit pouziti 'stimulus-use'

  connect () {
    this.setPosition()
  }

  triggerClicked () {
    if (this.openValue) {
      this.close()
    }else{
      this.open()
    }
  }

  open () {
    this.openValue = true
    this.element.classList.add("d-ui-menu-toolbar-dropdown--open")
  }

  close () {
    this.openValue = false
    this.element.classList.remove("d-ui-menu-toolbar-dropdown--open")
  }

  setPosition () {
    const $dropdownTrigger = document.querySelector(`.${this.dropdownTriggerValue}`)
    if (!$dropdownTrigger) return

    // get center position of dropdown trigger
    const dropdownTriggerLeft = $dropdownTrigger.offsetLeft
    const dropdownTriggerWidth = $dropdownTrigger.offsetWidth
    const center = dropdownTriggerLeft + dropdownTriggerWidth/2
    
    // set left position of dropdown
    const dropdownLeft = center - this.widthValue/2
    this.element.style.left = `${dropdownLeft}px`
  }

  titleClick () {
    this.element.classList.toggle("d-ui-menu-toolbar-dropdown--expanded")
  }
})
