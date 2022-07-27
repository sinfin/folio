window.Folio = window.Folio || {}
window.Folio.ImageSensitiveContentModal = {}

window.Folio.ImageSensitiveContentModal.open = (selector) => $(selector).modal()

window.Folio.Lightbox.bind('.f-image--lightboxable:not(.f-image--cloned):not(.f-image--custom-lightbox)')
