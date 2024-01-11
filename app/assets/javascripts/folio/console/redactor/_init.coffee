#= require folio/i18n

changedCallback = ->
  @rootElement.dispatchEvent(new window.Event('change', bubbles: true))

FOLIO_REDACTOR_I18N =
  cs:
    large: "Velký"
    small: "Malý"
  en:
    large: "Large"
    small: "Small"

ADVANCED_OPTIONS =
  plugins: ['video', 'table', 'button', 'character_counter', 'definedlinks', 'linksrel']
  toolbarFixed: true
  lang: document.documentElement.lang
  formatting: ['p', 'h2', 'h3', 'h4']
  linkNewTab: true
  callbacks:
    changed: changedCallback

OPTIONS =
  plugins: ['table', 'button', 'character_counter', 'definedlinks', 'linksrel']
  buttonsHide: ['file', 'image']
  toolbarFixed: true
  definedlinks: '/console/api/links.json'
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

EMAIL_OPTIONS =
  plugins: ['button', 'character_counter']
  buttonsHide: ['file', 'image', 'format', 'deleted', 'lists']
  toolbarFixed: true
  lang: document.documentElement.lang
  formatting: []
  callbacks:
    changed: changedCallback

PEREX_OPTIONS =
  plugins: ['character_counter', 'definedlinks', 'linksrel']
  buttonsHide: ['file', 'image', 'html', 'format', 'bold', 'italic', 'deleted', 'lists']
  breakline: true
  toolbarFixed: true
  lang: document.documentElement.lang
  linkNewTab: true
  callbacks:
    changed: changedCallback

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

window.folioConsoleRedactorHardsyncAll = ->
  $('.redactor-source').each ->
    R = $R(this)
    R.broadcast('hardsync')

$(document).on 'submit', 'form', window.folioConsoleRedactorHardsyncAll
