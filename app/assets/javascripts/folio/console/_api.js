window.FolioConsole = window.FolioConsole || {}
window.FolioConsole.Api = {}

const meta = document.querySelector('meta[name="csrf-token"]')

window.FolioConsole.Api.CSRF_TOKEN = meta ? {
  'X-CSRF-Token': meta.getAttribute('content')
} : {}

window.FolioConsole.Api.JSON_HEADERS = {
  ...window.FolioConsole.Api.CSRF_TOKEN,
  'Accept': 'application/json',
  'Content-Type': 'application/json'
}

window.FolioConsole.Api.HTML_HEADERS = {
  ...window.FolioConsole.Api.CSRF_TOKEN,
  'Accept': 'text/html',
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
      flashSuccess(response.meta.flash.success)
    } else if (response.meta.flash.alert) {
      flashError(response.meta.flash.alert)
    }
  }
  return response
}

window.FolioConsole.Api.api = (method, url, body) => {
  const data = {
    method,
    headers: window.FolioConsole.Api.JSON_HEADERS,
    credentials: 'same-origin'
  }

  // need to have this extra for MS Edge
  if (body) data.body = JSON.stringify(body)

  return fetch(url, data).then(checkResponse).then(responseToJson).then(flashMessageFromMeta)
}

window.FolioConsole.Api.apiPost = (url, body) => {
  return window.FolioConsole.Api.api('POST', url, body)
}

window.FolioConsole.Api.apiPut = (url, body) => {
  return window.FolioConsole.Api.api('PUT', url, body)
}

window.FolioConsole.Api.apiGet = (url, body = null) => {
  return window.FolioConsole.Api.api('GET', url, body)
}

window.FolioConsole.Api.apiDelete = (url) => {
  return window.FolioConsole.Api.api('DELETE', url, null)
}

window.FolioConsole.Api.htmlApi = (method, url, body) => {
  const data = {
    method,
    headers: window.FolioConsole.Api.HTML_HEADERS,
    credentials: 'same-origin'
  }
  // need to have this extra for MS Edge
  if (body) data.body = JSON.stringify(body)

  return fetch(url, data).then(checkResponse).then(responseToHtml).then(flashMessageFromMeta)
}

window.FolioConsole.Api.apiHtmlPost = (url, body) => {
  return window.FolioConsole.Api.htmlApi('POST', url, body)
}

window.FolioConsole.Api.apiFilePost = (url, file) => {
  const data = {
    method: 'POST',
    headers: { ...window.FolioConsole.Api.CSRF_TOKEN },
    credentials: 'same-origin',
    body: file
  }

  return fetch(url, data).then(checkResponse).then(responseToJson).then(flashMessageFromMeta)
}
