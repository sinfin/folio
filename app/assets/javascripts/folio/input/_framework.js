window.Folio = window.Folio || {}
window.Folio.Input = window.Folio.Input || {}

window.Folio.Input.framework = (hash) => {
  if (!hash.SELECTOR || !hash.bind || !hash.unbind) {
    return console.error("Missing SELECTOR/bind/unbind. Cannot use input framework.")
  }

  hash.bindAll = ($wrap) => {
    $wrap = $wrap || $(document.body)
    $wrap.find(hash.SELECTOR).each((i, input) => { hash.bind(input) })
  }

  hash.unbindAll = ($wrap) => {
    $wrap = $wrap || $(document.body)
    $wrap.find(hash.SELECTOR).each((i, input) => { hash.unbind(input) })
  }

  if (typeof Turbolinks === 'undefined') {
    $(() => { hash.bindAll() })
  } else {
    $(document)
      .on('turbolinks:load', () => { hash.bindAll() })
      .on('turbolinks:before-render', () => { hash.unbindAll() })
  }

  $(document)
    .on('cocoon:after-insert', (e, insertedItem) => {
      hash.bindAll(insertedItem)
    })
    .on('cocoon:before-remove', (e, item) => {
      hash.unbindAll(item)
    })
}
