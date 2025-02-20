// converted via https://coffeescript.org/#try
// once you update it, remove it from package.json standard js ignored files

(function () {
  window.jQuery(function () {
    return window.jQuery('.f-c-lazy-dom').each(function () {
      let $this
      $this = window.jQuery(this)
      $this.addClass('f-c-lazy-dom--loading')
      return window.jQuery.ajax({
        method: 'GET',
        url: $this.data('lazy-dom-url'),
        success: function (data) {
          $this.html(data)
          $this.trigger('folio:lazy-dom-loaded')
          return window.updateAllFolioLazyLoadInstances()
        },
        error: function (jxHr) {
          $this.html(`<p class=\"f-c-lazy-dom__title\">${$this.data('error')}</p>${jxHr.status}: ${jxHr.statusText}`)
          return $this.addClass('f-c-lazy-dom--error')
        },
        complete: function () {
          return $this.removeClass('f-c-lazy-dom--loading')
        }
      })
    })
  })
})()
