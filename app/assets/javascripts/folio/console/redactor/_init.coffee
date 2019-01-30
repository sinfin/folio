ADVANCED_OPTIONS =
  plugins: ['imagemanager', 'video', 'table', 'button', 'definedlinks']
  imageUploadParam: 'file[file]'
  imageData:
    elements: 'input[name="authenticity_token"]'
    'file[type]': 'Folio::Image'
  imageUpload: '/console/images.json'
  imageManagerJson: '/console/images.json'
  definedlinks: '/console/links.json'
  toolbarFixed: false
  lang: document.documentElement.lang
  formatting: ['p', 'h2', 'h3', 'h4']

OPTIONS =
  plugins: ['table', 'button', 'definedlinks']
  buttonsHide: ['file', 'image']
  toolbarFixed: false
  definedlinks: '/console/links.json'
  lang: document.documentElement.lang
  formatting: ['p', 'h2', 'h3', 'h4']

window.folioConsoleInitRedactor = (node, options = {}) ->
  return if node.classList.contains('redactor-source')
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
