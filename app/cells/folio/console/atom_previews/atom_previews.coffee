#= require jquery
#= require folio/lazyload

lazyloadAll = ->
  window.folioLazyloadInstances.forEach (instance) -> instance.update()

$(document)
  .on 'click', 'a, button', (e) -> e.preventDefault()
  .on 'form', 'submit', (e) -> e.preventDefault()

receiveMessage = (e) ->
  return if e.origin isnt window.origin
  switch e.data.type
    when 'replacedHtml' then lazyloadAll()

window.addEventListener('message', receiveMessage, false)
