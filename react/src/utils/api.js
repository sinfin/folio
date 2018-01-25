const HEADERS = {
  'Accept': 'application/json',
  'Content-Type': 'application/json',
  'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
}

const fallbackMessage = (response) => `${response.status}: ${response.statusText}`

const jsonError = (json) => {
  if (!json.status) return null
  if (!json.status.error) return null
  return json.status.error.message || null
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

function api (method, url, body) {
  let data = {
    method,
    headers: HEADERS,
    credentials: 'same-origin',
  }
  // need to have this extra for MS Edge
  if (body) data.body = JSON.stringify(body)

  return fetch(url, data).then(checkResponse).then(responseToJson)
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
