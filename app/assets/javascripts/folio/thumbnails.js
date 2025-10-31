window.Folio = window.Folio || {}
window.Folio.Thumbnails = {}

if (window.Folio.MessageBus) {
  window.Folio.MessageBus.callbacks['Folio::GenerateThumbnailJob'] = (data) => {
    if (!data || data.type !== 'Folio::GenerateThumbnailJob') return
    if (!data.data.temporary_url || !data.data.url) return

    for (const img of document.querySelectorAll(`img[src='${data.data.temporary_url}']`)) {
      img.src = data.data.url
      img.dispatchEvent(new CustomEvent('Folio::GenerateThumbnailJob/updated', { bubbles: true }))

      const a = img.closest('a[href="' + data.data.temporary_url + '"]')
      if (a) a.href = data.data.url
    }

    for (const img of document.querySelectorAll(`img[src='${data.data.temporary_url}&webp=1']`)) {
      img.src = data.data.webp_url
      img.dispatchEvent(new CustomEvent('Folio::GenerateThumbnailJob/updated', { bubbles: true }))

      const a = img.closest('a[href="' + data.data.temporary_url + '&webp=1"]')
      if (a) a.href = data.data.webp_url
    }

    for (const img of document.querySelectorAll(`img[srcset*='${data.data.temporary_url}']`)) {
      img.srcset = img.srcset.replace(data.data.temporary_url, data.data.url)
    }

    for (const img of document.querySelectorAll(`[data-lightbox-src='${data.data.temporary_url}']`)) {
      img.dataset.lightboxSrc = data.data.url
      img.dataset.lightboxWidth = data.width
      img.dataset.lightboxHeight = data.height
    }
  }
}
