refreshCatalogue = ($catalogue) ->
  $catalogue.addClass('f-c-catalogue--loading')

  $.ajax
    url: window.location.href
    type: 'GET'
    success: (res) ->
      $res = $($.parseHTML(res))
      $catalogue.replaceWith $res.find('.f-c-catalogue--ancestry').first()
      window.folioLazyloadInstances.forEach (lazyLoad) -> lazyLoad.update()

    error: ->
      $catalogue.removeClass('f-c-catalogue--loading')

indexPositionClickAncestry = (e) ->
  e.preventDefault()
  $btn = $(this)
  $wrap = $btn.closest('.f-c-index-position-buttons')
  $row = $wrap.closest('.f-c-catalogue__row')
  $targetRow = null

  depth = $row.data('depth')

  switch $btn.data('direction')
    when 'up'
      $targets = $row.prevAll('.f-c-catalogue__row')
    when 'down'
      $targets = $row.nextAll('.f-c-catalogue__row')
    else
      return null

  $targets.each (i, target) ->
    $target = $(target)
    targetDepth = $target.data('depth')
    if targetDepth is depth
      $targetRow = $target
      return false
    else if targetDepth > depth
      return true
    else
      return false

  return unless $targetRow

  $id = $row.find('.f-c-index-position-buttons__id')
  attribute = $id.data('attribute')

  id = $row.find('.f-c-index-position-buttons__id').val()
  targetId = $targetRow.find('.f-c-index-position-buttons__id').val()

  data = {}
  data[id] = {}
  data[id][attribute] = $targetRow.find('.f-c-index-position-buttons__input').val()
  data[targetId] = {}
  data[targetId][attribute] = $row.find('.f-c-index-position-buttons__input').val()

  $catalogue = $row.closest('.f-c-catalogue')
  $catalogue.addClass('f-c-catalogue--loading')

  $.ajax
    url: $wrap.data('url')
    type: 'POST'
    data:
      positions: data
    success: ->
      refreshCatalogue($catalogue)
    error: ->
      $catalogue.removeClass('f-c-catalogue--loading')

$(document).on 'click', '.f-c-index-position-buttons--ancestry .f-c-index-position-buttons__button', indexPositionClickAncestry
