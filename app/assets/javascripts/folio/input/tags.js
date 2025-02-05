//= require select2/dist/js/select2.full
//= require folio/add_params_to_url

window.Folio = window.Folio || {}
window.Folio.Input = window.Folio.Input || {}

window.Folio.Input.Tags = {}

window.Folio.Input.Tags.optionMapper = (str) => ({ value: str, text: str })

window.Folio.Input.Tags.bind = (input, opts) => {
  window.jQuery(input).selectize({
    delimiter: ', ',
    persist: false,
    create: window.Folio.Input.Tags.optionMapper,
    plugins: ['remove_button'],
    maxOptions: 50000,
    dropdownParent: 'body',
    preload: 'focus',
    load: (q, callback) => {
      const url = window.Folio.addParamsToUrl(opts.url, { q, context: opts.tagsContext })

      window.Folio.Api.apiGet(url)
        .then((res) => {
          callback(res.data.map(window.Folio.Input.Tags.optionMapper))
        })
        .catch((e) => {
          callback()
        })
    },
    render: {
      option_create: (data, escape) => (`
        <div class="create option">
          ${window.FolioConsole.translations.add}
          <strong>${escape(data.input)}</strong>&hellip;
        </div>
      `)
    }
  })
}

window.Folio.Input.Tags.unbind = (input) => {
  if (input.selectize) {
    input.selectize.destroy()
    input.selectize = null
  }
}

window.Folio.Stimulus.register('f-input-tags', class extends window.Stimulus.Controller {
  static values = {
    tagsContext: { type: String, default: 'tags' },
    url: String
  }

  connect () {
    this.initializing = !this.element.selectize

    if (this.initializing) {
      window.Folio.Input.Tags.bind(this.element, {
        url: this.urlValue,
        tagsContext: this.tagsContextValue
      })
    }
  }

  disconnect () {
    if (this.initializing) return
    window.Folio.Input.Tags.unbind(this.element)
  }
})
