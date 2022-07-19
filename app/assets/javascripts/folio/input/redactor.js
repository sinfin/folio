window.Folio = window.Folio || {}
window.Folio.Input = window.Folio.Input || {}

window.Folio.Input.Redactor = {}

window.Folio.Input.Redactor.SELECTOR = '.f-input--redactor'

window.Folio.Input.Redactor.intlTelInputOptions = {
  separateDialCode: true,
  dropdownContainer: document.body,
  autoPlaceholder: 'aggressive'
}

window.Folio.Input.Redactor.bindAll = ($wrap) => {
  $wrap = $wrap || $(document.body)

  $wrap.find(window.Folio.Input.Redactor.SELECTOR).each((i, input) => {
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
  })
}

window.Folio.Input.Redactor.unbindAll = ($wrap) => {
  $wrap = $wrap || $(document.body)

  $wrap.find(window.Folio.Input.Redactor.SELECTOR).each((i, input) => {
    window.folioConsoleDestroyRedactor(input)
  })
}

if (typeof Turbolinks === 'undefined') {
  $(() => { window.Folio.Input.Redactor.bindAll() })
} else {
  $(document)
    .on('turbolinks:load', () => { window.Folio.Input.Redactor.bindAll() })
    .on('turbolinks:before-render', () => { window.Folio.Input.Redactor.unbindAll() })
}

$(document)
  .on('cocoon:after-insert', (e, insertedItem) => {
    window.Folio.Input.Redactor.bindAll(insertedItem)
  })
  .on('cocoon:before-remove', (e, item) => {
    window.Folio.Input.Redactor.unbindAll(item)
  })
