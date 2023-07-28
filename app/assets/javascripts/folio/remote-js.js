window.Folio = window.Folio || {}

window.Folio.RemoteJs = {}

window.Folio.RemoteJs.data = {}

window.Folio.RemoteJs.loaded = (url) => {
  if (window.Folio.RemoteJs.data[url]) {
    return window.Folio.RemoteJs.data[url].loaded
  } else {
    return false
  }
}

window.Folio.RemoteJs.load = (url, successCallback, errorCallback) => {
  window.Folio.RemoteJs.data[url] = { loading: true, callbacks: [{ successCallback, errorCallback }] }

  const onLoad = () => {
    window.setTimeout(() => {
      window.Folio.RemoteJs.data[url].callbacks.forEach(({ successCallback, errorCallback }) => successCallback())
      window.Folio.RemoteJs.data[url] = { loaded: true }

      script.removeEventListener('load', onLoad)
      script.removeEventListener('error', onError)
    }, 0)
  }

  const onError = (ev) => {
    window.Folio.RemoteJs.data[url].callbacks.forEach(({ successCallback, errorCallback }) => errorCallback())
    window.Folio.RemoteJs.data[url] = { error: true }

    script.removeEventListener('load', onLoad)
    script.removeEventListener('error', onError)

    document.head.removeChild(script)
  }

  const script = document.createElement('script')

  script.addEventListener('load', onLoad)
  script.addEventListener('error', onError)

  script.setAttribute('type', 'text/javascript')
  script.setAttribute('async', true)
  script.setAttribute('src', url)

  document.head.appendChild(script)
}

window.Folio.RemoteJs.runWhenLoaded = (url, successCallback, errorCallback) => {
  if (window.Folio.RemoteJs.data[url]) {
    if (window.Folio.RemoteJs.data[url].loaded) {
      successCallback()
    } else if (window.Folio.RemoteJs.data[url].error) {
      errorCallback(window.Folio.RemoteJs.data[url].error)
    } else {
      window.Folio.RemoteJs.data[url].callbacks.push({ successCallback, errorCallback })
    }
  } else {
    window.Folio.RemoteJs.load(url, successCallback, errorCallback)
  }
}
