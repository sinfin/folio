window.FolioConsole = window.FolioConsole || {}
window.FolioConsole.PrivateAttachments = window.FolioConsole.PrivateAttachments || {}
window.FolioConsole.PrivateAttachments.Fields = {}

window.FolioConsole.PrivateAttachments.Fields.SELECTOR = ".f-c-private-attachments-fields__dropzone"

window.FolioConsole.PrivateAttachments.Fields.init = (el) => {
  window.FolioConsole.S3Upload.createConsoleDropzone({
    element: el
  })
}

window.FolioConsole.PrivateAttachments.Fields.initIn = ($wrap) => {
  $wrap.find(window.FolioConsole.PrivateAttachments.Fields.SELECTOR).each((i, el) => {
    window.FolioConsole.PrivateAttachments.Fields.init(el)
  })
}

window.FolioConsole.PrivateAttachments.Fields.initAll = () => {
  window.FolioConsole.PrivateAttachments.Fields.initIn($('body'))
}

window.FolioConsole.PrivateAttachments.Fields.destroy = (el) => {
  console.log('destroy', el)
}

window.FolioConsole.PrivateAttachments.Fields.destroyIn = ($wrap) => {
  $wrap.find(window.FolioConsole.PrivateAttachments.Fields.SELECTOR).each((i, el) => {
    window.FolioConsole.PrivateAttachments.Fields.destroy(el)
  })
}

window.FolioConsole.PrivateAttachments.Fields.destroyAll = () => {
  window.FolioConsole.PrivateAttachments.Fields.destroyIn($('body'))
}

if (typeof(Turbolinks) === 'undefiend') {
  $(() => { window.FolioConsole.PrivateAttachments.Fields.initAll() })
} else {
  $(document)
    .on('turbolinks:load', window.FolioConsole.PrivateAttachments.Fields.initAll)
    .on('turbolinks:before-render', window.FolioConsole.PrivateAttachments.Fields.destroyAll)
}

$(document)
  .on('cocoon:after-insert', (e, insertedItem) => {
    window.FolioConsole.PrivateAttachments.Fields.initIn($(insertedItem))
  })
  .on('cocoon:before-remove', (e, item) => {
    window.FolioConsole.PrivateAttachments.Fields.destroyIn($(item))
  })
