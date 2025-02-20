//= require vanilla-lazyload/dist/lazyload

// converted via https://coffeescript.org/#try
// once you update it, remove it from package.json standard js ignored files
// TODO jQuery -> stimulus

window.makeFolioLazyLoad = function (selector, containerSelector = null, options = {}) {
  let init
  if (window.folioLazyloadInstances === null) {
    window.folioLazyloadInstances = []
  }
  init = function () {
    let container, defaults
    if (containerSelector) {
      container = document.querySelector(containerSelector)
      if (!container) {
        return
      }
    } else {
      container = void 0
    }
    defaults = {
      elements_selector: selector,
      container,
      callback_reveal: function (el) {
        el.style.visibility = ''
        if (el.dataset.alt) {
          el.alt = el.dataset.alt
        }
        el.classList.remove(selector.replace('.', ''))
        return window.jQuery(el).trigger('folioLazyLoadLoaded').closest('.f-image').addClass('f-image--loaded')
      }
    }
    return window.folioLazyloadInstances.push(new LazyLoad($.extend({}, defaults, options)))
  }
  if (typeof Turbolinks !== 'undefined' && Turbolinks !== null) {
    return window.jQuery(document).on('turbolinks:load', init).on('turbolinks:before-cache', function () {
      let i, instance, len, ref
      if (!(window.folioLazyloadInstances.length > 0)) {
        return
      }
      ref = window.folioLazyloadInstances
      for (i = 0, len = ref.length; i < len; i++) {
        instance = ref[i]
        instance.destroy()
      }
      return window.folioLazyloadInstances = []
    })
  } else {
    return window.jQuery(function () {
      return setTimeout(init, 0)
    })
  }
}

window.makeFolioLazyLoad('.f-lazyload')

window.updateAllFolioLazyLoadInstances = function () {
  if (!window.folioLazyloadInstances) {
    return
  }
  return window.folioLazyloadInstances.forEach(function (instance) {
    return instance.update()
  })
}
