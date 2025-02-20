//= require folio/i18n

// converted via https://coffeescript.org/#try
// once you update it, remove it from package.json standard js ignored files

(function () {
  let ADVANCED_OPTIONS, EMAIL_OPTIONS, FOLIO_REDACTOR_I18N, OPTIONS, PEREX_OPTIONS, changedCallback

  changedCallback = function () {
    return this.rootElement.dispatchEvent(new window.Event('change', {
      bubbles: true
    }))
  }

  FOLIO_REDACTOR_I18N = {
    cs: {
      large: 'Velký',
      small: 'Malý'
    },
    en: {
      large: 'Large',
      small: 'Small'
    }
  }

  ADVANCED_OPTIONS = {
    plugins: ['video', 'table', 'button', 'character_counter', 'definedlinks', 'linksrel'],
    toolbarFixed: false,
    lang: document.documentElement.lang,
    formatting: ['p', 'h2', 'h3', 'h4'],
    linkNewTab: true,
    callbacks: {
      changed: changedCallback
    }
  }

  OPTIONS = {
    plugins: ['table', 'button', 'character_counter', 'definedlinks', 'linksrel'],
    buttonsHide: ['file', 'image'],
    toolbarFixed: false,
    definedlinks: '/console/api/links.json',
    lang: document.documentElement.lang,
    formatting: ['p', 'h2', 'h3', 'h4'],
    formattingAdd: {
      'large-p': {
        title: window.Folio.i18n(FOLIO_REDACTOR_I18N, 'large'),
        api: 'module.block.format',
        args: {
          tag: 'p',
          class: 'font-size-lg',
          type: 'toggle'
        }
      },
      'small-p': {
        title: window.Folio.i18n(FOLIO_REDACTOR_I18N, 'small'),
        api: 'module.block.format',
        args: {
          tag: 'p',
          class: 'font-size-sm',
          type: 'toggle'
        }
      }
    },
    linkNewTab: true,
    callbacks: {
      changed: changedCallback
    }
  }

  EMAIL_OPTIONS = {
    plugins: ['button', 'character_counter'],
    buttonsHide: ['file', 'image', 'format', 'deleted', 'lists'],
    toolbarFixed: false,
    lang: document.documentElement.lang,
    formatting: [],
    callbacks: {
      changed: changedCallback
    }
  }

  PEREX_OPTIONS = {
    plugins: ['character_counter', 'definedlinks', 'linksrel'],
    buttonsHide: ['file', 'image', 'html', 'format', 'bold', 'italic', 'deleted', 'lists'],
    breakline: true,
    toolbarFixed: false,
    lang: document.documentElement.lang,
    linkNewTab: true,
    callbacks: {
      changed: changedCallback
    }
  }

  window.folioConsoleInitRedactor = function (node, options = {}, additional = {}) {
    let opts
    if (node.classList.contains('redactor-source')) {
      return
    }
    if (options.advanced) {
      opts = ADVANCED_OPTIONS
    } else if (options.email) {
      opts = EMAIL_OPTIONS
    } else if (options.perex) {
      opts = PEREX_OPTIONS
    } else {
      opts = OPTIONS
    }
    window.folioConsoleRedactorOptionsOverride || (window.folioConsoleRedactorOptionsOverride = {})
    return $R(node, $.extend({}, opts, additional, window.folioConsoleRedactorOptionsOverride))
  }

  window.folioConsoleDestroyRedactor = function (node) {
    return $R(node, 'destroy')
  }

  window.folioConsoleRedactorSetContent = function (node, content) {
    let R
    R = $R(node)
    return R.source.setCode(content)
  }

  window.folioConsoleRedactorGetContent = function (node) {
    let R
    R = $R(node)
    return R.source.getCode()
  }

  window.folioConsoleRedactorHardsyncAll = function () {
    return window.jQuery('.redactor-source').each(function () {
      let R
      R = $R(this)
      return R.broadcast('hardsync')
    })
  }

  window.jQuery(document).on('submit', 'form', window.folioConsoleRedactorHardsyncAll)
})()
