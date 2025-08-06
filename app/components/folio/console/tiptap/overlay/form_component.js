window.Folio.Stimulus.register('f-c-tiptap-overlay-form', class extends window.Stimulus.Controller {
  static targets = ["form"]

  static values = {
    autoclickCover: Boolean,
  }

  connect () {
    window.setTimeout(() => {
      const firstInput = this.element.querySelector('.form-control')

      if (firstInput) [
        firstInput.focus()
      ]
    }, 200) // wait for css transition

    this.startReactNodes()

    if (this.autoclickCoverValue) {
      window.setTimeout(() => {
        const btn = this.element.querySelector('.f-c-tiptap-overlay-form__react-file-picker--cover .f-c-file-picker[data-f-c-file-picker-has-file-value="false"] .f-c-file-picker__btn')
        if (btn) btn.click()
      }, 0)
    }
  }

  disconnect () {
    this.stopReactNodes()
  }

  startReactNodes () {
    for (const reactNode of this.element.querySelectorAll('.folio-react-wrap')) {
      window.FolioConsole.React.init(reactNode)
    }
  }

  stopReactNodes () {
    for (const reactNode of this.element.querySelectorAll('.folio-react-wrap')) {
      window.FolioConsole.React.destroy(reactNode)
    }
  }

  onFormSubmit (e) {
    e.preventDefault()
    const data = window.Folio.formToHash(e.target)

    this.dispatch("submit", { detail: { data } })
  }

  onCancelClick () {
    this.dispatch("close")
  }
})
