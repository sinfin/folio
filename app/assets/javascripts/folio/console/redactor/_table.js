if (window.Redactor) {
  (function ($R) {
    $R.add('plugin', 'table', {
      translations: {
        cs: {
          table: 'Tabulka',
          'insert-table': 'Vložit tabulku',
          'insert-row-above': 'Vložit řádek nad',
          'insert-row-below': 'Vložit řádek pod',
          'insert-column-left': 'Vložit sloupec vlevo',
          'insert-column-right': 'Vložit sloupec vpravo',
          'add-head': 'Přidat hlavičku',
          'delete-head': 'Smazat hlavičku',
          'delete-column': 'Smazat sloupec',
          'delete-row': 'Smazat řádek',
          'delete-table': 'Smazat tabulku'
        },
        en: {
          table: 'Table',
          'insert-table': 'Insert table',
          'insert-row-above': 'Insert row above',
          'insert-row-below': 'Insert row below',
          'insert-column-left': 'Insert column left',
          'insert-column-right': 'Insert column right',
          'add-head': 'Add head',
          'delete-head': 'Delete head',
          'delete-column': 'Delete column',
          'delete-row': 'Delete row',
          'delete-table': 'Delete table'
        }
      },
      init: function (app) {
        this.app = app
        this.lang = app.lang
        this.opts = app.opts
        this.caret = app.caret
        this.editor = app.editor
        this.toolbar = app.toolbar
        this.component = app.component
        this.inspector = app.inspector
        this.insertion = app.insertion
        this.selection = app.selection
      },
      // messages
      ondropdown: {
        table: {
          observe: function (dropdown) {
            this._observeDropdown(dropdown)
          }
        }
      },
      onbottomclick: function () {
        this.insertion.insertToEnd(this.editor.getLastNode(), 'table')
      },

      // public
      start: function () {
        const dropdown = {
          observe: 'table',
          'insert-table': {
            title: this.lang.get('insert-table'),
            api: 'plugin.table.insert'
          },
          'insert-row-above': {
            title: this.lang.get('insert-row-above'),
            classname: 'redactor-table-item-observable',
            api: 'plugin.table.addRowAbove'
          },
          'insert-row-below': {
            title: this.lang.get('insert-row-below'),
            classname: 'redactor-table-item-observable',
            api: 'plugin.table.addRowBelow'
          },
          'insert-column-left': {
            title: this.lang.get('insert-column-left'),
            classname: 'redactor-table-item-observable',
            api: 'plugin.table.addColumnLeft'
          },
          'insert-column-right': {
            title: this.lang.get('insert-column-right'),
            classname: 'redactor-table-item-observable',
            api: 'plugin.table.addColumnRight'
          },
          'add-head': {
            title: this.lang.get('add-head'),
            classname: 'redactor-table-item-observable',
            api: 'plugin.table.addHead'
          },
          'delete-head': {
            title: this.lang.get('delete-head'),
            classname: 'redactor-table-item-observable',
            api: 'plugin.table.deleteHead'
          },
          'delete-column': {
            title: this.lang.get('delete-column'),
            classname: 'redactor-table-item-observable',
            api: 'plugin.table.deleteColumn'
          },
          'delete-row': {
            title: this.lang.get('delete-row'),
            classname: 'redactor-table-item-observable',
            api: 'plugin.table.deleteRow'
          },
          'delete-table': {
            title: this.lang.get('delete-table'),
            classname: 'redactor-table-item-observable',
            api: 'plugin.table.deleteTable'
          }
        }
        const obj = {
          title: this.lang.get('table')
        }

        const $button = this.toolbar.addButtonBefore('link', 'table', obj)
        $button.setIcon('<i class="re-icon-table"></i>')
        $button.setDropdown(dropdown)
      },
      insert: function () {
        const rows = 2
        const columns = 3
        let $component = this.component.create('table')

        for (let i = 0; i < rows; i++) {
          $component.addRow(columns)
        }

        $component = this.insertion.insertHtml($component)
        this.caret.setStart($component)
      },
      addRowAbove: function () {
        const $component = this._getComponent()
        if ($component) {
          const current = this.selection.getCurrent()
          const $row = $component.addRowTo(current, 'before')

          this.caret.setStart($row)
        }
      },
      addRowBelow: function () {
        const $component = this._getComponent()
        if ($component) {
          const current = this.selection.getCurrent()
          const $row = $component.addRowTo(current, 'after')

          this.caret.setStart($row)
        }
      },
      addColumnLeft: function () {
        const $component = this._getComponent()
        if ($component) {
          const current = this.selection.getCurrent()

          this.selection.save()
          $component.addColumnTo(current, 'left')
          this.selection.restore()
        }
      },
      addColumnRight: function () {
        const $component = this._getComponent()
        if ($component) {
          const current = this.selection.getCurrent()

          this.selection.save()
          $component.addColumnTo(current, 'right')
          this.selection.restore()
        }
      },
      addHead: function () {
        const $component = this._getComponent()
        if ($component) {
          this.selection.save()
          $component.addHead()
          this.selection.restore()
        }
      },
      deleteHead: function () {
        const $component = this._getComponent()
        if ($component) {
          const current = this.selection.getCurrent()
          const $head = $R.dom(current).closest('thead')
          if ($head.length !== 0) {
            $component.removeHead()
            this.caret.setStart($component)
          } else {
            this.selection.save()
            $component.removeHead()
            this.selection.restore()
          }
        }
      },
      deleteColumn: function () {
        const $component = this._getComponent()
        if ($component) {
          const current = this.selection.getCurrent()

          const $currentCell = $R.dom(current).closest('td, th')
          const nextCell = $currentCell.nextElement().get()
          const prevCell = $currentCell.prevElement().get()

          $component.removeColumn(current)

          if (nextCell) this.caret.setStart(nextCell)
          else if (prevCell) this.caret.setEnd(prevCell)
          else this.deleteTable()
        }
      },
      deleteRow: function () {
        const $component = this._getComponent()
        if ($component) {
          const current = this.selection.getCurrent()

          const $currentRow = $R.dom(current).closest('tr')
          const nextRow = $currentRow.nextElement().get()
          const prevRow = $currentRow.prevElement().get()

          $component.removeRow(current)

          if (nextRow) this.caret.setStart(nextRow)
          else if (prevRow) this.caret.setEnd(prevRow)
          else this.deleteTable()
        }
      },
      deleteTable: function () {
        const table = this._getTable()
        if (table) {
          this.component.remove(table)
        }
      },

      // private
      _getTable: function () {
        const current = this.selection.getCurrent()
        const data = this.inspector.parse(current)
        if (data.isTable()) {
          return data.getTable()
        }
      },
      _getComponent: function () {
        const current = this.selection.getCurrent()
        const data = this.inspector.parse(current)
        if (data.isTable()) {
          const table = data.getTable()

          return this.component.create('table', table)
        }
      },
      _observeDropdown: function (dropdown) {
        const table = this._getTable()
        const items = dropdown.getItemsByClass('redactor-table-item-observable')
        const tableItem = dropdown.getItem('insert-table')
        if (table) {
          this._observeItems(items, 'enable')
          tableItem.disable()
        } else {
          this._observeItems(items, 'disable')
          tableItem.enable()
        }
      },
      _observeItems: function (items, type) {
        for (let i = 0; i < items.length; i++) {
          items[i][type]()
        }
      }
    })
  })(window.Redactor);
  (function ($R) {
    $R.add('class', 'table.component', {
      mixins: ['dom', 'component'],
      init: function (app, el) {
        this.app = app

        // init
        return (el && el.cmnt !== undefined) ? el : this._init(el)
      },

      // public
      addHead: function () {
        this.removeHead()

        const columns = this.$element.find('tr').first().children('td, th').length
        const $head = $R.dom('<thead>')
        const $row = this._buildRow(columns, '<th>')

        $head.append($row)
        this.$element.prepend($head)
      },
      addRow: function (columns) {
        const $row = this._buildRow(columns)
        this.$element.append($row)

        return $row
      },
      addRowTo: function (current, type) {
        return this._addRowTo(current, type)
      },
      addColumnTo: function (current, type) {
        const $current = $R.dom(current)
        const $currentRow = $current.closest('tr')
        const $currentCell = $current.closest('td, th')

        let index = 0
        $currentRow.find('td, th').each(function (node, i) {
          if (node === $currentCell.get()) index = i
        })

        this.$element.find('tr').each(function (node) {
          const $node = $R.dom(node)
          const origCell = $node.find('td, th').get(index)
          const $origCell = $R.dom(origCell)

          const $td = $origCell.clone()
          $td.html('')

          if (type === 'right') $origCell.after($td)
          else $origCell.before($td)
        })
      },
      removeHead: function () {
        const $head = this.$element.find('thead')
        if ($head.length !== 0) $head.remove()
      },
      removeRow: function (current) {
        const $current = $R.dom(current)
        const $currentRow = $current.closest('tr')

        $currentRow.remove()
      },
      removeColumn: function (current) {
        const $current = $R.dom(current)
        const $currentRow = $current.closest('tr')
        const $currentCell = $current.closest('td, th')

        let index = 0
        $currentRow.find('td, th').each(function (node, i) {
          if (node === $currentCell.get()) index = i
        })

        this.$element.find('tr').each(function (node) {
          const $node = $R.dom(node)
          const origCell = $node.find('td, th').get(index)
          const $origCell = $R.dom(origCell)

          $origCell.remove()
        })
      },

      // private
      _init: function (el) {
        let wrapper, element
        if (typeof el !== 'undefined') {
          const $node = $R.dom(el)
          const node = $node.get()
          const $figure = $node.closest('figure')
          if ($figure.length !== 0) {
            wrapper = $figure
            element = $figure.find('table').get()
          } else if (node.tagName === 'TABLE') {
            element = node
          }
        }

        this._buildWrapper(wrapper)
        this._buildElement(element)
        this._initWrapper()
      },
      _addRowTo: function (current, position) {
        const $current = $R.dom(current)
        const $currentRow = $current.closest('tr')
        if ($currentRow.length !== 0) {
          const columns = $currentRow.children('td, th').length
          const $newRow = this._buildRow(columns)

          $currentRow[position]($newRow)

          return $newRow
        }
      },
      _buildRow: function (columns, tag) {
        tag = tag || '<td>'

        const $row = $R.dom('<tr>')
        for (let i = 0; i < columns; i++) {
          const $cell = $R.dom(tag)
          $cell.attr('contenteditable', true)

          $row.append($cell)
        }

        return $row
      },
      _buildElement: function (node) {
        if (node) {
          this.$element = $R.dom(node)
        } else {
          this.$element = $R.dom('<table>')
          this.append(this.$element)
        }
      },
      _buildWrapper: function (node) {
        node = node || '<figure>'

        this.parse(node)
      },
      _initWrapper: function () {
        this.addClass('redactor-component')
        this.attr({
          'data-redactor-type': 'table',
          tabindex: '-1',
          contenteditable: false
        })
      }
    })
  })(window.Redactor)
} else {
  console.error('Missing Redactor JS')
}
