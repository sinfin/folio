// converted via https://coffeescript.org/#try
// once you update it, remove it from package.json standard js ignored files

(function () {
  let getTr, indexPositionClickRegular, post, switchRows

  switchRows = function (tr) {
    let inputs, pos
    inputs = {
      btn: tr.btn.find('.f-c-index-position-buttons__input'),
      target: tr.target.find('.f-c-index-position-buttons__input')
    }
    pos = {
      btn: inputs.btn.val(),
      target: inputs.target.val()
    }
    inputs.btn.val(pos.target)
    inputs.target.val(pos.btn)
    // using past value
    if (inputs.btn.closest('.f-c-index-position-buttons--descending').length) {
      if (parseInt(pos.btn) > parseInt(pos.target)) {
        tr.btn.insertAfter(tr.target)
      } else {
        tr.btn.insertBefore(tr.target)
      }
    } else {
      if (parseInt(pos.btn) > parseInt(pos.target)) {
        tr.btn.insertBefore(tr.target)
      } else {
        tr.btn.insertAfter(tr.target)
      }
    }
    return tr.btn.closest('.f-c-catalogue__table')[0].dispatchEvent(new window.CustomEvent('folioConsoleUpdatedRowsOrder', {
      bubbles: true
    }))
  }

  getTr = function ($btn) {
    let $btnTr, $targetTr
    $btnTr = $btn.closest('.f-c-catalogue__row')
    switch ($btn.data('direction')) {
      case 'up':
        $targetTr = $btnTr.prevAll('.f-c-catalogue__row:first')
        break
      case 'down':
        $targetTr = $btnTr.nextAll('.f-c-catalogue__row:first')
        break
      default:
        return null
    }
    if ($targetTr.length !== 1) {
      return null
    }
    return {
      btn: $btnTr,
      target: $targetTr
    }
  }

  post = function (tr, url) {
    let $id, ajax, attribute, data
    data = {}
    $id = tr.btn.find('.f-c-index-position-buttons__id')
    attribute = $id.data('attribute')
    data[tr.btn.find('.f-c-index-position-buttons__id').val()] = {}
    data[tr.btn.find('.f-c-index-position-buttons__id').val()][attribute] = tr.target.find('.f-c-index-position-buttons__input').val()
    data[tr.target.find('.f-c-index-position-buttons__id').val()] = {}
    data[tr.target.find('.f-c-index-position-buttons__id').val()][attribute] = tr.btn.find('.f-c-index-position-buttons__input').val()
    tr.btn.addClass('folio-console-loading')
    tr.target.addClass('folio-console-loading')
    ajax = window.jQuery.ajax({
      url,
      type: 'POST',
      data: {
        positions: data
      }
    })
    return ajax.done(function (res) {
      switchRows(tr)
      return tr.btn[0].dispatchEvent(new window.CustomEvent('folioConsolePersistedRowsOrder', {
        bubbles: true,
        detail: {
          response: res
        }
      }))
    }).fail(function (jxHr) {
      return tr.btn[0].dispatchEvent(new window.CustomEvent('folioConsoleFailedToPersistRowsOrder', {
        bubbles: true,
        detail: {
          response: jxHr.responseJSON
        }
      }))
    }).always(function () {
      tr.btn.removeClass('folio-console-loading')
      return tr.target.removeClass('folio-console-loading')
    })
  }

  indexPositionClickRegular = function (e) {
    let $btn, tr
    e.preventDefault()
    $btn = window.jQuery(this)
    $btn.blur()
    tr = getTr($btn)
    if (!tr) {
      return
    }
    if (tr.btn.hasClass('folio-console-loading')) {
      return
    }
    if (tr.target.hasClass('folio-console-loading')) {
      return
    }
    return post(tr, $btn.closest('.f-c-index-position-buttons').data('url'))
  }

  window.jQuery(document).on('click', '.f-c-index-position-buttons--regular .f-c-index-position-buttons__button', indexPositionClickRegular)
})()
