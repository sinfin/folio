rowChildren = ($row) ->
  id = $row.find('.folio-console-input-id').val()
  $row.nextAll("tr[data-parent='#{id}']")

switchRows = (tr) ->
  inputs =
    btn: tr.btn.find('.folio-console-input-position')
    target: tr.target.find('.folio-console-input-position')

  pos =
    btn: inputs.btn.val()
    target: inputs.target.val()

  inputs.btn.val pos.target
  inputs.target.val pos.btn

  # using past value
  if parseInt(pos.btn) > parseInt(pos.target)
    tr.btn.add(rowChildren(tr.btn)).insertBefore tr.target
  else
    tr.btn.add(rowChildren(tr.btn)).insertAfter tr.target

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

  data[tr.btn.find('.folio-console-input-id').val()] =
    position: tr.target.find('.folio-console-input-position').val()

  data[tr.target.find('.folio-console-input-id').val()] =
    position: tr.btn.find('.folio-console-input-position').val()

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

$(document).on 'click', '.f-c-index-position__button', (e) ->
  e.preventDefault()
  $btn = $(this)
  $btn.blur()
  tr = getTr($btn)
  return unless tr
  return if tr.btn.hasClass('folio-console-loading')
  return if tr.target.hasClass('folio-console-loading')
  post(tr, $btn.data('url'))
