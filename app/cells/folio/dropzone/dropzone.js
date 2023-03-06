//= require folio/api
//= require folio/s3-upload
//= require dropzone/dist/dropzone

window.Folio = window.Folio || {}
window.Folio.Dropzone = window.Folio.Dropzone || {}

window.Folio.Dropzone.SELECTOR = '.f-dropzone__dropzone'

window.Folio.Dropzone.bind = (wrap) => {
  const $wrap = $(wrap)

  wrap.classList.add('dropzone')

  window.Folio.S3Upload.createDropzone({
    element: wrap,
    fileType: wrap.getAttribute('data-file-type'),
    dontRemoveFileOnSuccess: true,
    dropzoneOptions: {
      clickable: wrap,
      createImageThumbnails: wrap.getAttribute('data-create-thumbnails') !== null,
      previewsContainer: null,
    },
  })

  // const options = {
  //   ...$wrap.data('dict'),
  //   url: $wrap.data('create-url'),
  //   paramName: $wrap.data('param-name'),
  //   addRemoveLinks: true,
  //   createImageThumbnails: $wrap.data('create-thumbnails'),
  //   maxThumbnailFilesize: 15,
  //   thumbnailWidth: 250,
  //   thumbnailHeight: 250,
  //   maxFilesize: 100,
  //   maxFiles: $wrap.data('max-files') || null,
  //   timeout: 0,
  //   acceptedFiles: $wrap.data('file-formats') || null,
  //   removedfile: function (file) {
  //     let id, url
  //     if (file.status !== 'error') {
  //       try {
  //         id = file.id || JSON.parse(file.xhr.response).id
  //         url = $wrap.data('destroy-url').replace('ID', id)
  //         $.ajax({
  //           method: 'DELETE',
  //           url,
  //           success: function () {
  //             return $(file.previewElement).remove()
  //           },
  //           error: function () {
  //             return window.alert($wrap.data('destroy-failure'))
  //           }
  //         })
  //       } catch (error) {
  //         window.alert($wrap.data('destroy-failure'))
  //       }
  //     }
  //     return $wrap.toggleClass('dz-started', $wrap.find('.dz-preview').length !== 0)
  //   }
  // }

  // if ($wrap.data('index-url')) {
  //   $.get($wrap.data('index-url'), (res) => {
  //     let attachment, file, i, len
  //     if (res) {
  //       for (i = 0, len = res.length; i < len; i++) {
  //         attachment = res[i]
  //         file = {
  //           id: attachment.id,
  //           name: attachment.file_name,
  //           size: attachment.file_size
  //         }
  //         wrap.dropzone.files.push(file)
  //         wrap.dropzone.emit('addedfile', file)
  //         if (attachment.thumb) {
  //           wrap.dropzone.emit('thumbnail', file, attachment.thumb)
  //         }
  //         wrap.dropzone.emit('complete', file)
  //       }
  //     }
  //     return $wrap.removeClass('f-dropzone__dropzone--loading')
  //   })
  // }

  // if ($wrap.data('records')) {
  //   return $wrap.data('records').forEach((attachment) => {
  //     const file = {
  //       id: attachment.id,
  //       name: attachment.file_name,
  //       size: attachment.file_size
  //     }

  //     wrap.dropzone.files.push(file)
  //     wrap.dropzone.emit('addedfile', file)

  //     if (attachment.thumb) {
  //       wrap.dropzone.emit('thumbnail', file, attachment.thumb)
  //     }

  //     return wrap.dropzone.emit('complete', file)
  //   })
  // }
}

window.Folio.Dropzone.unbind = (dropzone) => {
  if (dropzone.dropzone) dropzone.dropzone.destroy()
}

window.Folio.Dropzone.bindAll = ($wrap) => {
  $wrap = $wrap || $(document.body)
  $wrap.find(window.Folio.Dropzone.SELECTOR).each((i, dropzone) => { window.Folio.Dropzone.bind(dropzone) })
}

window.Folio.Dropzone.unbindAll = ($wrap) => {
  $wrap = $wrap || $(document.body)
  $wrap.find(window.Folio.Dropzone.SELECTOR).each((i, dropzone) => { window.Folio.Dropzone.unbind(dropzone) })
}

if (typeof Turbolinks === 'undefined') {
  $(() => { window.Folio.Dropzone.bindAll() })
} else {
  $(document)
    .on('turbolinks:load', () => { window.Folio.Dropzone.bindAll() })
    .on('turbolinks:before-render', () => { window.Folio.Dropzone.unbindAll() })
}
