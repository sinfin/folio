window.Folio = window.Folio || {}
window.Folio.Api = {}

const meta = document.querySelector('meta[name="csrf-token"]')

window.Folio.Api.CSRF_TOKEN = meta
  ? {
      'X-CSRF-Token': meta.getAttribute('content')
    }
  : {}

window.Folio.Api.JSON_HEADERS = {
  ...window.Folio.Api.CSRF_TOKEN,
  Accept: 'application/json',
  'Content-Type': 'application/json'
}

window.Folio.Api.HTML_HEADERS = {
  ...window.Folio.Api.CSRF_TOKEN,
  Accept: 'text/html',
  'Content-Type': 'application/json'
}

const fallbackMessage = (response) => `${response.status}: ${response.statusText}`

const jsonError = (json) => {
  if (!json) return null

  if (json.error) {
    return json.error
  } else if (json.errors) {
    return json.errors.map((err) => {
      if (err.title && err.title.indexOf('::') === -1) {
        return `${err.title}: ${err.detail}`
      }

      return err.detail
    }).join('<br>')
  }

  return null
}

const makeCheckResponse = (asHtml) => (response) => {
  if (response.ok) return Promise.resolve(response)

  if (asHtml && response.redirected) {
    return Promise.resolve(response)
  }

  return response.json()
    .catch(() => Promise.reject(new Error(fallbackMessage(response))))
    .then((json) => {
      if (json.data) {
        return Promise.resolve(json)
      }

      const err = jsonError(json)

      if (err) {
        return Promise.reject(new Error(err))
      } else {
        return Promise.reject(new Error(fallbackMessage(response)))
      }
    })
}

function responseToJson (response) {
  if (response.status === 204) return Promise.resolve({})

  if (!response.status && response.data) {
    return response
  } else {
    return response.json()
  }
}

function responseToHtml (response) {
  if (response.status === 204) return Promise.resolve('')

  if (response.redirected) {
    if (response.url) {
      const urlObj = new URL(response.url)
      const queryParams = urlObj.searchParams
      const anchor = queryParams.get("_anchor")

      if (anchor) {
        queryParams.delete("_anchor")
        urlObj.search = queryParams.toString()
        return Promise.resolve(`{ "data": { "redirected": "${urlObj}#${anchor}" }}`)
      }

      return Promise.resolve(`{ "data": { "redirected": "${response.url}" }}`)
    }

    return Promise.resolve('{ "data": { "redirected": true }}')
  }
  return response.text()
}

window.Folio.Api.flashMessageFromMeta = (response) => {
  if (window.FolioConsole && window.FolioConsole.Flash) {
    if (typeof response === 'object' && response.meta && response.meta.flash) {
      if (response.meta.flash.success) {
        window.FolioConsole.Flash.success(response.meta.flash.success)
      } else if (response.meta.flash.alert) {
        window.FolioConsole.Flash.alert(response.meta.flash.alert)
      }
    }
  }

  return response
}

window.Folio.Api.api = (method, url, body, signal) => {
  const data = {
    method,
    headers: window.Folio.Api.JSON_HEADERS,
    credentials: 'same-origin'
  }

  // AbortController signal
  if (signal) data.signal = signal

  // need to have this extra for MS Edge
  if (body) data.body = JSON.stringify(body)

  return fetch(url, data).then(makeCheckResponse(false)).then(responseToJson).then(window.Folio.Api.flashMessageFromMeta)
}

window.Folio.Api.apiPost = (url, body, signal) => {
  return window.Folio.Api.api('POST', url, body, signal)
}

window.Folio.Api.apiPatch = (url, body, signal) => {
  return window.Folio.Api.api('PATCH', url, body, signal)
}

window.Folio.Api.apiPut = (url, body, signal) => {
  return window.Folio.Api.api('PUT', url, body, signal)
}

window.Folio.Api.apiGet = (url, body = null, signal) => {
  return window.Folio.Api.api('GET', url, body, signal)
}

window.Folio.Api.apiDelete = (url, body = null, signal) => {
  return window.Folio.Api.api('DELETE', url, body, signal)
}

window.Folio.Api.htmlApi = (method, url, body, signal) => {
  const data = {
    method,
    headers: window.Folio.Api.HTML_HEADERS,
    credentials: 'same-origin'
  }

  // AbortController signal
  if (signal) data.signal = signal

  // need to have this extra for MS Edge
  if (body) data.body = JSON.stringify(body)

  return fetch(url, data).then(makeCheckResponse(true)).then(responseToHtml).then(window.Folio.Api.flashMessageFromMeta)
}

window.Folio.Api.apiHtmlGet = (url, body = null, signal) => {
  return window.Folio.Api.htmlApi('GET', url, body, signal)
}

window.Folio.Api.apiHtmlPost = (url, body) => {
  return window.Folio.Api.htmlApi('POST', url, body)
}

window.Folio.Api.apiHtmlPatch = (url, body) => {
  return window.Folio.Api.htmlApi('PATCH', url, body)
}

window.Folio.Api.apiXhrFilePut = (url, file) => {
  return new Promise((resolve, reject) => {
    const xhr = new window.XMLHttpRequest()

    xhr.open('PUT', url)

    xhr.onload = () => {
      if (xhr.status >= 200 && xhr.status < 300) {
        resolve(xhr.response)
      } else {
        reject(new Error(`${xhr.status} ${xhr.statusText}`))
      }
    }

    xhr.onerror = () => {
      reject(new Error(`${xhr.status} ${xhr.statusText}`))
    }

    xhr.send(file)

    return xhr
  })
}
