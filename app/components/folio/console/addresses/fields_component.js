window.Folio.Stimulus.register('f-c-addresses-fields', class extends window.Stimulus.Controller {
  onToggle (e) {
    const col = e.currentTarget.closest('.f-c-addresses-fields__col')
    const fields = col.querySelector('.f-c-addresses-fields__fields')

    for (const input of fields.querySelectorAll('input, select, textarea')) {
      input.disabled = !e.currentTarget.checked
    }
  }
})
