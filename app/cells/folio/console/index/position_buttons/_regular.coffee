switchRows = (tr) ->
  inputs =
    btn: tr.btn.find('.f-c-index-position-buttons__input')
    target: tr.target.find('.f-c-index-position-buttons__input')

  pos =
    btn: inputs.btn.val()
    target: inputs.target.val()

  inputs.btn.val pos.target
  inputs.target.val pos.btn

  # using past value
  if inputs.btn.closest('.f-c-index-position-buttons--descending').length
    if parseInt(pos.btn) > parseInt(pos.target)
      tr.btn.insertAfter tr.target
    else
      tr.btn.insertBefore tr.target
  else
    if parseInt(pos.btn) > parseInt(pos.target)
      tr.btn.insertBefore tr.target
    else
      tr.btn.insertAfter tr.target

  tr.btn.closest('.f-c-catalogue__table').trigger('folioConsoleUpdatedRowsOrder')

getTr = ($btn) ->
  $btnTr = $btn.closest('.f-c-catalogue__row')

  switch $btn.data('direction')
    when 'up'
      $targetTr = $btnTr.prevAll(".f-c-catalogue__row:first")

    when 'down'
      $targetTr = $btnTr.nextAll(".f-c-catalogue__row:first")

    else
      return null

  return null if $targetTr.length isnt 1

  {
    btn: $btnTr
    target: $targetTr
  }

post = (tr, url) ->
  data = {}

  $id = tr.btn.find('.f-c-index-position-buttons__id')
  attribute = $id.data('attribute')

  data[tr.btn.find('.f-c-index-position-buttons__id').val()] = {}
  data[tr.btn.find('.f-c-index-position-buttons__id').val()][attribute] = tr.target.find('.f-c-index-position-buttons__input').val()

  data[tr.target.find('.f-c-index-position-buttons__id').val()] = {}
  data[tr.target.find('.f-c-index-position-buttons__id').val()][attribute] = tr.btn.find('.f-c-index-position-buttons__input').val()

  tr.btn.addClass('folio-console-loading')
  tr.target.addClass('folio-console-loading')

  ajax = $.ajax({
    url: url
    type: 'POST'
    data: { positions: data }
  })

  ajax
    .done (res) ->
      switchRows(tr)
      tr.btn.trigger('folioConsolePersistedRowsOrder', response: res)
    .fail (jxHr) ->
      tr.btn.trigger('folioConsoleFailedToPersistRowsOrder', response: jxHr.responseJson)
    .always ->
      tr.btn.removeClass('folio-console-loading')
      tr.target.removeClass('folio-console-loading')

indexPositionClickRegular = (e) ->
  e.preventDefault()
  $btn = $(this)
  $btn.blur()
  tr = getTr($btn)
  return unless tr
  return if tr.btn.hasClass('folio-console-loading')
  return if tr.target.hasClass('folio-console-loading')
  post(tr, $btn.closest('.f-c-index-position-buttons').data('url'))

$(document).on 'click', '.f-c-index-position-buttons--regular .f-c-index-position-buttons__button', indexPositionClickRegular
