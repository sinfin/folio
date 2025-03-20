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

window.Redactor.modules.link.prototype._setLinkData = function (nodes, data, type) {
  // only add rel - no other changes
  data.text = (data.text.trim() === '') ? this._truncateText(data.url) : data.text

  const isTextChanged = (!this.currentText || this.currentText !== data.text)

  this.selection.save()

  for (let i = 0; i < nodes.length; i++) {
    const $link = window.$R.create('link.component', this.app, nodes[i])
    const linkData = {}

    if (data.text && isTextChanged) linkData.text = data.text
    if (data.title !== undefined) linkData.title = data.title

    linkData.url = data.url
    linkData.rel = data.rel || false
    linkData.target = data.target || false

    $link.setData(linkData)

    // callback
    this.app.broadcast('link.' + type, $link)
  }

  setTimeout(this.selection.restore.bind(this.selection), 0)
}

window.Redactor.modules.link.prototype.open = function () {
  this.$link = this._buildCurrent()

  if (this.selection.isCollapsed()) {
    this.selection.save()
    this.selectionMarkers = false
  } else {
    this.selection.saveMarkers()
    this.selectionMarkers = true
  }

  document.activeElement.blur()

  const urlJson = {}

  if (this.$link.nodes && this.$link.nodes[0]) {
    urlJson.href = this.$link.nodes[0].getAttribute('href')
    urlJson.label = this.$link.nodes[0].innerText

    if (this.$link.nodes[0].target) {
      urlJson.target = this.$link.nodes[0].target
    }

    if (this.$link.nodes[0].rel) {
      urlJson.rel = this.$link.nodes[0].rel
    }
  }

  const detail = {
    urlJson,
    trigger: this,
    json: true,
    preferredLabel: urlJson.label
  }

  document.querySelector('.f-c-links-modal').dispatchEvent(new window.CustomEvent('f-c-links-modal:open', { detail }))
}

window.Redactor.modules.link.prototype.saveUrlJson = function (urlJson) {
  if (this.selectionMarkers) {
    this.selection.restoreMarkers()
  } else {
    this.selection.restore()
  }

  this.selectionMarkers = false

  const data = {
    text: urlJson.label,
    url: urlJson.href,
    rel: urlJson.rel,
    target: urlJson.target
  }

  if (this._isLink()) {
    this.update(data)
  } else {
    this.insert(data)
  }
}
