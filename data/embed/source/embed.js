(() => {
  const createEmbedElement = (data) => {
    const container = document.createElement('div')
    container.className = 'f-embed__container'

    const urlParams = new URLSearchParams(window.location.search)
    
    if (urlParams.get('centered') === '1') {
      container.classList.add('f-embed__container--centered')
    }

    const backgroundColor = urlParams.get('backgroundColor')
    if (backgroundColor && /^#[0-9A-Fa-f]{6}$/.test(backgroundColor)) {
      document.documentElement.style.backgroundColor = backgroundColor
      document.body.style.backgroundColor = backgroundColor
    }

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
          container.classList.add('f-embed__container--youtube')
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

        if (statusId) {
          container.innerHTML = `
            <blockquote class="twitter-tweet" data-conversation="none" data-dnt="true" data-theme="light">
              <p lang="en" dir="ltr"></p>
              <a target="_blank" href="${url}">View this Tweet</a>
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
            // Handle tweet embeds
            const tweets = document.querySelectorAll('.twitter-tweet')
            tweets.forEach(tweet => {
              const url = tweet.querySelector('a')?.href
              if (url && window.twttr.widgets.createTweet) {
                const statusMatch = url.match(/status\/(\d+)/)
                if (statusMatch) {
                  const tweetId = statusMatch[1]
                  window.twttr.widgets.createTweet(tweetId, tweet.parentElement, {
                    conversation: 'none',
                    theme: 'light'
                  }).then(element => {
                    if (element) {
                      tweet.style.display = 'none'
                    }
                  })
                }
              }
            })
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
