window.FolioConsole = window.FolioConsole || {}

window.FolioConsole.NotesCatalogueTooltip = window.FolioConsole.NotesCatalogueTooltip || {}

window.FolioConsole.NotesCatalogueTooltip.onSuccess = (tooltipEl, res) => {
  // Override in host app when needed
}

window.Folio.Stimulus.register('f-c-console-notes-catalogue-tooltip', class extends window.Stimulus.Controller {
  onNoteChange (event) {
    const input = event.target

    if (!input.classList.contains('f-c-console-notes-catalogue-tooltip__note-input')) return

    const tooltip = this.element

    if (tooltip.classList.contains('f-c-console-notes-catalogue-tooltip--submitting')) return

    tooltip.classList.add('f-c-console-notes-catalogue-tooltip--submitting')

    window.Folio.Api.apiPost(input.dataset.url, {
      closed: input.checked
    }).then((res) => {
      if (res && res.data) {
        const parentClass = tooltip.dataset.classNameParent
        const formParentClass = tooltip.dataset.classNameFormParent
        const parent = parentClass ? tooltip.closest(`.${parentClass}`) : null

        if (parent) {
          parent.dispatchEvent(new CustomEvent('folioConsole:success', {
            bubbles: true,
            detail: res
          }))

          if (window.jQuery) {
            window.jQuery(parent).trigger('folioConsole:success', res)
          }
        }

        if (res.data.catalogue_tooltip) {
          const tpl = document.createElement('template')
          tpl.innerHTML = res.data.catalogue_tooltip.trim()
          const newEl = tpl.content.firstElementChild

          if (newEl) {
            tooltip.replaceWith(newEl)
          } else {
            tooltip.remove()
          }
        } else {
          tooltip.remove()
        }

        if (res.data.form && parent) {
          const formParent = formParentClass ? parent.querySelector(`.${formParentClass}`) : null

          if (formParent) {
            for (const el of formParent.querySelectorAll('.folio-react-wrap--notes-fields')) {
              window.FolioConsole.React.destroy(el)
            }

            formParent.innerHTML = res.data.form

            for (const el of formParent.querySelectorAll('.folio-react-wrap--notes-fields')) {
              window.FolioConsole.React.init(el)
            }
          }
        }

        window.FolioConsole.NotesCatalogueTooltip.onSuccess(tooltip, res)
      }
    }).catch((err) => {
      const json = err.responseData
      if (json && Array.isArray(json.errors)) {
        const content = json.errors.map((obj) => `${obj.title} - ${obj.detail}`).join('<br>')
        document.dispatchEvent(new CustomEvent('folio:flash', {
          bubbles: true,
          detail: { flash: { content, variant: 'danger' } }
        }))
      }

      input.checked = !input.checked
    }).finally(() => {
      tooltip.classList.remove('f-c-console-notes-catalogue-tooltip--submitting')
    })
  }
})
