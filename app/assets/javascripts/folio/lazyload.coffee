#= require vanilla-lazyload/dist/lazyload

window.makeFolioLazyLoad = (selector, containerSelector = null, options = {}) ->
  window.folioLazyloadInstances ?= []

  init = ->
    if containerSelector
      container = document.querySelector(containerSelector)
      return unless container
    else
      container = undefined

    defaults =
      elements_selector: selector
      container: container
      callback_reveal: (el) ->
        el.style.visibility = ''
        el.alt = el.dataset.alt if el.dataset.alt
        el.classList.remove(selector.replace('.', ''))
        $(el)
          .trigger('folioLazyLoadLoaded')
          .closest('.f-image')
          .addClass('f-image--loaded')

    window.folioLazyloadInstances.push(
      new LazyLoad $.extend({}, defaults, options)
    )

  if Turbolinks?
    $(document)
      .on 'turbolinks:load', init
      .on 'turbolinks:before-cache', ->
        return unless window.folioLazyloadInstances.length > 0
        instance.destroy() for instance in window.folioLazyloadInstances
        window.folioLazyloadInstances = []
  else
    $ -> setTimeout(init, 0)

window.makeFolioLazyLoad '.f-lazyload'

window.updateAllFolioLazyLoadInstances = ->
  return unless window.folioLazyloadInstances
  window.folioLazyloadInstances.forEach (instance) -> instance.update()
