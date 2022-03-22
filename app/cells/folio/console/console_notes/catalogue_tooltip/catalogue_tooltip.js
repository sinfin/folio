window.FolioConsole = window.FolioConsole || {}

window.FolioConsole.NotesCatalogueTooltip = {}

window.FolioConsole.NotesCatalogueTooltip.onSuccess = ($tooltip, res) => {
  // to be overriden in app
}

window.FolioConsole.NotesCatalogueTooltip.onChange = (e) => {
  const $input = $(e.target)
  const $tooltip = $input.closest('.f-c-console-notes-catalogue-tooltip')

  if ($tooltip.hasClass('f-c-console-notes-catalogue-tooltip--submitting')) return

  $tooltip.addClass('f-c-console-notes-catalogue-tooltip--submitting')

  $.ajax({
    url: $input.data('url'),
    method: "POST",
    data: {
      closed: $input.prop('checked'),
    },
    success: (res) => {
      if (res && res.data) {
        const $parent = $tooltip.closest(`.${$tooltip.data('class-name-parent')}`)
        $parent.trigger('folioConsole:success', res)

        if (res.data.catalogue_tooltip) {
          $tooltip
            .find('.f-c-console-notes-catalogue-tooltip__tooltip-inner')
            .replaceWith($(res.data.catalogue_tooltip).find('.f-c-console-notes-catalogue-tooltip__tooltip-inner'))
        } else {
          $tooltip.remove()
        }

        if (res.data.form) {
          const $formParent = $parent.find(`.${$tooltip.data('class-name-form-parent')}`)

          $formParent.find('.folio-react-wrap--notes-fields').each((i, el) => {
            window.FolioConsole.React.destroy(el)
          })

          $formParent.html(res.data.form)

          $formParent.find('.folio-react-wrap--notes-fields').each((i, el) => {
            window.FolioConsole.React.init(el)
          })
        }

        window.FolioConsole.NotesCatalogueTooltip.onSuccess($tooltip, res)
      }

      $tooltip.removeClass('f-c-console-notes-catalogue-tooltip--submitting')

      window.FolioConsole.flashMessageFromMeta(res)
    },
    error: (jxHr) => {
      if (jxHr.responseText) {
        try {
          window.FolioConsole.flashMessageFromApiErrors(JSON.parse(jxHr.responseText))
        } catch (_e) {}
      }

      $tooltip.removeClass('f-c-console-notes-catalogue-tooltip--submitting')
      $input.prop('checked', !$input.prop('checked'))
    }
  })
}

$(document).on('change',
               '.f-c-console-notes-catalogue-tooltip__note-input',
               window.FolioConsole.NotesCatalogueTooltip.onChange)
