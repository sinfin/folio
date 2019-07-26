#= require jquery
#= require folio/lazyload

lazyloadAll = ->
  window.folioLazyloadInstances.forEach (instance) -> instance.update()

selectLocale = (locale) ->
  $('.f-c-atom-previews__locale').each ->
    $this = $(this)
    $this.prop('hidden', $this.data('locale') isnt locale)

$(document)
  .on 'click', 'a, button', (e) -> e.preventDefault()
  .on 'form', 'submit', (e) -> e.preventDefault()

receiveMessage = (e) ->
  return if e.origin isnt window.origin
  switch e.data.type
    when 'replacedHtml' then lazyloadAll()
    when 'selectLocale' then selectLocale(e.data.locale)

window.addEventListener('message', receiveMessage, false)
