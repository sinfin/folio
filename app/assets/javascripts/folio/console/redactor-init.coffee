OPTIONS =
  plugins: ['imagemanager']
  imageUploadParam: 'file[file]'
  imageData:
    elements: 'input[name="authenticity_token"]'
    'file[type]': 'Folio::Image'
  imageUpload: '/console/files.json'
  imageManagerJson: '/console/files.json?type=image'

window.folioConsoleInitRedactor = (node) -> $R(node, OPTIONS)
window.folioConsoleDestroyRedactor = (node) -> $R(node, 'destroy')
window.folioConsoleRedactorSetContent = (node, content) ->
  $R(node, 'source.setCode', content)
window.folioConsoleRedactor = (node, args...) -> $R(node, args...)

$ ->
  $wrap = $('.redactor')
  return if $wrap.length is 0
  $wrap.each ->
    window.folioConsoleInitRedactor(this)
