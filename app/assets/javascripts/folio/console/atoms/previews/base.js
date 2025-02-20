//= require jquery
//= require jquery-ui/jquery-ui
//= require justified-layout
//= require folio/atoms
//= require folio/message_bus
//= require folio/lazyload
//= require folio/debounce
//= require folio/lightbox
//= require folio/stimulus
//= require folio/console/atoms/previews/main_app
//= require folio/console/file/preview_reloader/preview_reloader

// converted via https://coffeescript.org/#try
// once you update it, remove it from package.json standard js ignored files

// see app/cells/folio/console/atoms/previews/previews.js
// code is here as it would get included by a wildcard import

(function () {
  let bindSortables, closeMobileControls, handleArrowClick, handleEditClick, handleInsertClick, handleMobileclick, handleNewHtml, handleOverlayClick, handleRemoveClick, handleSplitableJoinTriggerClick, handleWillReplaceHtml, hideInsert, lazyloadAll, receiveMessage, selectLocale, sendMediaQueryRequest, sendResizeMessage, setMediaQuery, showInsertHint, unbindSortables, updateLabel, updatePerex

  lazyloadAll = function () {
    return window.folioLazyloadInstances.forEach(function (instance) {
      instance.update()
      return instance.loadAll()
    })
  }

  selectLocale = function (locale) {
    return window.jQuery('.f-c-atoms-previews__locale').each(function () {
      let $this
      $this = window.jQuery(this)
      return $this.prop('hidden', $this.data('locale') && $this.data('locale') !== locale)
    })
  }

  closeMobileControls = function ($el) {
    return $el.closest('.f-c-atoms-previews__controls--active').removeClass('f-c-atoms-previews__controls--active')
  }

  handleArrowClick = function (e) {
    let $next, $prev, $this, $wrap, action, data, indices, nextIndices, targetIndex
    e.preventDefault()
    $this = window.jQuery(this)
    closeMobileControls($this)
    $wrap = $this.closest('.f-c-atoms-previews__preview')
    indices = $wrap.data('indices')
    if ($this.hasClass('f-c-atoms-previews__button--arrow-up')) {
      $prev = $wrap.prevAll('.f-c-atoms-previews__preview').first()
      if ($prev.length === 0) {
        return
      }
      targetIndex = $prev.data('indices')[0]
      action = 'prepend'
    } else {
      $next = $wrap.nextAll('.f-c-atoms-previews__preview').first()
      if ($next.length === 0) {
        return
      }
      nextIndices = $next.data('indices')
      targetIndex = nextIndices[nextIndices.length - 1]
      action = 'append'
    }
    data = {
      rootKey: $wrap.data('root-key'),
      indices,
      targetIndex,
      action,
      type: 'moveAtomsToIndex'
    }
    return window.top.postMessage(data, window.origin)
  }

  handleEditClick = function (e) {
    let $this, $wrap, data
    e.preventDefault()
    $this = window.jQuery(this)
    closeMobileControls($this)
    $wrap = $this.closest('.f-c-atoms-previews__preview')
    if ($wrap.length) {
      if (!$wrap.data('editable')) {
        return
      }
      data = {
        rootKey: $wrap.data('root-key'),
        indices: $wrap.data('indices'),
        type: 'editAtoms'
      }
      return window.top.postMessage(data, window.origin)
    } else {
      $wrap = $this.closest('.f-c-atoms-previews__setting')
      if ($wrap.length) {
        data = {
          type: 'editSetting',
          setting: $wrap.data('setting-key'),
          locale: $wrap.closest('.f-c-atoms-previews__locale').data('locale')
        }
        return window.top.postMessage(data, window.origin)
      }
    }
  }

  handleOverlayClick = function (e) {
    let $controls
    $controls = window.jQuery(this).closest('.f-c-atoms-previews__controls--active')
    if ($controls.length) {
      e.preventDefault()
      return $controls.removeClass('f-c-atoms-previews__controls--active')
    } else {
      return handleEditClick.call(this, e)
    }
  }

  handleRemoveClick = function (e) {
    let $this, $wrap, data
    e.preventDefault()
    $this = window.jQuery(this)
    closeMobileControls($this)
    if (window.confirm(window.FolioConsole.translations.removePrompt)) {
      $wrap = window.jQuery(this).closest('.f-c-atoms-previews__preview')
      data = {
        rootKey: $wrap.data('root-key'),
        indices: $wrap.data('indices'),
        type: 'removeAtoms'
      }
      return window.top.postMessage(data, window.origin)
    }
  }

  handleMobileclick = function (e) {
    e.preventDefault()
    e.stopPropagation()
    return window.jQuery(this).closest('.f-c-atoms-previews__controls').addClass('f-c-atoms-previews__controls--active')
  }

  showInsertHint = function (e) {
    e.preventDefault()
    return window.jQuery(this).closest('.f-c-atoms-previews__insert').addClass('f-c-atoms-previews__insert--active')
  }

  hideInsert = function ($insert) {
    return $insert.removeClass('f-c-atoms-previews__insert--active')
  }

  handleInsertClick = function (e) {
    let $a, $insert, $locale, $wrap, action, data, indices, rootKey
    e.preventDefault()
    $a = window.jQuery(this)
    $insert = $a.closest('.f-c-atoms-previews__insert')
    hideInsert($insert)
    $wrap = $insert.next('.f-c-atoms-previews__preview')
    indices = $wrap.data('indices')
    action = 'splice'
    if ($wrap.length === 0) {
      $wrap = $insert.prev('.f-c-atoms-previews__preview')
      if ($wrap.length === 0) {
        action = 'prepend'
        indices = [0]
      } else {
        action = 'append'
        indices = $wrap.data('indices')
      }
    }
    $locale = $a.closest('.f-c-atoms-previews__locale')
    rootKey = $locale.data('root-key')
    data = {
      type: 'newAtoms',
      rootKey,
      action,
      indices,
      atomType: $a.data('type'),
      contentable: $a.attr('data-contentable') === 'true'
    }
    return window.top.postMessage(data, window.origin)
  }

  handleSplitableJoinTriggerClick = function (e) {
    let $insert, $locale, $next, $previous, $trigger, data, field, indices, rootKey
    e.preventDefault()
    e.stopPropagation()
    $trigger = window.jQuery(this)
    $insert = $trigger.closest('.f-c-atoms-previews__insert')
    hideInsert($insert)
    $previous = $insert.prev('.f-c-atoms-previews__preview')
    $next = $insert.next('.f-c-atoms-previews__preview')
    field = $previous.data('atom-splittable')
    if (field !== $next.data('atom-splittable')) {
      return
    }
    indices = []
    $previous.data('indices').forEach((index) => {
      return indices.push(index)
    })
    $next.data('indices').forEach((index) => {
      return indices.push(index)
    })
    $locale = $trigger.closest('.f-c-atoms-previews__locale')
    rootKey = $locale.data('root-key')
    data = {
      type: 'splittableJoinAtomsPrompt',
      rootKey,
      indices,
      field
    }
    return window.top.postMessage(data, window.origin)
  }

  sendResizeMessage = function () {
    let data
    data = {
      type: 'setHeight'
    }
    return window.top.postMessage(data, window.origin)
  }

  sendMediaQueryRequest = function () {
    let data
    data = {
      type: 'requestMediaQuery'
    }
    return window.top.postMessage(data, window.origin)
  }

  setMediaQuery = function (width) {
    width || (width = window.jQuery(window).width())
    if (width > 991) {
      return window.jQuery('html').removeClass('media-breakpoint-down-md').addClass('media-breakpoint-up-lg')
    } else {
      return window.jQuery('html').addClass('media-breakpoint-down-md').removeClass('media-breakpoint-up-lg')
    }
  }

  bindSortables = function () {
    let scrollSensitivity
    scrollSensitivity = Math.max(200, window.jQuery(window).height() / 6)
    return window.jQuery('.f-c-atoms-previews__locale').each(function () {
      let $this
      $this = window.jQuery(this)
      return $this.sortable({
        axis: 'y',
        helper: 'clone',
        handle: '.f-c-atoms-previews__button--handle',
        items: '.f-c-atoms-previews__preview',
        placeholder: 'f-c-atoms-previews__preview-placeholder',
        scrollSensitivity,
        tolerance: 'pointer',
        update: function (e, ui) {
          let $next, $prev, $wrap, action, data, indices, prevIndices, targetIndex
          $wrap = ui.item
          indices = $wrap.data('indices')
          $prev = $wrap.prevAll('.f-c-atoms-previews__preview').first()
          if ($prev.length) {
            prevIndices = $prev.data('indices')
            targetIndex = prevIndices[prevIndices.length - 1]
            action = 'append'
          } else {
            $next = $wrap.nextAll('.f-c-atoms-previews__preview').first()
            if ($next.length === 0) {
              return
            }
            targetIndex = $next.data('indices')[0]
            action = 'prepend'
          }
          data = {
            rootKey: $wrap.data('root-key'),
            indices,
            targetIndex,
            action,
            type: 'moveAtomsToIndex'
          }
          return window.top.postMessage(data, window.origin)
        },
        start: function (e, ui) {
          let height, scale
          ui.placeholder.html(ui.item.html())
          height = ui.placeholder.height()
          scale = Math.round(100 * 100 / height) / 100
          ui.placeholder.find('.f-c-atoms-previews__preview-inner').css('transform', `scale(${scale})`)
          ui.placeholder.addClass('f-c-atoms-previews__preview-placeholder--scaled')
          return $this.addClass('ui-sortable--dragging')
        },
        stop: function (e, ui) {
          return $this.removeClass('ui-sortable--dragging')
        }
      })
    })
  }

  unbindSortables = function () {
    return window.jQuery('.f-c-atoms-previews__locale.ui-sortable').each(function () {
      return window.jQuery(this).sortable('destroy')
    })
  }

  handleNewHtml = function () {
    bindSortables()
    lazyloadAll()
    sendResizeMessage()
    return window.jQuery(document).trigger('folioConsoleReplacedHtml')
  }

  handleWillReplaceHtml = function () {
    unbindSortables()
    return window.jQuery(document).trigger('folioConsoleWillReplaceHtml')
  }

  updateLabel = function (locale, value) {
    let $label
    if (locale) {
      $label = window.jQuery(`.f-c-atoms-previews__locale[data-locale='${locale}'] .f-c-atoms-previews__label`)
    } else {
      $label = window.jQuery('.f-c-atoms-previews__locale .f-c-atoms-previews__label')
    }
    $label.prop('hidden', value.length === 0)
    $label.find('.f-c-atoms-previews__label-h1').text(value)
    return window.jQuery(document).trigger('folioConsoleUpdatedLabel')
  }

  updatePerex = function (locale, value) {
    let $perex
    if (locale) {
      $perex = window.jQuery(`.f-c-atoms-previews__locale[data-locale='${locale}'] .f-c-atoms-previews__perex`)
    } else {
      $perex = window.jQuery('.f-c-atoms-previews__locale .f-c-atoms-previews__perex')
    }
    $perex.prop('hidden', value.length === 0)
    $perex.find('.f-c-atoms-previews__perex-p').html(value)
    return window.jQuery(document).trigger('folioConsoleUpdatedPerex')
  }

  window.jQuery(document).on('click', '.f-c-atoms-previews__button--arrow', handleArrowClick).on('click', '.f-c-atoms-previews__button--edit', handleEditClick).on('click', '.f-c-atoms-previews-broken-preview__button--edit', handleEditClick).on('click', '.f-c-atoms-previews__button--settings', handleEditClick).on('click', '.f-c-atoms-previews__controls-overlay', handleOverlayClick).on('click', '.f-c-atoms-previews__button--remove', handleRemoveClick).on('click', '.f-c-atoms-previews-broken-preview__button--destroy', handleRemoveClick).on('click', '.f-c-atoms-previews__insert-a', handleInsertClick).on('click', '.f-c-atoms-previews__insert-splittable-join-trigger', handleSplitableJoinTriggerClick).on('click', '.f-c-atoms-previews__insert-hint', showInsertHint).on('click', '.f-c-atoms-previews__controls-mobile-overlay', handleMobileclick).on('click', 'a, button', function (e) {
    return e.preventDefault()
  }).on('form', 'submit', function (e) {
    return e.preventDefault()
  }).on('mouseleave', '.f-c-atoms-previews__insert', function (e) {
    return hideInsert(window.jQuery(this))
  })

  window.jQuery(window).on('resize orientationchange', sendResizeMessage)

  receiveMessage = function (e) {
    if (e.origin !== window.origin) {
      return
    }
    switch (e.data.type) {
      case 'replacedHtml':
        return handleNewHtml()
      case 'willReplaceHtml':
        return handleWillReplaceHtml()
      case 'selectLocale':
        return selectLocale(e.data.locale)
      case 'setMediaQuery':
        return setMediaQuery(e.data.width)
      case 'updateLabel':
        return updateLabel(e.data.locale, e.data.value)
      case 'updatePerex':
        return updatePerex(e.data.locale, e.data.value)
    }
  }

  window.addEventListener('message', receiveMessage, false)

  window.jQuery(function () {
    setMediaQuery()
    handleNewHtml()
    sendMediaQueryRequest()
    return window.jQuery(window).one('load', function () {
      return sendResizeMessage()
    })
  })
})()
