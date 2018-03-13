#= require jquery3

MAX_TIMES = 3
INTERVAL = 5000

performCheck = ($el, src, handler) ->
  return if $el.data('folio-working')

  timesChecked = $el.data('folio-times-checked') or 0

  if timesChecked < MAX_TIMES
    $el.data('folio-times-checked', timesChecked + 1)
    $el.data('folio-working', true)

    $.get src
      .then (res) ->
        handler(res) if res
      .always -> $el.data('folio-working', false)

  else
    handler(undefined)

check = ->
  $('img[src*="/thumbnail/"]').each ->
    $this = $(this)
    performCheck $this, $this.prop('src'), (res) ->
      if res && res.match('dummyimage.com')
        $this.attr('data-orig-src', $this.prop('src'))
      $this.prop('src', res)

  $('img[data-orig-src*="/thumbnail/"]').each ->
    $this = $(this)
    performCheck $this, $this.prop('data-orig-src'), (res) ->
      if res && !res.match('dummyimage.com')
        $this.prop('src', res).removeAttr('data-orig-src')

  $('[data-lightbox-src*="/thumbnail/"]').each ->
    $this = $(this)
    performCheck $this, $this.data('lightbox-src'), (res) ->
      if res && res.match('dummyimage.com')
        $this.attr('data-orig-lightbox-src', $this.data('lightbox-src'))
      $this.prop('data-lightbox-src', res)

  $('[data-orig-lightbox-src*="/thumbnail/"]').each ->
    $this = $(this)
    performCheck $this, $this.data('lightbox-src'), (res) ->
      if res && !res.match('dummyimage.com')
        $this.prop('data-lightbox-src', res)
        $this.removeAttr('data-orig-lightbox-src')

  $('.folio-thumbnail-background').each ->
    $this = $(this)
    url = $this.css('backgroundImage').match(/url\(["'](.+)["']\)/)[1]

    unless url.match('/thumbnail/')
      return $this.removeClass('folio-thumbnail-background')

    performCheck $this, url, (res) ->
      if res && res.match('dummyimage.com')
        $this.attr('data-folio-thumbnail-background', url)
      $this.removeClass('folio-thumbnail-background')
      $this.css('backgroundImage', "url('#{res}')")

  $('[data-folio-thumbnail-background').each ->
    $this = $(this)
    performCheck $this, $this.data('folio-thumbnail-background'), (res) ->
      if res && !res.match('dummyimage.com')
        $this.removeAttr('data-folio-thumbnail-background')
        $this.css('backgroundImage', "url('#{res}')")

window.folioThumbnailsLoader ?= setInterval(check, INTERVAL)
