//= require folio/webp
//= require photoswipe.esm.folio
//= require photoswipe-dynamic-caption-plugin.esm

window.Folio = window.Folio || {}
window.Folio.Lightbox = {}

window.Folio.Lightbox.calls = []

window.Folio.Lightbox.instances = []

window.Folio.Lightbox.authorLabel = document.lang === 'cs' ? 'Foto' : 'Photo'

window.Folio.Lightbox.bind = (selector, options) => {
  options = options || {}

  window.Folio.Lightbox.calls.push([selector, options])

  const init = () => {
    const $items = $(selector)

    if ($items.length === 0) return

    if (options.individual) {
      $items.each(function () {
        let individualSelector = `.${this.className.replace(/\s+/g, '.')}`

        if (options.itemSelector) {
          individualSelector = `${individualSelector} ${options.itemSelector}`
        }

        window.Folio.Lightbox.instances.push(new window.Folio.Lightbox.Lightbox({ selector: individualSelector, options }))
      })
    } else if (options.fromData) {
      $items.each((i, el) => {
        window.Folio.Lightbox.instances.push(new window.Folio.Lightbox.Lightbox({ selector, options, data: $(el).data('lightbox-image-data') }))
      })
    } else {
      window.Folio.Lightbox.instances.push(new window.Folio.Lightbox.Lightbox({ selector, options }))
    }
  }

  if (typeof Turbolinks !== 'undefined' && Turbolinks !== null) {
    $(document)
      .on('turbolinks:load', init)
      .on('turbolinks:before-render', function () {
        if (window.Folio.Lightbox.instances.length === 0) return

        window.Folio.Lightbox.instances.forEach((instance) => {
          instance.destroy()
        })

        window.Folio.Lightbox.instances = []
      })
  } else {
    $(() => setTimeout(init, 0))
  }
}

window.Folio.Lightbox.updateAll = () => {
  window.Folio.Lightbox.instances.forEach((instance) => instance.destroy())

  window.Folio.Lightbox.instances = []

  window.Folio.Lightbox.calls.forEach((call) => window.Folio.Lightbox.bind(call[0], call[1]))
}

window.Folio.Lightbox.Lightbox = class FolioLightbox {
  constructor (attrs) {
    this.selector = attrs.selector
    this.options = attrs.options

    if (attrs.additionalSelector) {
      this.fullSelector = `${this.selector}, ${attrs.additionalSelector}`
    } else {
      this.fullSelector = this.selector
    }

    this.eventIdentifier = 'folioLightbox'
    this.$html = $(document.documentElement)

    this.bind(attrs.data)
  }

  bind (data) {
    this.unbind()
    const that = this

    $(document).on(`click.${this.eventIdentifier}`, this.fullSelector, function (e) {
      e.preventDefault()

      let items = data || that.items()

      if (that.options.itemsCallback) {
        items = that.options.itemsCallback(items)
      }

      let index = 0

      if (typeof that.options.forceIndex !== 'undefined') {
        index = that.options.forceIndex
      } else {
        items.forEach((item, i) => {
          if (item.el === this) {
            index = i
          }
        })
      }

      that.photoSwipe = new window.Folio.PhotoSwipe({
        dataSource: items,
        index: index
      })

      if (that.options.changeCallback) {
        that.photoSwipe.on('change', () => that.options.changeCallback(that))
      }

      that.photoSwipeCaptionPlugin = new window.Folio.PhotoSwipeDynamicCaption({
        on: () => {},
        pswp: that.photoSwipe
      }, {
        captionContent: (slide) => {
          if (slide.data.caption || slide.data.author) {
            let content = '<div class="f-pswp__caption">'

            if (slide.data.caption) {
              content += `<div class="f-pswp__caption-caption">${slide.data.caption}</div>`
            }

            if (slide.data.author) {
              content += `<div class="f-pswp__caption-author">${window.Folio.Lightbox.authorLabel}: ${slide.data.author}</div>`
            }

            content += '</div>'

            return content
          }
        }
      })

      that.photoSwipeCaptionPlugin.initPlugin()

      that.photoSwipe.init()
    })
  }

  items () {
    const items = []

    $(this.selector).each((i, el) => {
      const item = this.item(i, el)

      if (item) items.push(item)
    })

    return items
  }

  item (index, el) {
    let $el = $(el)

    if ($el.hasClass('f-image--sensitive-content')) {
      if (!this.$html.hasClass('f-html--show-sensitive-content')) return
    }

    if (!$el.data('lightbox-src')) {
      $el = $(el).find('[data-lightbox-src]')
    }

    if (!$el.length) return null

    return {
      w: parseInt($el.data('lightbox-width')),
      h: parseInt($el.data('lightbox-height')),
      caption: $el.data('lightbox-caption') || $el.next('figcaption').text(),
      author: $el.data('lightbox-author'),
      src: window.Folio.Webp.supported ? $el.data('lightbox-webp-src') : $el.data('lightbox-src'),
      el: el
    }
  }

  unbind () {
    $(document).off(`click.${this.eventIdentifier}`, this.fullSelector)
  }

  destroy () {
    try {
      this.photoSwipe.close()
      this.photoSwipe.destroy()
    } catch (_error) {
    }

    this.photoSwipe = null
    this.unbind()
  }
}
