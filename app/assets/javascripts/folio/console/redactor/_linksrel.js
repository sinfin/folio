// add rel input to redactor link component and module

window.Redactor.classes['link.component'].prototype.getData = function () {
  const names = ['url', 'text', 'target', 'title', 'rel']
  const data = {}

  for (let i = 0; i < names.length; i++) {
    data[names[i]] = this._get(names[i])
  }

  return data
}

window.Redactor.classes['link.component'].prototype._get_rel = function () {
  return this.attr('rel')
}

window.Redactor.classes['link.component'].prototype._set_rel = function (rel) {
  if (!rel || rel === '') {
    this.removeAttr('rel')
  } else {
    this.attr('rel', rel)
  }
}

window.Redactor.modules.link.prototype.modals.link = `
  <form action="">
    <div class="form-item">
      <label for="modal-link-url">URL <span class="req">*</span></label>
      <input type="text" id="modal-link-url" name="url">
    </div>

    <div class="form-item">
      <label for="modal-link-text">## text ##</label>
      <input type="text" id="modal-link-text" name="text">
    </div>

    <div class="form-item form-item-title">
      <label for="modal-link-title">## title ##</label>
      <input type="text" id="modal-link-title" name="title">
    </div>

    <div class="form-item form-item-rel">
      <label for="modal-link-rel">Rel</label>
      <input type="text" id="modal-link-rel" name="rel">
    </div>

    <div class="form-item form-item-target">
      <label class="checkbox">
      <input type="checkbox" name="target"> ## link-in-new-tab ## </label>
    </div>
  </form>
`

window.Redactor.modals.link = window.Redactor.modules.link.prototype.modals.link

window.Redactor.modules.link.prototype._setFormData = function ($form, $modal) {
  const linkData = this.$link.getData()
  const data = {
    url: linkData.url,
    text: linkData.text,
    title: linkData.title,
    rel: linkData.rel,
    target: (this.opts.linkTarget || linkData.target)
  }

  if (!this.opts.linkNewTab) $modal.find('.form-item-target').hide()
  if (!this.opts.linkTitle) $modal.find('.form-item-title').hide()

  $form.setData(data)
  this.currentText = $form.getField('text').val()
}

window.Redactor.modules.link.prototype._setLinkData = function (nodes, data, type) {
  data.text = (data.text.trim() === '') ? this._truncateText(data.url) : data.text

  const isTextChanged = (!this.currentText || this.currentText !== data.text)

  this.selection.save()
  for (let i = 0; i < nodes.length; i++) {
    const $link = window.Redactor.create('link.component', this.app, nodes[i])
    const linkData = {}

    if (data.text && isTextChanged) linkData.text = data.text
    if (data.url) linkData.url = data.url
    if (data.rel) linkData.rel = data.rel
    if (data.title !== undefined) linkData.title = data.title
    if (data.target !== undefined) linkData.target = data.target

    $link.setData(linkData)

    // callback
    this.app.broadcast('link.' + type, $link)
  }

  setTimeout(this.selection.restore.bind(this.selection), 0)
}

const LINK_REL_OPTIONS = [
  "alternate",
  "author",
  "bookmark",
  "canonical",
  "dns-prefetch",
  "external",
  "help",
  "icon",
  "license",
  "manifest",
  "me",
  "modulepreload",
  "next",
  "nofollow",
  "noopener",
  "noreferrer",
  "opener",
  "pingback",
  "preconnect",
  "prefetch",
  "preload",
  "prerender",
  "prev",
  "search",
  "stylesheet",
  "tag",
]

window.Redactor.add('plugin', 'linksrel', {
  init: function (app) {
    this.app = app
    this.opts = app.opts
    this.component = app.component
    // local
    this.$select = null
    this.$urlInput = null
  },
  onmodal: {
    link: {
      open: function ($modal, $form) {
        const input = $form.nodes[0].querySelector('#modal-link-rel')
        if (input) {
          input.classList.add('f-input')
          input.classList.add('f-input--autocomplete')
          input.dataset.autocomplete = JSON.stringify(LINK_REL_OPTIONS)
          window.Folio.Input.Autocomplete.bind(input)
          this.autocompleteBound = input
        }
      },
      close: function () {
        if (this.autocompleteBound) {
          window.Folio.Input.Autocomplete.unbind(this.autocompleteBoundInput)
          this.autocompleteBoundInput = null
        }
      }
    }
  },
})
