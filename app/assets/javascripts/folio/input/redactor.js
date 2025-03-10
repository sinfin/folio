window.Folio = window.Folio || {}
window.Folio.Input = window.Folio.Input || {}

window.Folio.Input.Redactor = {}

window.Folio.Input.Redactor.intlTelInputOptions = {
  separateDialCode: true,
  dropdownContainer: document.body,
  autoPlaceholder: 'aggressive'
}

window.Folio.Input.Redactor.bind = (input) => {
  const opts = {
    advanced: input.classList.contains('f-input--redactor-advanced'),
    email: input.classList.contains('f-input--redactor-email'),
    perex: input.classList.contains('f-input--redactor-perex')
  }

  const additional = {}

  if (input.classList.contains('f-c-js-atoms-placement-perex')) {
    additional.callbacks = {
      keyup: () => {
        const data = {
          type: 'updatePerex',
          locale: null,
          value: input.source.getCode()
        }

        $('.f-c-simple-form-with-atoms__iframe, .f-c-merges-form-row__atoms-iframe').each((i, el) => {
          el.contentWindow.postMessage(data, window.origin)
        })
      }
    }
  }

  window.folioConsoleInitRedactor(input, opts, additional)
}

window.Folio.Input.Redactor.unbind = (input) => {
  window.folioConsoleDestroyRedactor(input)
}

window.Folio.Input.Redactor.updateByCurrentHtml = (input) => {
  const R = $R(input)
  R.broadcast('hardsync')
}

window.Folio.Stimulus.register('f-input-redactor', class extends window.Stimulus.Controller {
  static targets = ['input']

  connect () {
    window.Folio.Input.Redactor.bind(this.inputTarget)
  }

  disconnect () {
    window.Folio.Input.Redactor.unbind(this.inputTarget)
  }
})
