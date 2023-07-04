//= require folio/input/_framework

window.Folio = window.Folio || {}
window.Folio.Input = window.Folio.Input || {}

window.Folio.Input.ContentTemplates = {}

window.Folio.Input.ContentTemplates.SELECTOR = '.f-input--content-templates'

window.Folio.Input.ContentTemplates.bind = (input) => {
  const $input = $(input)
  let $wrap = $input.closest('.f-c-translated-inputs')

  if ($wrap.length === 0) $wrap = $input.closest('.form-group')

  if ($wrap.hasClass('f-input--content-templates-bound')) return

  $wrap.addClass('f-input--content-templates-bound')

  let $label = $wrap.find('label')

  if ($label.length === 0) {
    $label = $(`<label for="${$input.prop('id')}">&nbsp;</label>`)
    $input.before($label)
  }

  const $menu = $('<div class="dropdown-menu f-input-content-templates-dropdown__menu" />')

  const url = $input.data('content-templates-url')

  const title = $input.data('content-templates-title')

  if (url && title) {
    $menu.append($(`<a class="dropdown-header f-input-content-templates-dropdown__header" href="${url}">
      <span class="f-input-content-templates-dropdown__header-text">${title}</span>
      ${window.Folio.Ui.Icon.create('edit', { class: "f-input-content-templates-dropdown__header-ico ms-2" }).outerHTML}
    </a>`))
  }

  $input.data('content-templates').forEach((hash) => {
    const $a = $('<a href="#" class="dropdown-item f-input-content-templates-dropdown__item"></a>')
    $a.text(hash.label)
    $a.data('value', hash.contents)
    $menu.append($a)
  })

  const $flex = $(`<div class="f-input-content-templates-dropdown">
    <span class="ml-3 small f-input-content-templates-dropdown__toggle dropdown-toggle" data-toggle="dropdown">${window.FolioConsole.translations.contentTemplates}
    </span>
  </div>`)

  $label.before($flex)
  $flex.prepend($label)
  $flex.append($menu)

  $menu.on('click', '.f-input-content-templates-dropdown__item', (e) => {
    e.preventDefault()

    const $this = $(e.currentTarget)

    const data = $this.data('value')

    if (!data) return

    if (!data.length) return

    $this
      .closest('.form-group, .f-c-translated-inputs')
      .find(window.Folio.Input.ContentTemplates.SELECTOR)
      .each((i, el) => {
        if (data[i]) {
          $(el).val(data[i]).trigger('change')
          if (el.dispatchEvent) {
            el.dispatchEvent(new Event('autosize:update'))
          }
        }
      })
  })
}

window.Folio.Input.ContentTemplates.unbind = (input) => {
  const $input = $(input)

  $input
    .closest('.form-group, .f-c-translated-inputs')
    .find('.f-input-content-templates-dropdown__menu')
    .off('click', '.f-input-content-templates-dropdown__item')
}

window.Folio.Input.framework(window.Folio.Input.ContentTemplates)
