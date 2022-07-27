$ ->
  $('.f-c-lazy-dom').each ->
    $this = $(this)
    $this.addClass('f-c-lazy-dom--loading')

    $.ajax
      method: 'GET'
      url: $this.data('lazy-dom-url')
      success: (data) ->
        $this.html(data)
        $this.trigger('folio:lazy-dom-loaded')
        window.updateAllFolioLazyLoadInstances()
        window.Folio.Lightbox.updateAll()
      error: (jxHr) ->
        $this.html("<p class=\"f-c-lazy-dom__title\">#{$this.data('error')}</p>#{jxHr.status}: #{jxHr.statusText}")
        $this.addClass('f-c-lazy-dom--error')
      complete: ->
        $this.removeClass('f-c-lazy-dom--loading')
