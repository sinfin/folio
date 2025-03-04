// TODO jQuery -> stimulus

(() => {
  let loadEvent = 'turbolinks:load'
  let unloadEvent = 'turbolinks:before-render'

  if (typeof window.Turbolinks === 'undefined' || window.Turbolinks === null) {
    loadEvent = 'folioConsoleReplacedHtml'
    unloadEvent = 'folioConsoleWillReplaceHtml'
  }

  window.jQuery(document).on(loadEvent, () => {
    window.jQuery(document).trigger('folioAtomsLoad')
  }).on(unloadEvent, () => {
    window.jQuery(document).trigger('folioAtomsUnload')
  })
})()
