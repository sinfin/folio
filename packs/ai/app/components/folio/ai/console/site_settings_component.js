window.Folio.Stimulus.register('f-ai-c-site-settings', class extends window.Stimulus.Controller {
  static targets = ['model']

  static values = {
    providers: Object
  }

  changeProvider (event) {
    const providerData = this.providersValue[event.currentTarget.value]
    if (!providerData || !this.hasModelTarget) return

    this.replaceModelOptions(this.modelOptions(providerData))
    this.modelTarget.value = ''
  }

  modelOptions (providerData) {
    const defaultModel = providerData.defaultModel || ''
    const models = Array.from(providerData.models || []).filter((model) => model !== defaultModel)

    return [
      { label: providerData.defaultLabel || defaultModel, value: '' },
      ...models.map((model) => ({ label: model, value: model }))
    ]
  }

  replaceModelOptions (options) {
    const fragment = document.createDocumentFragment()

    options.forEach((optionData) => {
      const option = document.createElement('option')
      option.value = optionData.value
      option.textContent = optionData.label
      fragment.appendChild(option)
    })

    this.modelTarget.replaceChildren(fragment)
  }
})
