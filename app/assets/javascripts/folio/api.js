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
  return json.error || null
}

function checkResponse (response) {
  if (response.ok) return Promise.resolve(response)

  return response.json()
    .catch(() => Promise.reject(new Error(fallbackMessage(response))))
    .then((json) => {
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
  return response.json()
}

function responseToHtml (response) {
  if (response.status === 204) return Promise.resolve('')
  return response.text()
}

function flashMessageFromMeta (response) {
  if (typeof response === 'object' && response.meta && response.meta.flash) {
    if (response.meta.flash.success) {
      window.FolioConsole.Flash.success(response.meta.flash.success)
    } else if (response.meta.flash.alert) {
      window.FolioConsole.Flash.alert(response.meta.flash.alert)
    }
  }
  return response
}

window.Folio.Api.api = (method, url, body) => {
  const data = {
    method,
    headers: window.Folio.Api.JSON_HEADERS,
    credentials: 'same-origin'
  }

  // need to have this extra for MS Edge
  if (body) data.body = JSON.stringify(body)

  return fetch(url, data).then(checkResponse).then(responseToJson).then(flashMessageFromMeta)
}

window.Folio.Api.apiPost = (url, body) => {
  return window.Folio.Api.api('POST', url, body)
}

window.Folio.Api.apiPut = (url, body) => {
  return window.Folio.Api.api('PUT', url, body)
}

window.Folio.Api.apiGet = (url, body = null) => {
  return window.Folio.Api.api('GET', url, body)
}

window.Folio.Api.apiDelete = (url) => {
  return window.Folio.Api.api('DELETE', url, null)
}

window.Folio.Api.htmlApi = (method, url, body) => {
  const data = {
    method,
    headers: window.Folio.Api.HTML_HEADERS,
    credentials: 'same-origin'
  }
  // need to have this extra for MS Edge
  if (body) data.body = JSON.stringify(body)

  return fetch(url, data).then(checkResponse).then(responseToHtml).then(flashMessageFromMeta)
}

window.Folio.Api.apiHtmlPost = (url, body) => {
  return window.Folio.Api.htmlApi('POST', url, body)
}

window.Folio.Api.apiXhrFilePut = (url, file) => {
  return new Promise((resolve, reject) => {
    const xhr = new window.XMLHttpRequest()

    xhr.open('PUT', url)

    xhr.onload = () => {
      if (xhr.status >= 200 && xhr.status < 300) {
        resolve(xhr.response)
      } else {
        reject({
          status: xhr.status,
          statusText: xhr.statusText
        })
      }
    }

    xhr.onerror = () => {
      reject({
        status: xhr.status,
        statusText: xhr.statusText
      })
    }

    xhr.send(file)

    return xhr
  })
}
