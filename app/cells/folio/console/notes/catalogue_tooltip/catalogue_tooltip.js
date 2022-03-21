window.FolioConsole = window.FolioConsole || {}

window.FolioConsole.NotesCatalogueTooltip = {}

window.FolioConsole.NotesCatalogueTooltip.onChange = (e) => {
  const $input = $(e.target)
  const $tooltip = $input.closest('.f-c-notes-catalogue-tooltip')

  if ($tooltip.hasClass('f-c-notes-catalogue-tooltip--submitting')) return

  $tooltip.addClass('f-c-notes-catalogue-tooltip--submitting')

  $.ajax({
    url: $input.data('url'),
    method: "POST",
    data: {
      closed: $input.prop('checked'),
    },
    success: (res) => {
      console.log(res)
    },
    error: (jxHr) => {
      if (jxHr.responseText) {
        try {
          window.FolioConsole.flashMessageFromApiErrors(JSON.parse(jxHr.responseText))
        } catch (_e) {}
      }

      $tooltip.removeClass('f-c-notes-catalogue-tooltip--submitting')
      $input.prop('checked', !$input.prop('checked'))
    }
  })
}

$(document).on('change',
               '.f-c-notes-catalogue-tooltip__note-input',
               window.FolioConsole.NotesCatalogueTooltip.onChange)
