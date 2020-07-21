rowChildren = ($row) ->
  id = $row.find('.f-c-index-position__id').val()
  $row.nextAll("tr[data-parent='#{id}']")

switchRows = (tr) ->
  inputs =
    btn: tr.btn.find('.f-c-index-position__input')
    target: tr.target.find('.f-c-index-position__input')

  pos =
    btn: inputs.btn.val()
    target: inputs.target.val()

  inputs.btn.val pos.target
  inputs.target.val pos.btn

  # using past value
  if inputs.btn.closest('.f-c-index-position--descending').length
    if parseInt(pos.btn) > parseInt(pos.target)
      tr.btn.add(rowChildren(tr.btn)).insertAfter tr.target
    else
      tr.btn.add(rowChildren(tr.btn)).insertBefore tr.target
  else
    if parseInt(pos.btn) > parseInt(pos.target)
      tr.btn.add(rowChildren(tr.btn)).insertBefore tr.target
    else
      tr.btn.add(rowChildren(tr.btn)).insertAfter tr.target

  tr.btn.closest('.f-c-show-for-index').trigger('folioConsoleUpdatedRowsOrder')

getTr = ($btn) ->
  $btnTr = $btn.closest('.f-c-show-for__row')

  switch $btn.data('direction')
    when 'up'
      $targetTr = $btnTr.prevAll(".f-c-show-for__row:first")

    when 'down'
      $targetTr = $btnTr.nextAll(".f-c-show-for__row:first")

    else
      return null

  return null if $targetTr.length isnt 1

  {
    btn: $btnTr
    target: $targetTr
  }

post = (tr, url) ->
  data = {}

  $id = tr.btn.find('.f-c-index-position__id')
  attribute = $id.data('attribute')

  data[tr.btn.find('.f-c-index-position__id').val()] = {}
  data[tr.btn.find('.f-c-index-position__id').val()][attribute] = tr.target.find('.f-c-index-position__input').val()

  data[tr.target.find('.f-c-index-position__id').val()] = {}
  data[tr.target.find('.f-c-index-position__id').val()][attribute] = tr.btn.find('.f-c-index-position__input').val()

  tr.btn.addClass('folio-console-loading')
  tr.target.addClass('folio-console-loading')

  ajax = $.ajax({
    url: url
    type: 'POST'
    data: { positions: data }
  })

  ajax
    .done -> switchRows(tr)
    .always ->
      tr.btn.removeClass('folio-console-loading')
      tr.target.removeClass('folio-console-loading')

makeSortableUpdate = ($sortable) -> ->
  $sortable.trigger('folioConsoleUpdatedRowsOrder')
  positions = []
  $positions = $sortable.find('.f-c-index-position')
  $positions.addClass('folio-console-loading')

  $positions.each ->
    positions.push(parseInt($(this).find('.f-c-index-position__input').val()))

  if $sortable.find('.f-c-index-position--descending').length
    positions.sort (a, b) -> b - a
  else
    positions.sort (a, b) -> a - b

  data = {}
  $positions.each (i, el) ->
    position = positions[i]
    $position = $(el)
    $id = $position.find('.f-c-index-position__id')
    $input = $position.find('.f-c-index-position__input')

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
        .addClass('f-c-index-position--failed')
    .done ->
      $positions.removeClass('folio-console-loading')

indexPositionSortable = ->
  $sortable = $('.f-c-show-for-index')
  return if $sortable.find('.f-c-index-position__button--handle').length < 2
  $sortable.sortable
    axis: 'y'
    handle: '.f-c-index-position__button--handle'
    items: '.f-c-show-for__row:not(:first-child)'
    placeholder: 'f-c-show-for__sortable-placeholder'
    update: makeSortableUpdate($sortable)
    start: (e, ui) ->
      $another = $sortable.find('.f-c-show-for__row:not(.ui-sortable-helper)')
      $cells = $another.find('.f-c-show-for__cell')
      ui.item.find('.f-c-show-for__cell').each (i, cell) ->
        $(cell).width($cells.eq(i).width())

    stop: (e, ui) ->
      ui.item.find('.f-c-show-for__cell').css('width', '')

$(document).on 'click', '.f-c-index-position__button', (e) ->
  e.preventDefault()
  $btn = $(this)
  $btn.blur()
  tr = getTr($btn)
  return unless tr
  return if tr.btn.hasClass('folio-console-loading')
  return if tr.target.hasClass('folio-console-loading')
  post(tr, $btn.closest('.f-c-index-position').data('url'))

$ indexPositionSortable
