//= require folio/api

window.Folio = window.Folio || {}
window.Folio.Thumbnails = {}

// Constants
window.Folio.Thumbnails.CONTROLLER_NAME = 'f-thumbnail'
window.Folio.Thumbnails.CONTROLLER_REGEX = /\s*f-thumbnail/
window.Folio.Thumbnails.EVENT_NAME = 'f-thumbnail:newData'
window.Folio.Thumbnails.JOB_EVENT_NAME = 'Folio::GenerateThumbnailJob/updated'
window.Folio.Thumbnails.JOB_TYPE = 'Folio::GenerateThumbnailJob'
window.Folio.Thumbnails.API_URL = '/folio/api/thumbnails.json'

window.Folio.Thumbnails.state = 'idle'
window.Folio.Thumbnails.timeout = null
window.Folio.Thumbnails.scheduled = new Map() // Map of element -> data
window.Folio.Thumbnails.LOAD_INTERVAL = 3000 // 3 seconds

window.Folio.Thumbnails.schedule = ({ data, element }) => {
  // Add element and its data to scheduled collection
  window.Folio.Thumbnails.scheduled.set(element, data)

  // Start timer if we just transitioned from idle to having scheduled items
  if (window.Folio.Thumbnails.state === 'idle') {
    window.Folio.Thumbnails.state = 'scheduled'
    window.Folio.Thumbnails.startTimer()
  }
}

window.Folio.Thumbnails.load = () => {
  if (window.Folio.Thumbnails.scheduled.size === 0) {
    window.Folio.Thumbnails.state = 'idle'
    return
  }

  // Collect all scheduled data
  const allData = []
  for (const data of window.Folio.Thumbnails.scheduled.values()) {
    allData.push(...data)
  }

  if (allData.length > 0) {
    window.Folio.Thumbnails.state = 'loading'

    // Format data for API - extract only id and size
    const thumbnailRequests = allData.map(item => ({
      id: item.id,
      size: item.size
    }))

    window.Folio.Api.apiGet(window.Folio.Thumbnails.API_URL, { thumbnails: thumbnailRequests }).then((res) => {
      // TODO: Handle successful response
      console.log('Thumbnails loaded:', res)
    }).catch((error) => {
      console.error('Error loading thumbnails:', error)
    }).finally(() => {
      window.setTimeout(() => {
        // Schedule next load if we still have scheduled elements
        if (window.Folio.Thumbnails.scheduled.size > 0) {
          window.Folio.Thumbnails.state = 'scheduled'
          window.Folio.Thumbnails.scheduleNextLoad()
        } else {
          window.Folio.Thumbnails.state = 'idle'
        }
      }, 0)
    })
  }
}

window.Folio.Thumbnails.remove = ({ element }) => {
  // Remove element from scheduled collection
  window.Folio.Thumbnails.scheduled.delete(element)

  // Stop timer if no more elements are scheduled
  if (window.Folio.Thumbnails.scheduled.size === 0) {
    window.Folio.Thumbnails.stopTimer()
    window.Folio.Thumbnails.state = 'idle'
  }
}

window.Folio.Thumbnails.clearTimer = () => {
  if (window.Folio.Thumbnails.timeout) {
    clearTimeout(window.Folio.Thumbnails.timeout)
    window.Folio.Thumbnails.timeout = null
  }
}

window.Folio.Thumbnails.startTimer = () => {
  // Clear existing timer if running
  window.Folio.Thumbnails.clearTimer()
  window.Folio.Thumbnails.scheduleNextLoad()
}

window.Folio.Thumbnails.scheduleNextLoad = () => {
  window.Folio.Thumbnails.timeout = setTimeout(() => {
    window.Folio.Thumbnails.timeout = null
    window.Folio.Thumbnails.load()
  }, window.Folio.Thumbnails.LOAD_INTERVAL)
}

