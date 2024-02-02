window.Folio = window.Folio || {}
window.Folio.Input = window.Folio.Input || {}

window.Folio.Input.ContentTemplates = {}

window.Folio.Input.ContentTemplates.I18n = {
  cs: {
    title: 'Šablony',
  },
  en: {
    remove: 'Templates'
  }
}

window.Folio.Input.ContentTemplates.bind = (input, { templates, editUrl, title }) => {
  if (templates.length === 0) return

  let wrap = input.closest('.f-c-translated-inputs') || input.closest('.form-group')

  if (wrap.classList.contains('f-input-content-templates-bound')) return

  wrap.classList.add('f-input-content-templates-bound')

  let label = wrap.querySelector('label')

  if (!label) {
    label = document.createElement('label')
    label.for = input.id
    label.innerHTML = '&nbsp;'
    input.insertAdjacentElement('beforebegin', label)
  }

  let menuHtml = ""

  if (editUrl && title) {
    const iconHtml = window.Folio.Ui.Icon.create('edit', { class: "f-input-content-templates-dropdown__header-ico ms-2" }).outerHTML

    menuHtml += `<a class="dropdown-header f-input-content-templates-dropdown__header" href="${editUrl}">
      <span class="f-input-content-templates-dropdown__header-text">${title}</span>${iconHtml}</a>`
  }

  templates.forEach((hash) => {
    menuHtml += `<a href="#" class="dropdown-item f-input-content-templates-dropdown__item" data-action="f-input-content-templates-menu#onItemClick" data-f-input-content-templates-menu-contents-param="${window.encodeURIComponent(JSON.stringify(hash.contents))}">${hash.label}</a>`
  })

  const flexHtml = `<div class="f-input-content-templates-dropdown">
    <span class="ml-3 small f-input-content-templates-dropdown__toggle dropdown-toggle" data-toggle="dropdown" data-bs-toggle="dropdown">${window.Folio.i18n(window.Folio.Input.ContentTemplates.I18n, 'title')}</span>

    <div class="dropdown-menu f-input-content-templates-dropdown__menu" data-controller="f-input-content-templates-menu">${menuHtml}</div>
  </div>`

  label.insertAdjacentHTML('beforebegin', flexHtml)
  const flex = wrap.querySelector('.f-input-content-templates-dropdown')
  flex.insertAdjacentElement('afterbegin', label)
}

window.Folio.Input.ContentTemplates.unbind = (input) => {
  // no action needed
}

window.Folio.Stimulus.register('f-input-content-templates-menu', class extends window.Stimulus.Controller {
  onItemClick (e) {
    e.preventDefault()
    const values = JSON.parse(window.decodeURIComponent(e.params.contents))
    const wrap = this.element.closest('.f-input-content-templates-bound')
    const inputs = wrap.querySelectorAll('[data-controller="f-input-content-templates"]')

    inputs.forEach((input, i) => {
      if (values[i]) {
        input.value = values[i]
        input.dispatchEvent(new window.Event('change', { bubbles: true }))
      }
    })
  }
})

window.Folio.Stimulus.register('f-input-content-templates', class extends window.Stimulus.Controller {
  static values = {
    templates: String,
    editUrl: String,
    title: String,
  }

  connect () {
    if (this.templatesValue) {
      const templates = JSON.parse(this.templatesValue)

      window.Folio.Input.ContentTemplates.bind(this.element, {
        templates,
        editUrl: this.editUrlValue,
        title: this.titleValue,
      })
    }
  }

  disconnect () {
    if (this.templatesValue) {
      window.Folio.Input.ContentTemplates.unbind(this.element)
    }
  }
})
