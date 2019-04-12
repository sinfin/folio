#= require vanilla-lazyload/dist/lazyload

window.makeFolioLazyLoad = (selector, containerSelector = null, options = {}) ->
  window.folioLazyloadInstances ?= []

  $(document)
    .on 'turbolinks:load', ->
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
          el.alt = el.dataset.alt
          el.classList.remove(selector.replace('.', ''))

      window.folioLazyloadInstances.push(
        new LazyLoad $.extend({}, defaults, options)
      )

    .on 'turbolinks:before-cache', ->
      return unless window.folioLazyloadInstances.length > 0
      instance.destroy() for instance in window.folioLazyloadInstances
      window.folioLazyloadInstances = []

window.makeFolioLazyLoad '.folio-lazyload'
