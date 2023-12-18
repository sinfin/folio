(function ($R) {
  $R.add('plugin', 'button', {
    modals: {
      button: `<form action="">
                 <div class="form-item">
                   <label for="redactor-button-link">## button-link ##</label>
                   <input type="text" id="redactor-button-link" name="link" data-controller="f-c-input-url">
                 </div>

                 <div class="form-item">
                   <label for="redactor-button-text">## button-text ##</label>
                   <input type="text" id="redactor-button-text" name="text">
                 </div>

                 <div class="form-item form-item-fill">
                   <label class="checkbox">
                   <input type="checkbox" name="fill" checked> ## button-fill ## </label>
                 </div>
              </form>`
    },
    translations: {
      cs: {
        button: 'Tlačítko',
        'button-link': 'Odkaz',
        'button-text': 'Text',
        'button-fill': 'Zvýraznit',
        change: 'Upravit'
      },
      en: {
        button: 'Button',
        'button-link': 'Link',
        'button-text': 'Text',
        'button-fill': 'Emphasize',
        change: 'Change'
      }
    },
    onmodal: {
      button: {
        open: function ($modal, $form) {
          const node = $modal.app.selection.getCurrent()
          let ref

          if (node != null ? ((ref = node.classList) != null ? ref.contains('folio-redactor-button') : undefined) : undefined) {
            const $a = $(node).find('a')

            $form.getField('fill').nodes[0].checked = !$a.hasClass('btn-redactor--outline')
            $form.getField('link').val($a.attr('href'))
            $form.getField('text').val($a.text())
          }
        },
        opened: function ($modal, $form) {
          return $form.getField('link').focus()
        },
        insert: function ($modal, $form) {
          const data = $form.getData()
          return this.insert(data)
        }
      }
    },
    init: function (app) {
      this.app = app
      this.lang = app.lang
      this.toolbar = app.toolbar
      this.insertion = app.insertion
      this.component = app.component
    },
    start: function () {
      const $button = this.toolbar.addButton('button', {
        title: this.lang.get('button'),
        api: 'plugin.button.open'
      })

      const icon = window.Folio.Ui.Icon.create('button_pointer', {
        height: 16
      })

      return $button.setIcon(icon.outerHTML)
    },
    open: function () {
      return this.app.api('module.modal.build', {
        title: this.lang.get('button'),
        width: '600px',
        name: 'button',
        handle: 'insert',
        commands: {
          insert: {
            title: this.lang.get('insert')
          },
          cancel: {
            title: this.lang.get('cancel')
          }
        }
      })
    },
    oncontextbar: function (e, contextbar) {
      e.preventDefault()

      const data = this.app.inspector.parse(e.target)

      if (!data.isComponentType('button')) {
        return
      }

      const node = data.getComponent()

      const buttons = {
        change: {
          title: this.lang.get('change'),
          api: 'plugin.button.open',
          args: node
        },
        remove: {
          title: this.lang.get('delete'),
          api: 'plugin.button.remove',
          args: node
        }
      }
      return contextbar.set(e, node, buttons, 'bottom')
    },
    remove: function (node) {
      return this.component.remove(node)
    },
    insert: function (data) {
      this.app.api('module.modal.close')

      if (data.text.trim() === '') {
        return
      }

      if (data.link.trim() === '') {
        return
      }

      const $component = this.component.create('button', data)

      return this.insertion.insertHtml($component)
    }
  })
  return $R.add('class', 'button.component', {
    mixins: ['dom', 'component'],

    init: function (app, data) {
      this.app = app
      return this._init(data)
    },

    _init: function (data) {
      this.parse(`<p class="redactor-component folio-redactor-button"><a class="btn btn-redactor btn-redactor--${data.fill ? 'fill' : 'outline'}" href="${data.link}">${data.text}</a></p>`)

      return this.attr({
        'data-redactor-type': 'button',
        tabindex: '-1',
        contenteditable: false
      })
    }
  })
})(window.Redactor)
