window.FolioConsole = window.FolioConsole || {}

window.FolioConsole.Index = window.FolioConsole.Index || {}

window.FolioConsole.Index.PositionButtons = window.FolioConsole.Index.PositionButtons || {}

window.FolioConsole.Index.PositionButtons.Sortable = window.FolioConsole.Index.PositionButtons.Sortable || {}

window.FolioConsole.Index.PositionButtons.Sortable.makeSortableUpdate = ($sortable) => {
  return () => {
    $sortable.trigger('folioConsoleUpdatedRowsOrder')

    let positions = []
    const $positions = $sortable.find('.f-c-index-position-buttons')

    $positions.addClass('folio-console-loading')
    $positions.each((i, el) => { positions.push(parseInt($(el).find('.f-c-index-position-buttons__input').val())) })

    if ($sortable.find('.f-c-index-position-buttons--descending').length) {
      positions.sort(function(a, b) {
        return b - a
      })
    } else {
      positions.sort(function(a, b) {
        return a - b
      })
    }

    let data = {}

    $positions.each((i, el) => {
      const position = positions[i]
      const $position = $(el)
      const $id = $position.find('.f-c-index-position-buttons__id')
      const $input = $position.find('.f-c-index-position-buttons__input')
      const id = $id.val()
      const attribute = $id.data('attribute')

      data[id] = {}
      data[id][attribute] = position
      return $input.val(position)
    })

    const ajax = $.ajax({
      url: $positions.first().data('url'),
      type: 'POST',
      data: {
        positions: data
      }
    })

    return ajax.fail(() => {
      return $positions.removeClass('folio-console-loading').addClass('f-c-index-position-buttons--failed')
    }).fail((jxHr) => {
      return $positions.trigger('folioConsoleFailedToPersistRowsOrder', {
        response: jxHr.responseJSON
      })
    }).done((res) => {
      $positions.removeClass('folio-console-loading')
      return $positions.trigger('folioConsolePersistedRowsOrder', {
        response: res
      })
    })
  }
}

window.FolioConsole.Index.PositionButtons.Sortable.bind = function() {
  const $sortable = $('.f-c-catalogue__table')

  if ($sortable.closest('.f-c-catalogue--ancestry').length) return
  if ($sortable.find('.f-c-index-position-buttons__button--handle').length < 2) return

  $sortable.sortable({
    axis: 'y',
    handle: '.f-c-index-position-buttons__button--handle',
    items: '.f-c-catalogue__row:not(:first-child)',
    placeholder: 'f-c-catalogue__sortable-placeholder',
    update: window.FolioConsole.Index.PositionButtons.Sortable.makeSortableUpdate($sortable),
    start: function(e, ui) {
      const $another = $sortable.find('.f-c-catalogue__row:not(.ui-sortable-helper)')
      const $cells = $another.find('.f-c-catalogue__cell')

      ui.item.find('.f-c-catalogue__cell').each((i, cell) => {
        $(cell).width($cells.eq(i).width())
      })
    },
    stop: (e, ui) => {
      ui.item.find('.f-c-catalogue__cell').css('width', '')
    }
  })

  return $sortable
}

window.FolioConsole.Index.PositionButtons.Sortable.unbind = function() {
  const $sortable = $('.f-c-catalogue__table')
  if ($sortable.length && $sortable.sortable("instance")) {
    $sortable.sortable("destroy")
  }
}

$(window.FolioConsole.Index.PositionButtons.Sortable.bind)
