// converted via https://coffeescript.org/#try
// once you update it, remove it from package.json standard js ignored files
(function ($R) {
  return $R.add('plugin', 'definedlinks', {
    init: function (app) {
      this.app = app
      this.opts = app.opts
      this.component = app.component
      // local
      this.$select = null
      return this.$urlInput = null
    },
    onmodal: {
      link: {
        open: function ($modal, $form) {
          if (!this.opts.definedlinks) {
            return
          }
          this.$modal = $modal
          this.$form = $form
          return this._load()
        },
        close: function () {
          if (this.$select && this.$select.select2) {
            this.$select.off('select2:select')
            this.$select.select2('destroy')
            this.$select = null
            return this.$urlInput = null
          }
        }
      }
    },
    _load: function () {
      if (this.opts.definedlinks) {
        return this._build(this.opts.definedlinks)
      }
    },
    _build: function (url) {
      let $modal, $row, modal
      modal = this.$modal.nodes[0]
      $modal = window.jQuery(modal)
      this.$urlInput = $modal.find('#modal-link-url')
      if ($modal.find('.redactor-defined-links').length === 0) {
        this.$urlInput.wrap('<div class=\'row\'></div>')
        this.$urlInput.wrap('<div class=\'col-md-8\'></div>')
        $row = this.$urlInput.closest('.row')
        $row.prepend('<div class="col-md-4"><select class="form-control redactor-defined-links" /></div>')
      }
      this.links = []
      this.$select = $modal.find('.redactor-defined-links')
      this.$select.select2({
        width: '100%',
        language: document.documentElement.lang,
        ajax: {
          url,
          dataType: 'JSON',
          minimumInputLength: 0,
          cache: false,
          data: function (params) {
            return {
              q: params.term
            }
          },
          processResults: function (data, params) {
            return {
              results: data.data.map(function (h) {
                h.id = h.url
                h.text = h.label
                return h
              })
            }
          }
        }
      })
      return this.$select.on('select2:select', (e) => {
        let $linkText
        this.$urlInput.val(e.params.data.url).addClass('form-control--hinted')
        $linkText = $modal.find('#modal-link-text')
        if ($linkText.length && !$linkText.val()) {
          $linkText.val(e.params.data.title).addClass('form-control--hinted')
        }
        return setTimeout(() => {
          $linkText.removeClass('form-control--hinted')
          if (this.$urlInput) {
            return this.$urlInput.removeClass('form-control--hinted')
          }
        }, 1000)
      })
    }
  })
})(window.Redactor)
