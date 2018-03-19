FolioCable.folio_thumbnails = FolioCable.cable.subscriptions.create 'FolioThumbnailsChannel',
  received: (data) ->
    return unless data
    { temporary_url, temporary_s3_url, url } = data
    return unless temporary_url and temporary_s3_url and url

    for temp_url in [temporary_url, temporary_s3_url]
      $("img[src='#{temp_url}']").attr('src', url)
      $("img[srcset*='#{temp_url}']").each ->
        $img = $(this)
        $img.attr('srcset', $img.attr('srcset').replace(temp_url, url))

      $('.folio-thumbnail-background').each ->
        $this = $(this)
        bg = $this.css('background-image')
        if bg.indexOf(temp_url) isnt -1
          $this.css('background-image', "url('#{url}')")
          $this.removeClass('folio-thumbnail-background')

      $("[data-lightbox-src='#{temp_url}']").attr('data-lightbox-src', url)
