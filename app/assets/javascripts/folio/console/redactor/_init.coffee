ADVANCED_OPTIONS =
  plugins: ['imagemanager', 'video', 'table']
  imageUploadParam: 'file[file]'
  imageData:
    elements: 'input[name="authenticity_token"]'
    'file[type]': 'Folio::Image'
  imageUpload: '/console/images.json'
  imageManagerJson: '/console/images.json'
  toolbarFixed: false
  lang: document.documentElement.lang

OPTIONS =
  plugins: ['video', 'table']
  buttonsHide: ['file', 'image']
  toolbarFixed: false
  lang: document.documentElement.lang

window.folioConsoleInitRedactor = (node, options = {}) ->
  opts = if options.advanced then ADVANCED_OPTIONS else OPTIONS
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
    window.folioConsoleInitRedactor(this, advanced: @classList.contains('redactor--advanced'))
