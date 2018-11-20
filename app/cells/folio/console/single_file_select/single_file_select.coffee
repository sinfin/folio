$(document).on 'click', '.folio-console-single-file-select .folio-console-hover-destroy, .folio-console-single-file-select .btn-danger', ->
  $this = $(this)
  unless window.confirm(window.FolioConsole.translations.removePrompt)
    return $this.blur()
  $wrap = $this.closest('.folio-console-single-file-select')
  $wrap.find('.folio-console-single-file-select-destroy').val(1)
  $wrap.find('img, video').remove()
  $wrap.removeClass('folio-console-has-file')

$(document).on 'click', '.folio-console-single-file-select-button', ->
  $this = $(this)
  $wrap = $this.closest('.folio-console-single-file-select')
  $wrap.find('input[type="file"]').click()

$(document).on 'change', '.folio-console-single-file-select-file', ->
  $this = $(this)
  $wrap = $this.closest('.folio-console-single-file-select')
  $wrap.find('.folio-console-single-file-select-destroy').val(null)
  $wrap.find('.folio-console-single-file-select-image').prepend('<img src="https://doader.s3.amazonaws.com/250x250.gif?" alt="" />')
  $wrap.addClass('folio-console-has-file')

  isImage = $wrap.hasClass('folio-console-single-file-select-as-image')
  isVideo = $wrap.hasClass('folio-console-single-file-select-as-video')

  if @files and @files[0] and (isImage or isVideo)
    reader = new FileReader()

    reader.onload = (e) ->
      if isVideo
        $video = $wrap.find('.folio-console-single-file-select-video')
        $video.find('video').remove()
        $video.prepend("""
          <video width="auto" height="auto" controls>
            <source src=#{e.target.result} type="video/mp4">
          </video>
        """)
      else if isImage
        $image = $wrap.find('.folio-console-single-file-select-image')
        $image.find('img').remove()
        $image.prepend("<img src=\"#{e.target.result}\" alt=\"\" />")

    reader.readAsDataURL(@files[0])
