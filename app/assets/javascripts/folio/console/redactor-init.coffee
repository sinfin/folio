$ ->
  $wrap = $('.redactor')
  return if $wrap.length is 0
  $wrap.each ->
    $(this).redactor
      plugins: ['imagemanager']
      imageUploadParam: 'file[file]'
      imageUploadForms: "input[name='authenticity_token']"
      imageUploadFields:
            'file[type]': 'Folio::Image'
      imageUpload: '/console/files.json'
      imageManagerJson: '/console/files.json?type=image'
