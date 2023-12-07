window.FolioConsole = window.FolioConsole || {}
window.FolioConsole.PrivateAttachments = window.FolioConsole.PrivateAttachments || {}
window.FolioConsole.PrivateAttachments.Fields = {}

window.FolioConsole.PrivateAttachments.Fields.SELECTOR = '.f-c-private-attachments-fields-dropzone'

window.FolioConsole.PrivateAttachments.Fields.init = (el, opts) => {
  const $el = $(el)

  const dropzone = window.Folio.S3Upload.createConsoleDropzone({
    element: el.getAttribute('data-dropzone-to-body') === 'true' ? document.body : el,
    fileType: el.getAttribute('data-file-type'),
    fileHumanType: el.getAttribute('data-file-human-type'),
    dropzoneOptions: {
      clickable: el.querySelector(`${window.FolioConsole.PrivateAttachments.Fields.SELECTOR}__trigger`),
      previewsContainer: false,
      previewTemplate: '',
      disablePreviews: true
    },
    onStart: (s3Path, fileAttributes) => {
      $el.find(`${window.FolioConsole.PrivateAttachments.Fields.SELECTOR}__add`).click()

      const $fields = $el.find('.f-c-private-attachments-fields').last()

      $fields
        .find('.f-c-private-attachments-fields__title-input')
        .val(fileAttributes.file_name)

      $fields.attr('data-s3-path', s3Path)
    },
    onSuccess: (s3Path, fileFromApi) => {
      const $fields = $el.find(`.f-c-private-attachments-fields[data-s3-path="${s3Path}"]`)
      if ($fields.length !== 1) return

      $fields
        .find('.f-c-private-attachments-fields__card')
        .addClass('card--fresh')

      const a = document.createElement('a')
      a.href = fileFromApi.attributes.expiring_url
      a.appendChild(window.Folio.Icon.create("file_document", { class: "f-c-private-attachments-fields__file-ico" }))

      $fields
        .find('.f-c-private-attachments-fields__file-col')[0]
        .appendChild(a)

      $fields
        .find('.f-c-private-attachments-fields__id-input')
        .val(fileFromApi.id)

      $fields
        .find('.f-c-private-attachments-fields__dropzone-progress-bar')
        .hide(0)

      $fields.closest('form')[0].dispatchEvent(new window.Event('change', { bubbles: true }))
    },
    onFailure: (s3Path) => {
      const $fields = $el.find(`.f-c-private-attachments-fields[data-s3-path="${s3Path}"]`)
      if ($fields.length !== 1) return
      $fields.remove()
    },
    onProgress: (s3Path, roundedProgress, text) => {
      const $fields = $el.find(`.f-c-private-attachments-fields[data-s3-path="${s3Path}"]`)
      if ($fields.length !== 1) return

      $fields
        .find('.f-c-private-attachments-fields__dropzone-progress-bar')
        .css('width', `${roundedProgress}%`)
    }
  })

  $el.data('folioConsoleDropzone', dropzone)

  if (opts && opts.trigger) {
    $el.click()

    setTimeout(() => {
      console.log('aye')
    }, 0)
  }
}

window.FolioConsole.PrivateAttachments.Fields.initIn = ($wrap, opts) => {
  $wrap.find(window.FolioConsole.PrivateAttachments.Fields.SELECTOR).each((i, el) => {
    window.FolioConsole.PrivateAttachments.Fields.init(el, opts)
  })
}

window.FolioConsole.PrivateAttachments.Fields.initAll = () => {
  window.FolioConsole.PrivateAttachments.Fields.initIn($('body'))
}

window.FolioConsole.PrivateAttachments.Fields.destroy = (el) => {
  const dropzone = $(el).data('folioConsoleDropzone')

  if (dropzone) {
    window.Folio.S3Upload.destroyDropzone(dropzone)
    $(el).data('folioConsoleDropzone', null)
  }
}

window.FolioConsole.PrivateAttachments.Fields.destroyIn = ($wrap) => {
  $wrap.find(window.FolioConsole.PrivateAttachments.Fields.SELECTOR).each((i, el) => {
    window.FolioConsole.PrivateAttachments.Fields.destroy(el)
  })
}

window.FolioConsole.PrivateAttachments.Fields.destroyAll = () => {
  window.FolioConsole.PrivateAttachments.Fields.destroyIn($('body'))
}

window.FolioConsole.PrivateAttachments.Fields.updateSingleFields = (e) => {
  const $el = $(e.currentTarget)

  $el
    .find('.f-c-private-attachments-fields-dropzone__add')
    .prop('hidden', $el.find('.f-c-private-attachments-fields:visible').length > 0)
}

if (typeof (Turbolinks) === 'undefiend') {
  $(() => { window.FolioConsole.PrivateAttachments.Fields.initAll() })
} else {
  $(document)
    .on('turbolinks:load', window.FolioConsole.PrivateAttachments.Fields.initAll)
    .on('turbolinks:before-render', window.FolioConsole.PrivateAttachments.Fields.destroyAll)
    .on('change cocoon:after-remove', '.f-c-private-attachments-fields-dropzone[data-dropzone-single="true"]', window.FolioConsole.PrivateAttachments.Fields.updateSingleFields)
}
