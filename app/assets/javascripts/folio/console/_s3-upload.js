window.FolioConsole.S3Upload = {}

window.FolioConsole.S3Upload.HEADERS = {
  'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
  'Accept': 'application/json',
  'Content-Type': 'application/json'
}

window.FolioConsole.S3Upload.newUpload = ({ filesUrl, file }) => {
  return window.FolioConsole.Api.apiPost(`${filesUrl}/s3_before`, { file_name: file.name })
}
