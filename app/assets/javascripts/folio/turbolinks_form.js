//= require folio/add_params_to_url
//= require folio/form_to_hash

window.Folio.Stimulus.register('f-turbolinks-form', class extends window.Stimulus.Controller {
  onSubmit (e) {
    e.preventDefault()

    const rawData = window.Folio.formToHash(this.element)
    const data = {}

    Object.keys(rawData).forEach((key) => {
      if (rawData[key] !== '') {
        data[key] = rawData[key]
      }
    })

    const url = window.Folio.addParamsToUrl(this.element.action, data)

    window.Turbolinks.visit(url)
  }
})
