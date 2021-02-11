ADVANCED_OPTIONS =
  plugins: ['video', 'table', 'button', 'character_counter']
  toolbarFixed: true
  lang: document.documentElement.lang
  formatting: ['p', 'h2', 'h3', 'h4']
  linkNewTab: true

OPTIONS =
  plugins: ['table', 'button', 'character_counter']
  buttonsHide: ['file', 'image']
  toolbarFixed: true
  lang: document.documentElement.lang
  formatting: ['p', 'h2', 'h3', 'h4']
  linkNewTab: true

EMAIL_OPTIONS =
  plugins: ['button', 'character_counter']
  buttonsHide: ['file', 'image', 'format', 'deleted', 'lists']
  toolbarFixed: true
  lang: document.documentElement.lang
  formatting: []

PEREX_OPTIONS =
  plugins: ['character_counter']
  buttonsHide: ['file', 'image', 'html', 'format', 'bold', 'italic', 'deleted', 'lists']
  breakline: true
  toolbarFixed: true
  lang: document.documentElement.lang
  linkNewTab: true

window.folioConsoleInitRedactor = (node, options = {}, additional = {}) ->
  return if node.classList.contains('redactor-source')

  if options.advanced
    opts = ADVANCED_OPTIONS
  else if options.email
    opts = EMAIL_OPTIONS
  else if options.perex
    opts = PEREX_OPTIONS
  else
    opts = OPTIONS

  window.folioConsoleRedactorOptionsOverride ||= {}

  $R(node, $.extend({}, opts, additional, window.folioConsoleRedactorOptionsOverride))

window.folioConsoleDestroyRedactor = (node) ->
  $R(node, 'destroy')

window.folioConsoleRedactorSetContent = (node, content) ->
  R = $R(node)
  R.source.setCode content

window.folioConsoleRedactorGetContent = (node) ->
  R = $R(node)
  R.source.getCode()
