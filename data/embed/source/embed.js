(() => {
  const createEmbedElement = (data) => {
    const container = document.createElement('div')
    container.className = 'f-embed__container'

    if (data.html) {
      container.innerHTML = data.html
      return container
    }

    if (!data.url || !data.type) {
      container.innerHTML = '<p>Invalid embed data</p>'
      return container
    }

    const type = data.type
    const url = data.url

    switch (type) {
      case 'youtube': {
        let videoId = url.match(/[?&]v=([^&]+)/)?.[1]
        if (!videoId) {
          videoId = url.match(/youtu\.be\/([a-zA-Z0-9\-_]+)/)?.[1]
        }

        if (videoId) {
          container.innerHTML = `
            <iframe
              width="560"
              height="315"
              src="https://www.youtube.com/embed/${videoId}"
              frameborder="0"
              allowfullscreen>
            </iframe>
          `
        }
        break
      }

      case 'instagram': {
        const postId = url.match(/\/p\/([a-zA-Z0-9\-_]+)/)?.[1]
        if (postId) {
          container.innerHTML = `
            <blockquote class="instagram-media" data-instgrm-permalink="${url}">
              <a target="_blank" href="${url}">View this post on Instagram</a>
            </blockquote>
          `
          loadInstagramScript()
        }
        break
      }

      case 'twitter':
        container.innerHTML = `
          <blockquote class="twitter-tweet">
            <a target="_blank" href="${url}">View on Twitter</a>
          </blockquote>
        `
        loadTwitterScript()
        break

      case 'facebook':
        container.innerHTML = `
          <div class="fb-post" data-href="${url}">
            <a target="_blank" href="${url}">View on Facebook</a>
          </div>
        `
        loadFacebookScript()
        break

      case 'pinterest': {
        const match = url.match(/\/pin\/(?:[^/]*--)?([0-9]+)/)
        const pinId = match?.[1]
        if (pinId) {
          const canonicalUrl = `https://pinterest.com/pin/${pinId}/`
          container.innerHTML = `
            <a data-pin-do="embedPin" data-pin-width="medium" href="${canonicalUrl}"></a>
          `
          loadPinterestScript()
        }
        break
      }

      default:
        container.innerHTML = `<a href="${url}" target="_blank">View content</a>`
    }

    return container
  }

  const loadInstagramScript = () => {
    if (!window.instgrm && !document.querySelector('script[src*="instagram.com/embed"]')) {
      const script = document.createElement('script')
      script.src = 'https://www.instagram.com/embed.js'
      script.async = true
      document.head.appendChild(script)
    } else if (window.instgrm) {
      window.instgrm.Embeds.process()
    }
  }

  const loadTwitterScript = () => {
    if (!window.twttr && !document.querySelector('script[src*="twitter.com/widgets"]')) {
      const script = document.createElement('script')
      script.src = 'https://platform.twitter.com/widgets.js'
      script.async = true
      document.head.appendChild(script)
    } else if (window.twttr) {
      window.twttr.widgets.load()
    }
  }

  const loadFacebookScript = () => {
    if (!window.FB && !document.querySelector('script[src*="facebook.net/sdk"]')) {
      const script = document.createElement('script')
      script.src = 'https://connect.facebook.net/en_US/sdk.js#xfbml=1&version=v18.0'
      script.async = true
      document.head.appendChild(script)
    } else if (window.FB) {
      window.FB.XFBML.parse()
    }
  }

  const loadPinterestScript = () => {
    if (!window.PinUtils && !document.querySelector('script[src*="pinterest.com/js/pinit"]')) {
      const script = document.createElement('script')
      script.src = 'https://assets.pinterest.com/js/pinit.js'
      script.async = true
      script.onload = () => {
        setTimeout(() => {
          if (window.PinUtils) {
            window.PinUtils.build()
          }
        }, 100)
      }
      document.head.appendChild(script)
    } else if (window.PinUtils) {
      window.PinUtils.build()
    }
  }

  const postResizeMessage = (width, height) => {
    window.parent.postMessage({
      type: 'f-embed:resized',
      width,
      height
    }, window.origin)
  }

  const setupResizeObserver = (element) => {
    if (typeof window.ResizeObserver === 'undefined') return

    const resizeObserver = new window.ResizeObserver(entries => {
      for (const entry of entries) {
        const { width, height } = entry.contentRect
        postResizeMessage(width, height)
      }
    })

    resizeObserver.observe(element)

    // Send initial size
    const rect = element.getBoundingClientRect()
    postResizeMessage(rect.width, rect.height)
  }

  const setData = (data) => {
    if (!data || !data.active) {
      document.body.innerHTML = ''
      return
    }

    const embedElement = createEmbedElement(data)
    document.body.innerHTML = ''
    document.body.appendChild(embedElement)
    setupResizeObserver(embedElement)

    window.parent.postMessage({ type: 'f-embed:rendered-embed' }, window.origin)
  }

  window.addEventListener('message', (e) => {
    if (e.origin !== window.origin) return
    if (!e.data) return

    switch (e.data.type) {
      case 'f-embed:set-data':
        setData(e.data.folioEmbedData)
        break
    }
  })

  window.parent.postMessage({ type: 'f-embed:javascript-evaluated' }, window.origin)
})()