window.Folio.Stimulus.register(window.Folio.Thumbnails.CONTROLLER_NAME, class extends window.Stimulus.Controller {
  connect () {
    const data = this.getData()

    if (data.length) {
      this.handleNewData = (e) => {
        console.log('handleNewData', e.detail)
      }

      this.element.addEventListener(window.Folio.Thumbnails.EVENT_NAME, this.handleNewData)

      window.Folio.Thumbnails.schedule({ data, element: this.element })
    } else {
      this.element.dataset.controller = this.element.dataset.controller.replace(window.Folio.Thumbnails.CONTROLLER_REGEX, '')
    }
  }

  disconnect () {
    if (this.handleNewData) {
      window.Folio.Thumbnails.remove({ element: this.element })

      this.element.removeEventListener(window.Folio.Thumbnails.EVENT_NAME, this.handleNewData)
      delete this.handleNewData
    }
  }

  getData () {
    const data = []

    try {
      let image, source

      if (this.element.tagName.toLowerCase() === 'img') {
        image = this.element
        const picture = image.closest('picture')

        if (picture) {
          source = picture.querySelector('source')
        }
      } else if (this.element.tagName.toLowerCase() === 'picture') {
        image = this.element.querySelector('img')
        source = this.element.querySelector('source')
      }

      if (image) {
        if (image.src) {
          const result = this.dataFromString(image.src)
          if (result) data.push(result)
        }

        if (image.srcset) {
          const results = this.dataFromSrcset(image.srcset)
          data.push(...results)
        }
      }

      if (source && source.srcset) {
        const results = this.dataFromSrcset(source.srcset)
        data.push(...results)
      }
    } catch (error) {
      console.warn('Error extracting thumbnail data:', error)
    }

    return data
  }

  dataFromSrcset (srcset) {
    if (!srcset || typeof srcset !== 'string') return []

    const results = []
    try {
      const srcsetParts = srcset.split(',').map(part => part.trim())

      for (const part of srcsetParts) {
        if (!part) continue
        const url = part.split(/\s+/)[0] // Get URL before any descriptor (1x, 2x, etc.)
        if (url) {
          const result = this.dataFromString(url)
          if (result) results.push(result)
        }
      }
    } catch (error) {
      console.warn('Error parsing srcset:', error)
    }

    return results
  }

  dataFromString (string) {
    if (!string || typeof string !== 'string') return null

    try {
      const url = new URL(string)
      const params = new URLSearchParams(url.search)

      const id = params.get('image')
      const size = params.get('size')

      // Only return data if we have all three components: url, id, and size
      if (string && id && size) {
        return {
          url: string,
          id,
          size
        }
      }
    } catch (error) {
      // Invalid URL format
      console.warn('Error parsing thumbnail URL:', error)
    }

    return null
  }
})

window.Folio.Thumbnails.stopTimer = () => {
  window.Folio.Thumbnails.clearTimer()
}

if (window.Folio.MessageBus) {
  window.Folio.Thumbnails.updateMessageBusImageElements = (selector, newSrc, temporaryUrl, newHref = null) => {
    try {
      for (const img of document.querySelectorAll(selector)) {
        img.src = newSrc
        img.dispatchEvent(new CustomEvent(window.Folio.Thumbnails.JOB_EVENT_NAME, { bubbles: true }))

        const a = img.closest(`a[href="${temporaryUrl}"]`)
        if (a && newHref) a.href = newHref
      }
    } catch (error) {
      console.warn('Error updating image elements:', error)
    }
  }

  window.Folio.MessageBus.callbacks[window.Folio.Thumbnails.JOB_TYPE] = (data) => {
    if (!data || data.type !== window.Folio.Thumbnails.JOB_TYPE) return
    if (!data.data?.temporary_url || !data.data?.url) return

    // Update regular images
    window.Folio.Thumbnails.updateMessageBusImageElements(
      `img[src='${data.data.temporary_url}']`,
      data.data.url,
      data.data.temporary_url,
      data.data.url
    )

    // Update WebP images
    if (data.data.webp_url) {
      window.Folio.Thumbnails.updateMessageBusImageElements(
        `img[src='${data.data.temporary_url}&webp=1']`,
        data.data.webp_url,
        `${data.data.temporary_url}&webp=1`,
        data.data.webp_url
      )
    }

    // Update srcset attributes
    try {
      for (const img of document.querySelectorAll(`img[srcset*='${data.data.temporary_url}']`)) {
        img.srcset = img.srcset.replace(data.data.temporary_url, data.data.url)
      }
    } catch (error) {
      console.warn('Error updating srcset attributes:', error)
    }

    // Update lightbox data
    try {
      for (const element of document.querySelectorAll(`[data-lightbox-src='${data.data.temporary_url}']`)) {
        element.dataset.lightboxSrc = data.data.url
        if (data.data.width) element.dataset.lightboxWidth = data.data.width
        if (data.data.height) element.dataset.lightboxHeight = data.data.height
      }
    } catch (error) {
      console.warn('Error updating lightbox data:', error)
    }
  }
}
