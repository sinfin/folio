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
window.Folio.Thumbnails.LOAD_INTERVAL = 2100 // 2 seconds and a bit - cache is set to 2s

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

    // Build URL with query parameters for GET request
    const url = new URL(window.Folio.Thumbnails.API_URL, window.location.origin)
    url.searchParams.set('thumbnails', JSON.stringify(thumbnailRequests))

    window.Folio.Api.apiGet(url.toString()).then((res) => {
      // Handle the response and dispatch events for ready thumbnails
      window.Folio.Thumbnails.handleResponse(res)
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

window.Folio.Thumbnails.handleResponse = (response) => {
  if (!Array.isArray(response)) return

  // Process each thumbnail in the response
  response.forEach(thumbnail => {
    // Only handle ready thumbnails
    if (!thumbnail.ready || !thumbnail.url) return

    // Find elements that match this thumbnail
    for (const [element, elementData] of window.Folio.Thumbnails.scheduled.entries()) {
      // Check if any of the element's thumbnail data matches this response
      const matchingData = elementData.find(data =>
        data.id === thumbnail.id.toString() && data.size === thumbnail.size
      )

      if (matchingData) {
        // Dispatch event to the element with the new thumbnail data
        element.dispatchEvent(new CustomEvent(window.Folio.Thumbnails.EVENT_NAME, {
          detail: {
            id: thumbnail.id,
            size: thumbnail.size,
            url: thumbnail.url,
            ready: thumbnail.ready,
            originalData: matchingData
          },
          bubbles: true
        }))
      }
    }
  })
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
        this.updateImageSources(e.detail)
        this.cleanup()
      }

      this.element.addEventListener(window.Folio.Thumbnails.EVENT_NAME, this.handleNewData)

      window.Folio.Thumbnails.schedule({ data, element: this.element })
    } else {
      this.removeController()
    }
  }

  disconnect () {
    this.cleanup()
  }

  removeController () {
    if (!this.element.dataset.controller) return

    if (this.element.dataset.controller === window.Folio.Thumbnails.CONTROLLER_NAME) {
      delete this.element.dataset.controller
    } else {
      this.element.dataset.controller = this.element.dataset.controller.replace(window.Folio.Thumbnails.CONTROLLER_REGEX, '')
    }
  }

  getData () {
    const data = []

    try {
      // Only handle img elements with src attributes
      let image = null

      if (this.element.tagName.toLowerCase() === 'img') {
        image = this.element
      }

      if (image && image.src) {
        const result = this.dataFromString(image.src)
        if (result) data.push(result)
      }
    } catch (error) {
      console.warn('Error extracting thumbnail data:', error)
    }

    return data
  }

  dataFromString (string) {
    if (!string || typeof string !== 'string') return null

    try {
      const url = new URL(string)
      const params = new URLSearchParams(url.search)

      const id = params.get('image')
      const size = params.get('size')

      // Only return data if we have all components: url, id, and size
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

  updateImageSources (thumbnailData) {
    try {
      let image = null

      if (this.element.tagName.toLowerCase() === 'img') {
        image = this.element
      }

      // Update img src if it matches the thumbnail
      if (image && this.urlMatches(image.src, thumbnailData)) {
        image.src = thumbnailData.url
      }
    } catch (error) {
      console.warn('Error updating image sources:', error)
    }
  }

  urlMatches (url, thumbnailData) {
    try {
      const parsedUrl = new URL(url)
      const params = new URLSearchParams(parsedUrl.search)
      const id = params.get('image')
      const size = params.get('size')

      return id === thumbnailData.id.toString() && size === thumbnailData.size
    } catch (error) {
      return false
    }
  }

  cleanup () {
    if (this.handleNewData) {
      // Remove from scheduled collection
      window.Folio.Thumbnails.remove({ element: this.element })

      // Remove event listener
      this.element.removeEventListener(window.Folio.Thumbnails.EVENT_NAME, this.handleNewData)
      delete this.handleNewData
    }

    // Remove controller from element
    this.removeController()
  }
})

window.Folio.Thumbnails.stopTimer = () => {
  window.Folio.Thumbnails.clearTimer()
}

if (window.Folio.MessageBus) {
  window.Folio.MessageBus.callbacks[window.Folio.Thumbnails.JOB_TYPE] = (data) => {
    if (!data || data.type !== window.Folio.Thumbnails.JOB_TYPE) return
    if (!data.data?.id || !data.data?.size || !data.data?.url) return

    // Trigger the polling system's event for elements waiting for this thumbnail
    const thumbnailEvent = new CustomEvent(window.Folio.Thumbnails.EVENT_NAME, {
      detail: {
        id: data.data.id,
        size: data.data.size,
        url: data.data.url,
        ready: true,
        width: data.data.width,
        height: data.data.height
      },
      bubbles: true
    })

    // Dispatch to all elements that might be waiting for this thumbnail
    for (const [element, elementData] of window.Folio.Thumbnails.scheduled.entries()) {
      const matchingData = elementData.find(item =>
        item.id === data.data.id.toString() && item.size === data.data.size
      )
      if (matchingData) {
        element.dispatchEvent(thumbnailEvent)
      }
    }
  }
}
