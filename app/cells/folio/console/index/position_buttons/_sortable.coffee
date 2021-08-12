makeSortableUpdate = ($sortable) -> ->
  $sortable.trigger('folioConsoleUpdatedRowsOrder')
  positions = []
  $positions = $sortable.find('.f-c-index-position-buttons')
  $positions.addClass('folio-console-loading')

  $positions.each ->
    positions.push(parseInt($(this).find('.f-c-index-position-buttons__input').val()))

  if $sortable.find('.f-c-index-position-buttons--descending').length
    positions.sort (a, b) -> b - a
  else
    positions.sort (a, b) -> a - b

  data = {}
  $positions.each (i, el) ->
    position = positions[i]
    $position = $(el)
    $id = $position.find('.f-c-index-position-buttons__id')
    $input = $position.find('.f-c-index-position-buttons__input')

    id = $id.val()
    attribute = $id.data('attribute')

    data[id] = {}
    data[id][attribute] = position
    $input.val(position)

  ajax = $.ajax({
    url: $positions.first().data('url')
    type: 'POST'
    data: { positions: data }
  })

  ajax
    .fail ->
      $positions
        .removeClass('folio-console-loading')
        .addClass('f-c-index-position-buttons--failed')
    .fail (jxHr) ->
      $positions.trigger('folioConsoleFailedToPersistRowsOrder', response: jxHr.responseJSON)
    .done (res) ->
      $positions.removeClass('folio-console-loading')
      $positions.trigger('folioConsolePersistedRowsOrder', response: res)

window.folioConsoleBindIndexPositionSortable = ->
  $sortable = $('.f-c-catalogue__table')
  return if $sortable.closest('.f-c-catalogue--ancestry').length
  return if $sortable.find('.f-c-index-position-buttons__button--handle').length < 2
  $sortable.sortable
    axis: 'y'
    handle: '.f-c-index-position-buttons__button--handle'
    items: '.f-c-catalogue__row:not(:first-child)'
    placeholder: 'f-c-catalogue__sortable-placeholder'
    update: makeSortableUpdate($sortable)
    start: (e, ui) ->
      $another = $sortable.find('.f-c-catalogue__row:not(.ui-sortable-helper)')
      $cells = $another.find('.f-c-catalogue__cell')
      ui.item.find('.f-c-catalogue__cell').each (i, cell) ->
        $(cell).width($cells.eq(i).width())

    stop: (e, ui) ->
      ui.item.find('.f-c-catalogue__cell').css('width', '')

window.folioConsoleUnbindIndexPositionSortable = ->
  $sortable = $('.f-c-catalogue__table')
  $sortable.sortable("destroy") if $sortable.length and $sortable.sortable("instance")

$ window.folioConsoleBindIndexPositionSortable
