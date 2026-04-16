(() => {
  const relativeLuminance = (hex) => window.Folio.Embed.hexRelativeLuminance(hex)

  const urlParamsForTheme = new URLSearchParams(window.location.search)
  const legacyBackgroundColor = urlParamsForTheme.get('backgroundColor')
  const lightBackgroundColor = urlParamsForTheme.get('lightBackgroundColor')
  const darkBackgroundColor = urlParamsForTheme.get('darkBackgroundColor')

  const validateHexColor = (value) => value && /^#[0-9A-Fa-f]{6}$/.test(value)

  const applyDocumentBackground = (explicitScheme) => {
    let hex = null
    let useDarkClass = false

    if (validateHexColor(lightBackgroundColor) && validateHexColor(darkBackgroundColor)) {
      let scheme
      if (explicitScheme === 'light' || explicitScheme === 'dark') {
        scheme = explicitScheme
      } else {
        scheme = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
      }
      hex = scheme === 'dark' ? darkBackgroundColor : lightBackgroundColor
      useDarkClass = relativeLuminance(hex) < 0.5
    } else if (validateHexColor(legacyBackgroundColor)) {
      hex = legacyBackgroundColor
      useDarkClass = relativeLuminance(hex) < 0.5
    }

    if (!hex) return

    document.documentElement.style.backgroundColor = hex
    document.body.style.backgroundColor = hex
    document.body.classList.toggle('f-embed-body--dark-background', useDarkClass)
  }

  // Script runs in <head>; body may not exist yet — defer theme until DOM is ready.
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
      applyDocumentBackground()
    })
  } else {
    applyDocumentBackground()
  }

  const setDynamicMinHeight = (iframe) => {
    if (!iframe.src || !iframe.src.includes('facebook.com')) return
    if (iframe.style.minHeight) return

    const heightString = iframe.getAttribute('height')
    if (!heightString) return

    const height = parseInt(heightString, 10)

    if (height) {
      iframe.style.minHeight = `${height + 1}px`
    }
  }

  const createEmbedElement = (data) => {
    const container = document.createElement('div')
    container.className = 'f-embed__container'

    const urlParams = new URLSearchParams(window.location.search)

    if (urlParams.get('centered') === '1') {
      container.classList.add('f-embed__container--centered')
    }

    if (data.html) {
      container.innerHTML = data.html

      // Extract and execute scripts manually
      const scripts = container.querySelectorAll('script')
      scripts.forEach(script => {
        const newScript = document.createElement('script')
        if (script.src) {
          newScript.src = script.src
          newScript.async = script.async
        } else {
          newScript.textContent = script.textContent
        }
        document.head.appendChild(newScript)
        script.remove() // Remove the old script to avoid duplication
      })

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

        const isShorts = !videoId && /\/shorts\//.test(url)
        if (!videoId) {
          videoId = url.match(/\/shorts\/([a-zA-Z0-9\-_]+)/)?.[1]
        }

        if (videoId) {
          const width = isShorts ? 360 : 560
          const height = isShorts ? 640 : 315
          const iframeClass = isShorts ? 'f-embed__youtube-iframe f-embed__youtube-iframe--shorts' : 'f-embed__youtube-iframe'

          container.innerHTML = `
            <iframe
              class="${iframeClass}"
              width="${width}"
              height="${height}"
              src="https://www.youtube.com/embed/${videoId}"
              frameborder="0"
              allowfullscreen>
            </iframe>
          `
          container.classList.add('f-embed__container--youtube')
        }
        break
      }

      case 'instagram': {
        const postId = url.match(/\/p\/([a-zA-Z0-9\-_]+)/)?.[1]
        if (postId) {
          container.innerHTML = `
            <blockquote class="instagram-media f-embed__blockquote--instagram" data-instgrm-permalink="${url}">
              <a target="_blank" href="${url}">View this post on Instagram</a>
            </blockquote>

            <span class="f-embed__loader f-embed__loader--instagram"></span>
          `
          container.classList.add('f-embed__container--instagram')

          loadInstagramScript()
        }
        break
      }

      case 'twitter': {
        const statusMatch = url.match(/\/status\/(\d+)/)
        const statusId = statusMatch?.[1]
        // Normalize x.com URLs to twitter.com for widget compatibility
        const twitterUrl = url.replace(/^https?:\/\/(www\.)?x\.com\//, 'https://twitter.com/')

        if (statusId) {
          container.innerHTML = `
            <blockquote class="twitter-tweet" data-conversation="none" data-dnt="true" data-theme="light">
              <p lang="en" dir="ltr"></p>
              <a target="_blank" href="${twitterUrl}">View this Tweet</a>
            </blockquote>
            <span class="f-embed__loader f-embed__loader--twitter"></span>
          `
          container.classList.add('f-embed__container--twitter')
        }
        loadTwitterScript()
        break
      }

      case 'pinterest': {
        const match = url.match(/\/pin\/(?:[^/]*--)?([0-9]+)/)
        const pinId = match?.[1]
        if (pinId) {
          const canonicalUrl = `https://pinterest.com/pin/${pinId}/`
          container.innerHTML = `
            <a data-pin-do="embedPin" data-pin-width="medium" href="${canonicalUrl}"></a>
          `
          container.classList.add('f-embed__container--pinterest')
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
      script.onload = () => {
        if (window.instgrm && window.instgrm.Embeds) {
          window.instgrm.Embeds.process()
        }
      }
      document.head.appendChild(script)
    } else if (window.instgrm) {
      window.instgrm.Embeds.process()
    }
  }

  let twitterLoading = false

  const loadTwitterScript = () => {
    if (!window.twttr && !document.querySelector('script[src*="twitter.com/widgets"]')) {
      const script = document.createElement('script')
      script.src = 'https://platform.twitter.com/widgets.js'
      script.async = true
      script.onload = () => {
        if (window.twttr && window.twttr.widgets) {
          twitterLoading = true
          window.twttr.widgets.load().then(() => {
            twitterLoading = false
          })
        }
      }
      document.head.appendChild(script)
    } else if (window.twttr && window.twttr.widgets && !twitterLoading) {
      twitterLoading = true
      window.twttr.widgets.load().then(() => {
        twitterLoading = false
      })
    }
  }

  const loadPinterestScript = () => {
    if (!window.PinUtils && !document.querySelector('script[src*="pinterest.com/js/pinit"]')) {
      const script = document.createElement('script')
      script.src = 'https://assets.pinterest.com/js/pinit.js'
      script.async = true
      script.onload = () => {
        if (window.PinUtils) {
          window.PinUtils.build()
        }
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

    const iframe = embedElement.querySelector('iframe')
    if (iframe) {
      setDynamicMinHeight(iframe)
    }

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
      case 'f-embed:set-color-scheme': {
        const scheme = e.data.colorScheme
        if (scheme === 'light' || scheme === 'dark') {
          applyDocumentBackground(scheme)
        }
        break
      }
    }
  })

  window.parent.postMessage({ type: 'f-embed:javascript-evaluated' }, window.origin)
})()
