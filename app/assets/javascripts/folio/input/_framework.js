window.Folio = window.Folio || {}
window.Folio.Input = window.Folio.Input || {}

window.Folio.Input.Framework = {}

window.Folio.Input.Framework.bindInputEvents = (bind, unbind) => {
  if (typeof Turbolinks === 'undefined') {
    $(() => { bind() })
  } else {
    $(document)
      .on('turbolinks:load', () => { bind() })
      .on('turbolinks:before-render', () => { unbind() })
  }

  $(document)
    .on('cocoon:after-insert', (e, insertedItem) => {
      bind(insertedItem)
    })
    .on('cocoon:before-remove', (e, item) => {
      unbind(item)
    })
}
