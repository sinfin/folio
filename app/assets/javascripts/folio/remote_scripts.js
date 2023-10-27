window.Folio = window.Folio || {}
window.Folio.RemoteScripts = {}

window.Folio.RemoteScripts.Data = {
  'js-cookie': {
    urls: ['https://cdnjs.cloudflare.com/ajax/libs/js-cookie/3.0.5/js.cookie.min.js'],
    successCallbacks: [],
    errorCallbacks: []
  },
  bootstrap: {
    urls: ['https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.1/js/bootstrap.bundle.js']
  },
  'cleave-js': {
    urls: ['https://cdnjs.cloudflare.com/ajax/libs/cleave.js/1.0.2/cleave.min.js']
  }
}

window.Folio.RemoteScripts.runSuccessCallbacks = (key) => {
  window.Folio.RemoteScripts.Data[key].successCallbacks.forEach((callback) => { callback() })
  window.Folio.RemoteScripts.Data[key].successCallbacks = []
}

window.Folio.RemoteScripts.runErrorCallbacks = (key) => {
  window.Folio.RemoteScripts.Data[key].errorCallbacks.forEach((callback) => { callback() })
  window.Folio.RemoteScripts.Data[key].errorCallbacks = []
}

window.Folio.RemoteScripts.onLoaded = (key, url) => {
  const data = window.Folio.RemoteScripts.Data[key]
  data.loadedCount = (data.loadedCount || 0) + 1

  if (data.loadedCount === data.urls.length) {
    data.loaded = true
    window.Folio.RemoteScripts.runSuccessCallbacks(key)
  }
}

window.Folio.RemoteScripts.onError = (key, url) => {
  const data = window.Folio.RemoteScripts.Data[key]
  data.error = true

  if (data.loadedCount === data.urls.length) {
    data.loaded = true
    window.Folio.RemoteScripts.runErrorCallbacks(key)
  }
}

window.Folio.RemoteScripts.load = (key) => {
  const data = window.Folio.RemoteScripts.Data[key]
  if (data.loaded) {
    return window.Folio.RemoteScripts.runSuccessCallbacks(key)
  }

  data.loading = true
  data.scripts = data.urls.map((url) => {
    const script = document.createElement('script')

    script.onload = () => {
      window.Folio.RemoteScripts.onLoaded(key, url)
    }

    script.onError = () => {
      window.Folio.RemoteScripts.onError(key, url)
    }

    script.src = url

    document.head.appendChild(script)

    return script
  })
}

window.Folio.RemoteScripts.run = (script, successCallback, errorCallback) => {
  let key

  if (typeof script === 'string') {
    key = script
  } else if (typeof script === 'object') {
    if (script.key && (script.urls || script.url)) {
      key = script.key

      if (!window.Folio.RemoteScripts.Data[key]) {
        window.Folio.RemoteScripts.Data[key] = {
          urls: script.urls || [script.url]
        }
      }
    }
  }

  if (!window.Folio.RemoteScripts.Data[key]) {
    throw new Error(`Missing script data for ${script}`)
  }

  ['successCallbacks', 'errorCallbacks'].forEach((urlKey) => {
    if (!window.Folio.RemoteScripts.Data[key][urlKey]) {
      window.Folio.RemoteScripts.Data[key][urlKey] = []
    }
  })

  if (window.Folio.RemoteScripts.Data[key].loaded) {
    successCallback()
  } else if (window.Folio.RemoteScripts.Data[key].error) {
    errorCallback()
  } else {
    window.Folio.RemoteScripts.Data[key].successCallbacks.push(successCallback)
    window.Folio.RemoteScripts.Data[key].errorCallbacks.push(errorCallback)

    if (!window.Folio.RemoteScripts.Data[key].loading) {
      window.Folio.RemoteScripts.load(key)
    }
  }
}
