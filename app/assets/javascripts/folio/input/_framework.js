window.Folio = window.Folio || {}
window.Folio.Input = window.Folio.Input || {}

window.Folio.Input.framework = (hash) => {
  if (!hash.SELECTOR || !hash.bind || !hash.unbind) {
    return console.error('Missing SELECTOR/bind/unbind. Cannot use input framework.')
  }

  hash.bindAll = (wrap) => {
    wrap = wrap || document.body
    wrap.querySelectorAll(hash.SELECTOR).forEach((input) => {
      hash.bind(input)
    })
  }

  hash.unbindAll = (wrap) => {
    wrap = wrap || document.body
    wrap.querySelectorAll(hash.SELECTOR).forEach((input) => {
      hash.unbind(input)
    })
  }

  if (typeof Turbolinks === 'undefined') {
    document.addEventListener('DOMContentLoaded', () => { hash.bindAll() })
  } else {
    document.addEventListener('turbolinks:load', () => hash.bindAll())
    document.addEventListener('turblolinks:before-render', () => hash.bindAll())
  }

  document.body.addEventListener('cocoon:after-insert', (insertedItem) => {
    hash.bindAll(insertedItem)
  })
  document.body.addEventListener('cocoon:before-remove', (item) => {
    hash.unbindAll(item)
  })
}
