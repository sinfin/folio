// converted via https://coffeescript.org/#try
// once you update it, remove it from package.json standard js ignored files

(function () {
  let indexPositionClickAncestry, refreshCatalogue

  refreshCatalogue = function ($catalogue) {
    $catalogue.addClass('f-c-catalogue--loading')
    return window.jQuery.ajax({
      url: window.location.href,
      type: 'GET',
      success: function (res) {
        let $res
        $res = window.jQuery($.parseHTML(res))
        $catalogue.replaceWith($res.find('.f-c-catalogue--ancestry').first())
      },
      error: function () {
        return $catalogue.removeClass('f-c-catalogue--loading')
      }
    })
  }

  indexPositionClickAncestry = function (e) {
    let $btn, $catalogue, $id, $row, $targetRow, $targets, $wrap, attribute, data, depth, id, targetId
    e.preventDefault()
    $btn = window.jQuery(this)
    $wrap = $btn.closest('.f-c-index-position-buttons')
    $row = $wrap.closest('.f-c-catalogue__row')
    $targetRow = null
    depth = $row.data('depth')
    switch ($btn.data('direction')) {
      case 'up':
        $targets = $row.prevAll('.f-c-catalogue__row')
        break
      case 'down':
        $targets = $row.nextAll('.f-c-catalogue__row')
        break
      default:
        return null
    }
    $targets.each(function (i, target) {
      let $target, targetDepth
      $target = window.jQuery(target)
      targetDepth = $target.data('depth')
      if (targetDepth === depth) {
        $targetRow = $target
        return false
      } else if (targetDepth > depth) {
        return true
      } else {
        return false
      }
    })
    if (!$targetRow) {
      return
    }
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
    return window.jQuery.ajax({
      url: $wrap.data('url'),
      type: 'POST',
      data: {
        positions: data
      },
      success: function () {
        return refreshCatalogue($catalogue)
      },
      error: function () {
        return $catalogue.removeClass('f-c-catalogue--loading')
      }
    })
  }

  window.jQuery(document).on('click', '.f-c-index-position-buttons--ancestry .f-c-index-position-buttons__button', indexPositionClickAncestry)
})()
