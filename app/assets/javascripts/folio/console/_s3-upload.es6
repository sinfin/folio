window.FolioConsole.S3Upload = {}

window.FolioConsole.S3Upload.HEADERS = {
  'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
  'Accept': 'application/json',
  'Content-Type': 'application/json'
}

window.FolioConsole.S3Upload.newUpload = ({ filesUrl, file }) => {
  const data = {
    method: "POST",
    headers: window.FolioConsole.S3Upload.HEADERS,
    credentials: 'same-origin',
    body: JSON.stringify({ file_name: file.name })
  }

  return fetch(url, data).then(checkResponse).then(responseToJson).then(flashMessageFromMeta)
}
