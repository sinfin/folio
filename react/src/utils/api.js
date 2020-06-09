import { flashSuccess, flashError } from 'utils/flash'

const meta = document.querySelector('meta[name="csrf-token"]')

export const CSRF = meta ? {
  'X-CSRF-Token': meta.getAttribute('content')
} : {}

const JSON_HEADERS = {
  ...CSRF,
  Accept: 'application/json',
  'Content-Type': 'application/json'
}

const HTML_HEADERS = {
  ...CSRF,
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
      flashSuccess(response.meta.flash.success)
    } else if (response.meta.flash.alert) {
      flashError(response.meta.flash.alert)
    }
  }
  return response
}

function api (method, url, body) {
  const data = {
    method,
    headers: JSON_HEADERS,
    credentials: 'same-origin'
  }
  // need to have this extra for MS Edge
  if (body) data.body = JSON.stringify(body)

  return fetch(url, data).then(checkResponse).then(responseToJson).then(flashMessageFromMeta)
}

export function apiPost (url, body) {
  return api('POST', url, body)
}

export function apiPut (url, body) {
  return api('PUT', url, body)
}

export function apiGet (url, body = null) {
  return api('GET', url, body)
}

export function apiDelete (url) {
  return api('DELETE', url, null)
}

function htmlApi (method, url, body) {
  const data = {
    method,
    headers: HTML_HEADERS,
    credentials: 'same-origin'
  }
  // need to have this extra for MS Edge
  if (body) data.body = JSON.stringify(body)

  return fetch(url, data).then(checkResponse).then(responseToHtml).then(flashMessageFromMeta)
}

export function apiHtmlPost (url, body) {
  return htmlApi('POST', url, body)
}

export function apiFilePost (url, file) {
  const data = {
    method: 'POST',
    headers: { ...CSRF },
    credentials: 'same-origin',
    body: file
  }

  return fetch(url, data).then(checkResponse).then(responseToJson).then(flashMessageFromMeta)
}
