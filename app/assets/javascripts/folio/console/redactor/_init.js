//= require folio/i18n

// converted via https://coffeescript.org/#try
// once you update it, remove it from package.json standard js ignored files

(function () {
  var ADVANCED_OPTIONS, EMAIL_OPTIONS, FOLIO_REDACTOR_I18N, OPTIONS, PEREX_OPTIONS, blurCallback, changedCallback, focusCallback;

  blurCallback = function(e) {
    if (window.FolioConsole && window.FolioConsole.HtmlAutoFormat && window.FolioConsole.HtmlAutoFormat.redactorBlurCallback) {
      window.FolioConsole.HtmlAutoFormat.redactorBlurCallback({
        redactor: this
      });
    }
    return e.target.dispatchEvent(new CustomEvent('focusout', {
      bubbles: true,
      detail: {
        redactor: true
      }
    }));
  };

  focusCallback = function(e) {
    return e.target.dispatchEvent(new CustomEvent('focusin', {
      bubbles: true,
      detail: {
        redactor: true
      }
    }));
  };

  changedCallback = function(html) {
    return this.rootElement.dispatchEvent(new CustomEvent('change', {
      bubbles: true,
      detail: {
        redactor: true
      }
    }));
  };

  FOLIO_REDACTOR_I18N = {
    cs: {
      large: "Velký",
      small: "Malý"
    },
    en: {
      large: "Large",
      small: "Small"
    }
  };

  ADVANCED_OPTIONS = {
    plugins: ['video', 'table', 'button', 'character_counter'],
    toolbarFixed: false,
    lang: document.documentElement.lang,
    formatting: ['p', 'h2', 'h3', 'h4'],
    linkNewTab: true,
    callbacks: {
      changed: changedCallback,
      focus: focusCallback,
      blur: blurCallback
    }
  };

  OPTIONS = {
    plugins: ['table', 'button', 'character_counter'],
    buttonsHide: ['file', 'image'],
    toolbarFixed: false,
    lang: document.documentElement.lang,
    formatting: ['p', 'h2', 'h3', 'h4'],
    formattingAdd: {
      "large-p": {
        title: window.Folio.i18n(FOLIO_REDACTOR_I18N, "large"),
        api: 'module.block.format',
        args: {
          'tag': 'p',
          'class': 'font-size-lg',
          'type': 'toggle'
        }
      },
      "small-p": {
        title: window.Folio.i18n(FOLIO_REDACTOR_I18N, "small"),
        api: 'module.block.format',
        args: {
          'tag': 'p',
          'class': 'font-size-sm',
          'type': 'toggle'
        }
      }
    },
    linkNewTab: true,
    callbacks: {
      changed: changedCallback,
      focus: focusCallback,
      blur: blurCallback
    }
  };

  EMAIL_OPTIONS = {
    plugins: ['button', 'character_counter'],
    buttonsHide: ['file', 'image', 'format', 'deleted', 'lists'],
    toolbarFixed: false,
    lang: document.documentElement.lang,
    formatting: [],
    callbacks: {
      changed: changedCallback,
      focus: focusCallback,
      blur: blurCallback
    }
  };

  PEREX_OPTIONS = {
    plugins: ['character_counter'],
    buttonsHide: ['file', 'image', 'html', 'format', 'bold', 'italic', 'deleted', 'lists'],
    breakline: true,
    toolbarFixed: false,
    lang: document.documentElement.lang,
    linkNewTab: true,
    callbacks: {
      changed: changedCallback,
      focus: focusCallback,
      blur: blurCallback
    }
  };

  window.folioConsoleInitRedactor = function(node, options = {}, additional = {}) {
    var callbacksHash, opts;
    if (node.classList.contains('redactor-source')) {
      return;
    }
    if (options.advanced) {
      opts = ADVANCED_OPTIONS;
    } else if (options.email) {
      opts = EMAIL_OPTIONS;
    } else if (options.perex) {
      opts = PEREX_OPTIONS;
    } else {
      opts = OPTIONS;
    }
    window.folioConsoleRedactorOptionsOverride || (window.folioConsoleRedactorOptionsOverride = {});
    callbacksHash = {
      callbacks: $.extend({}, opts.callbacks || {}, additional.callbacks || {}, window.folioConsoleRedactorOptionsOverride.callbacks || {})
    };
    return $R(node, $.extend({}, opts, additional, window.folioConsoleRedactorOptionsOverride, callbacksHash));
  };

  window.folioConsoleDestroyRedactor = function(node) {
    return $R(node, 'destroy');
  };

  window.folioConsoleRedactorSetContent = function(node, content) {
    var R;
    R = $R(node);
    return R.source.setCode(content);
  };

  window.folioConsoleRedactorGetContent = function(node) {
    var R;
    R = $R(node);
    return R.source.getCode();
  };

  window.folioConsoleRedactorHardsyncAll = function() {
    return $('.redactor-source').each(function() {
      var R;
      R = $R(this);
      return R.broadcast('hardsync');
    });
  };

  $(document).on('submit', 'form', window.folioConsoleRedactorHardsyncAll);
})()
