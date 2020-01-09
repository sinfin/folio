$(document).on 'click', '.folio-console-single-file-select__button--add, .folio-console-single-file-select__button--change', ->
  $this = $(this)
  $wrap = $this.closest('.folio-console-single-file-select')
  $wrap.find('input[type="file"]').click()

$(document).on 'click', '.folio-console-single-file-select__button--remove', ->
  $this = $(this)
  unless window.confirm(window.FolioConsole.translations.removePrompt)
    return $this.blur()
  $wrap = $this.closest('.folio-console-single-file-select')
  $wrap.find('.folio-console-single-file-select__destroy').val(1)
  $wrap.find('.folio-console-single-file-select__clearable').html('')
  $wrap.removeClass('folio-console-single-file-select--has-file')

$(document).on 'change', '.folio-console-single-file-select-file', ->
  return unless @files and @files[0]

  $this = $(this)
  $wrap = $this.closest('.folio-console-single-file-select')
  $wrap.find('.folio-console-single-file-select__destroy').val(null)
  $wrap.addClass('folio-console-single-file-select--has-file')
  $wrap.find('.folio-console-single-file-select__clearable').html('')

  isImage = $wrap.find('.f-c-file-list__img-wrap').length
  isVideo = $wrap.find('.folio-console-single-file-select__video').length

  if isImage or isVideo
    if isImage
      $wrap.find('.f-c-file-list__img-wrap').html('<img src="https://doader.s3.amazonaws.com/250x250.gif?" alt="" />')

    reader = new FileReader()

    reader.onload = (e) ->
      if isVideo
        $video = $wrap.find('.folio-console-single-file-select__video')
        $video.html("""
          <video width="auto" height="auto" controls>
            <source src=#{e.target.result} type="video/mp4">
          </video>
        """)
      else if isImage
        $imageWrap = $wrap.find('.f-c-file-list__img-wrap')
        $imageWrap.html("<img src=\"#{e.target.result}\" alt=\"\" class=\"f-c-file-list__img\" />")

    reader.readAsDataURL(@files[0])
  else
    $wrap.find('.f-c-file-table__td--main').text(@files[0].name)
