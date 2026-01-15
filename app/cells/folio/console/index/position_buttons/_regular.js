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

  postBoundary = function ($btn, $row, direction) {
    const $catalogue = $row.closest('.f-c-catalogue')
    const prefix = direction === 'up' ? 'prev' : 'next'
    const boundaryId = $catalogue.data('f-c-catalogue-' + prefix + '-boundary-id')
    const boundaryPosition = $catalogue.data('f-c-catalogue-' + prefix + '-boundary-position')

    if (!boundaryId || boundaryPosition == null) return

    const $id = $row.find('.f-c-index-position-buttons__id')
    const attribute = $id.data('attribute')
    const currentId = $id.val()
    const currentPosition = $row.find('.f-c-index-position-buttons__input').val()

    const data = {}
    data[currentId] = {}
    data[currentId][attribute] = boundaryPosition
    data[boundaryId] = {}
    data[boundaryId][attribute] = currentPosition

    $row.addClass('folio-console-loading')

    window.jQuery.ajax({
      url: $btn.closest('.f-c-index-position-buttons').data('url'),
      type: 'POST',
      data: { positions: data }
    }).done(function () {
      const url = new window.URL(window.location.href)
      const page = parseInt(url.searchParams.get('page')) || 1
      const newPage = direction === 'up' ? page - 1 : page + 1

      if (newPage <= 1) {
        url.searchParams.delete('page')
      } else {
        url.searchParams.set('page', String(newPage))
      }

      const newUrl = url.toString()

      if (direction === 'up') {
        window.sessionStorage.setItem('f-c-catalogue-boundary-scroll', JSON.stringify({
          url: newUrl,
          timestamp: Date.now()
        }))
      }

      window.location.href = newUrl
    }).fail(function (jxHr) {
      $row.removeClass('folio-console-loading')
      $row[0].dispatchEvent(new window.CustomEvent('folioConsoleFailedToPersistRowsOrder', {
        bubbles: true,
        detail: { response: jxHr.responseJSON }
      }))
    })
  }

  indexPositionClickRegular = function (e) {
    let $btn, tr
    e.preventDefault()
    $btn = window.jQuery(this)
    $btn.blur()
    tr = getTr($btn)

    if (!tr) {
      // Cross-page boundary movement
      return postBoundary($btn, $btn.closest('.f-c-catalogue__row'), $btn.data('direction'))
    }

    if (tr.btn.hasClass('folio-console-loading')) return
    if (tr.target.hasClass('folio-console-loading')) return

    return post(tr, $btn.closest('.f-c-index-position-buttons').data('url'))
  }

  window.jQuery(document).on('click', '.f-c-index-position-buttons--regular .f-c-index-position-buttons__button', indexPositionClickRegular)

  // Check session storage and scroll to bottom if recent boundary navigation
  window.jQuery(function () {
    const stored = window.sessionStorage.getItem('f-c-catalogue-boundary-scroll')
    if (!stored) return

    let data
    try {
      data = JSON.parse(stored)
    } catch (e) {
      return
    }

    const now = Date.now()
    const age = now - data.timestamp
    const currentUrl = window.location.href

    if (age < 30000 && data.url === currentUrl) {
      // Find overflow parent
      const $catalogue = window.jQuery('.f-c-catalogue').first()
      let $scrollParent = $catalogue.parent()
      let foundScrollParent = false

      while ($scrollParent.length && !$scrollParent.is('body, html')) {
        const overflow = window.getComputedStyle($scrollParent[0]).overflow
        const overflowY = window.getComputedStyle($scrollParent[0]).overflowY

        if (overflow === 'auto' || overflow === 'scroll' || overflowY === 'auto' || overflowY === 'scroll') {
          foundScrollParent = true
          $scrollParent[0].scrollTop = $scrollParent[0].scrollHeight
          break
        }

        $scrollParent = $scrollParent.parent()
      }

      if (!foundScrollParent) {
        window.scrollTo(0, document.body.scrollHeight)
      }

      window.sessionStorage.removeItem('f-c-catalogue-boundary-scroll')
    } else if (age >= 30000) {
      window.sessionStorage.removeItem('f-c-catalogue-boundary-scroll')
    }
  })
})()
