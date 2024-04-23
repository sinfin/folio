//= require photoswipe.esm.folio
//= require photoswipe-dynamic-caption-plugin.esm

window.Folio.Stimulus.register('f-lightbox', class extends window.Stimulus.Controller {
  static targets = ['item']

  onItemClick (e) {
    e.preventDefault()

    if (e.currentTarget.dataset.fLightboxIndex) {
      this.startPhotoSwipe(parseInt(e.currentTarget.dataset.fLightboxIndex))
    } else {
      this.startPhotoSwipe(this.itemTargets.indexOf(e.currentTarget))
    }
  }

  dataSource () {
    return this.itemTargets.map((itemTarget) => ({
      ...JSON.parse(itemTarget.dataset.photoswipe),
      el: itemTarget
    }))
  }

  startPhotoSwipe (index) {
    const photoSwipe = new window.Folio.PhotoSwipe({
      dataSource: this.dataSource(),
      index
    })

    const photoSwipeCaptionPlugin = new window.Folio.PhotoSwipeDynamicCaption({
      on: () => {},
      pswp: photoSwipe
    }, {
      type: 'auto',
      captionContent: (slide) => {
        if (slide.data.caption || slide.data.author) {
          let content = '<div class="f-pswp__caption">'

          if (slide.data.caption) {
            content += `<div class="f-pswp__caption-caption">${slide.data.caption}</div>`
          }

          if (slide.data.author) {
            const authorLabel = document.documentElement.lang === 'cs' ? 'Foto' : 'Photo'
            content += `<div class="f-pswp__caption-author">${authorLabel}: ${slide.data.author}</div>`
          }

          content += '</div>'

          return content
        }
      }
    })

    photoSwipeCaptionPlugin.initPlugin()

    photoSwipe.init()
  }
})
