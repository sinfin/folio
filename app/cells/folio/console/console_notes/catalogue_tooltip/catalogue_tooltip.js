window.FolioConsole = window.FolioConsole || {}

window.FolioConsole.NotesCatalogueTooltip = {}

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
        if (res.data.catalogue_tooltip) {
          $tooltip
            .find('.f-c-console-notes-catalogue-tooltip__tooltip-inner')
            .replaceWith($(res.data.catalogue_tooltip).find('.f-c-console-notes-catalogue-tooltip__tooltip-inner'))
        } else {
          $tooltip.remove()
        }
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
