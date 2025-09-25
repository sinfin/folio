window.Folio.Stimulus.register('f-input-embed-inner', class extends window.Stimulus.Controller {
  static values = {
    state: String
  }

  static targets = ['urlInput', 'htmlInput']

  onInput (e) {
    this.updateStateBasedOnInputs()
  }

  // updateStateBasedOnInputs () {
  //   const newState = this.getNewStateBasedOnInputs()
  //   if (!newState) return
  //   if (newState == this.stateValue) return

  //   this.stateValue = newState
  // }

  // getNewStateBasedOnInputs () {
  //   const htmlValue = this.htmlInputTarget.value.trim()
  //   if (htmlValue) {
  //     if (htmlValue)
  //   }
  // }
})
