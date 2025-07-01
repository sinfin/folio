#= require folio/i18n

blurCallback = (e) ->
  if window.FolioConsole and window.FolioConsole.HtmlAutoFormat and window.FolioConsole.HtmlAutoFormat.redactorBlurCallback
    window.FolioConsole.HtmlAutoFormat.redactorBlurCallback
      redactor: this

  e.target.dispatchEvent(new CustomEvent('focusout', { bubbles: true, detail: { redactor: true } }))


focusCallback = (e) ->
  e.target.dispatchEvent(new CustomEvent('focusin', { bubbles: true, detail: { redactor: true } }))

changedCallback = (html) ->
  @rootElement.dispatchEvent(new CustomEvent('change', { bubbles: true, detail: { redactor: true } }))

FOLIO_REDACTOR_I18N =
  cs:
    large: "Velký"
    small: "Malý"
  en:
    large: "Large"
    small: "Small"

ADVANCED_OPTIONS =
  plugins: ['video', 'table', 'button', 'character_counter']
  toolbarFixed: false
  lang: document.documentElement.lang
  formatting: ['p', 'h2', 'h3', 'h4']
  linkNewTab: true
  callbacks:
    changed: changedCallback
    focus: focusCallback
    blur: blurCallback

OPTIONS =
  plugins: ['table', 'button', 'character_counter']
  buttonsHide: ['file', 'image']
  toolbarFixed: false
  lang: document.documentElement.lang
  formatting: ['p', 'h2', 'h3', 'h4']
  formattingAdd:
    "large-p":
      title: window.Folio.i18n(FOLIO_REDACTOR_I18N, "large")
      api: 'module.block.format'
      args:
        'tag': 'p',
        'class': 'font-size-lg'
        'type': 'toggle'
    "small-p":
      title: window.Folio.i18n(FOLIO_REDACTOR_I18N, "small")
      api: 'module.block.format'
      args:
        'tag': 'p',
        'class': 'font-size-sm'
        'type': 'toggle'

  linkNewTab: true
  callbacks:
    changed: changedCallback
    focus: focusCallback
    blur: blurCallback

EMAIL_OPTIONS =
  plugins: ['button', 'character_counter']
  buttonsHide: ['file', 'image', 'format', 'deleted', 'lists']
  toolbarFixed: false
  lang: document.documentElement.lang
  formatting: []
  callbacks:
    changed: changedCallback
    focus: focusCallback
    blur: blurCallback

PEREX_OPTIONS =
  plugins: ['character_counter']
  buttonsHide: ['file', 'image', 'html', 'format', 'bold', 'italic', 'deleted', 'lists']
  breakline: true
  toolbarFixed: false
  lang: document.documentElement.lang
  linkNewTab: true
  callbacks:
    changed: changedCallback
    focus: focusCallback
    blur: blurCallback

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

  callbacksHash =
    callbacks: $.extend({}, opts.callbacks or {}, additional.callbacks or {}, window.folioConsoleRedactorOptionsOverride.callbacks or {})

  $R(node, $.extend({}, opts, additional, window.folioConsoleRedactorOptionsOverride, callbacksHash))

  if window.FolioConsole and window.FolioConsole.HtmlAutoFormat and window.FolioConsole.HtmlAutoFormat.addMissingAttributes
    parent = node.closest('.redactor')
    if parent
      box = parent.querySelector('.redactor-in')
      if box
        window.FolioConsole.HtmlAutoFormat.addMissingAttributes(box)

window.folioConsoleDestroyRedactor = (node) ->
  $R(node, 'destroy')

window.folioConsoleRedactorSetContent = (node, content) ->
  R = $R(node)
  R.source.setCode content

window.folioConsoleRedactorGetContent = (node) ->
  R = $R(node)
  R.source.getCode()

window.folioConsoleRedactorHardsyncAll = ->
  $('.redactor-source').each ->
    R = $R(this)
    R.broadcast('hardsync')

$(document).on 'submit', 'form', window.folioConsoleRedactorHardsyncAll
