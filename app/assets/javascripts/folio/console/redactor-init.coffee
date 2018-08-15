OPTIONS =
  plugins: ['imagemanager', 'video']
  imageUploadParam: 'file[file]'
  imageData:
    elements: 'input[name="authenticity_token"]'
    'file[type]': 'Folio::Image'
  imageUpload: '/console/images.json'
  imageManagerJson: '/console/images.json'

NO_IMAGES_OPTIONS =
  plugins: []
  buttonsHide: ['file', 'image']

window.folioConsoleInitRedactor = (node, options = {}) ->
  opts = if options.noImages then NO_IMAGES_OPTIONS else OPTIONS
  $R(node, opts)

window.folioConsoleDestroyRedactor = (node) ->
  $R(node, 'destroy')

window.folioConsoleRedactorSetContent = (node, content) ->
  R = $R(node)
  R.source.setCode content

window.folioConsoleRedactorGetContent = (node) ->
  R = $R(node)
  R.source.getCode()

$ ->
  $wrap = $('.redactor')
  return if $wrap.length is 0
  $wrap.each ->
    window.folioConsoleInitRedactor(this)
