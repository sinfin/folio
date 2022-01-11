window.folioS3Upload = {}

window.folioS3Upload.newUpload = ({ filesUrl, file, done, fail }) => {
  return $.ajax({
    url: `${filesUrl}/s3_before`,
    type: 'POST',
    data: { file_name: file.name }
  }).done(done || () => {}).fail(fail || () => {})
}
