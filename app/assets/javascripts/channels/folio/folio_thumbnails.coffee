FolioCable.folio_thumbnails = FolioCable.cable.subscriptions.create 'FolioThumbnailsChannel',
  received: (data) ->
    return unless data
    { temporary_url, url } = data
    return unless temporary_url and url

    $("img[src='#{temporary_url}']").attr('src', url)
    $("img[srcset*='#{temporary_url}']").each ->
      $img = $(this)
      $img.attr('srcset', $img.attr('srcset').replace(temporary_url, url))

    $('.folio-thumbnail-background').each ->
      $this = $(this)
      bg = $this.css('background-image')
      if bg.indexOf(temporary_url) isnt -1
        $this.css('background-image', "url('#{url}')")
        $this.removeClass('folio-thumbnail-background')
