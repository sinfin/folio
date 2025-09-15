window.Folio.Stimulus.register('f-c-ui-index-header', class extends window.Stimulus.Controller {
  onQueryAutocompleteSelected (e) {
    e.currentTarget.requestSubmit()
  }
})
