// TODO jQuery -> stimulus

(() => {
  let loadEvent = 'turbolinks:load'
  let unloadEvent = 'turbolinks:before-render'

  if (typeof Turbolinks === 'undefined' || Turbolinks === null) {
    loadEvent = 'folioConsoleReplacedHtml'
    unloadEvent = 'folioConsoleWillReplaceHtml'
  }

  $(document).on(loadEvent, () => {
    $(document).trigger('folioAtomsLoad')
  }).on(unloadEvent, () => {
    $(document).trigger('folioAtomsUnload')
  })
})()
