$(document).on 'click', '.folio-console-single-image-select .folio-console-hover-destroy', ->
  $this = $(this)
  $wrap = $this.closest('.folio-console-single-image-select')
  $wrap.find('.folio-console-single-image-select-destroy').val(1)
  $wrap.find('img').remove()
  $wrap.removeClass('folio-console-has-image')

$(document).on 'click', '.folio-console-single-image-select-button', ->
  $this = $(this)
  $wrap = $this.closest('.folio-console-single-image-select')
  $wrap.find('input[type="file"]').click()

$(document).on 'change', '.folio-console-single-image-select-file', ->
  $this = $(this)
  $wrap = $this.closest('.folio-console-single-image-select')
  $wrap.find('.folio-console-single-image-select-destroy').val(null)
  $wrap.find('.folio-console-single-image-select-image').prepend('<img src="https://doader.s3.amazonaws.com/250x250.gif?" alt="" />')
  $wrap.addClass('folio-console-has-image')

  if @files && @files[0]
    reader = new FileReader()

    reader.onload = (e) ->
      $image = $wrap.find('.folio-console-single-image-select-image')
      $image.find('img').remove()
      $image.prepend("<img src=\"#{e.target.result}\" alt=\"\" />")

    reader.readAsDataURL(@files[0])
