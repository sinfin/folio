// converted via https://coffeescript.org/#try
// once you update it, remove it from package.json standard js ignored files

(function () {
  let editSetting, receiveMessage, selectTab, sendMessage, setHeight

  sendMessage = function (data) {
    return window.jQuery('.f-c-simple-form-with-atoms__iframe, .f-c-merges-form-row__atoms-iframe').each(function () {
      return this.contentWindow.postMessage(data, window.origin)
    })
  }

  window.jQuery(document).one('click', '.f-c-simple-form-with-atoms__form', function (e) {
    return window.jQuery('.f-c-simple-form-with-atoms').addClass('f-c-simple-form-with-atoms--expanded-form')
  }).on('click', '.f-c-simple-form-with-atoms__overlay-dismiss', function (e) {
    e.preventDefault()
    return window.postMessage({
      type: 'closeForm'
    }, window.origin)
  }).on('click', '.f-c-simple-form-with-atoms__form-toggle, .f-c-simple-form-with-atoms__title--clickable', function (e) {
    e.preventDefault()
    return window.jQuery('.f-c-simple-form-with-atoms').toggleClass('f-c-simple-form-with-atoms--expanded-form')
  }).on('keyup', '.f-c-js-atoms-placement-label', function (e) {
    let $this
    e.preventDefault()
    $this = window.jQuery(this)
    return sendMessage({
      type: 'updateLabel',
      locale: $this.data('locale') || null,
      value: $this.val()
    })
  }).on('keyup', '.f-c-js-atoms-placement-perex', function (e) {
    let $this
    e.preventDefault()
    $this = window.jQuery(this)
    return sendMessage({
      type: 'updatePerex',
      locale: $this.data('locale') || null,
      value: $this.val()
    })
  }).on('change folioConsoleCustomChange folioCustomChange', '.f-c-js-atoms-placement-setting', function (e) {
    window.postMessage({
      type: 'refreshPreview'
    }, window.origin)
    // used to refresh react select async options
    return window.setTimeout(function () {
      return window.jQuery(document).trigger('folioAtomSettingChanged')
    }, 0)
  })

  selectTab = function ($el) {
    let $tab, id
    $tab = $el.closest('.tab-pane')
    if ($tab.length && !$tab.hasClass('active')) {
      id = $tab.attr('id')
      return window.jQuery('.nav-tabs .nav-link').filter(function () {
        return this.href.split('#').pop() === id
      }).click()
    }
  }

  editSetting = function (locale, key) {
    let $scroll, $setting, callback
    window.jQuery('.f-c-simple-form-with-atoms').addClass('f-c-simple-form-with-atoms--expanded-form')
    if (key === 'label') {
      $setting = window.jQuery('.f-c-js-atoms-placement-label')
    } else if (key === 'perex') {
      $setting = window.jQuery('.f-c-js-atoms-placement-perex')
    } else {
      $setting = window.jQuery('.f-c-js-atoms-placement-setting').filter(`[data-atom-setting='${key}']`)
    }
    if (locale) {
      $setting = $setting.filter(`[data-locale='${locale}']`)
    }
    if ($setting.length) {
      selectTab($setting)
      $scroll = window.jQuery(document.documentElement)
      callback = function () {
        setTimeout(function () {
          return $setting.addClass('f-c-js-atoms-placement-setting--highlighted')
        }, 0)
        setTimeout(function () {
          return $setting.removeClass('f-c-js-atoms-placement-setting--highlighted')
        }, 300)
        if ($setting.hasClass('selectized')) {
          return $setting[0].selectize.focus()
        } else if ($setting.hasClass('redactor-source')) {
          return $R($setting[0], 'editor.startFocus')
        } else {
          return $setting.focus()
        }
      }
      if ($scroll.scrollTop() > window.jQuery(window).height() / 2) {
        return $scroll.animate({
          scrollTop: 0
        }, callback)
      } else {
        return callback()
      }
    }
  }

  setHeight = function () {
    let $iframes, minHeight
    $iframes = window.jQuery('.f-c-simple-form-with-atoms__iframe, .f-c-merges-form-row__atoms-iframe')
    minHeight = 0
    $iframes.each(function () {
      let height
      if (!this.contentWindow.jQuery) {
        return
      }
      height = this.contentWindow.jQuery('.f-c-atoms-previews').outerHeight(true)
      if (typeof height === 'number') {
        return minHeight = Math.max(minHeight, height)
      }
    })
    return $iframes.css('min-height', minHeight)
  }

  receiveMessage = function (e) {
    if (e.origin !== window.origin) {
      return
    }
    switch (e.data.type) {
      case 'setHeight':
        return setHeight()
      case 'editSetting':
        return editSetting(e.data.locale, e.data.setting)
    }
  }

  window.addEventListener('message', receiveMessage, false)
})()
