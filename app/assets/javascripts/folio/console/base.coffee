#= require jquery
#= require jquery_ujs
#= require popper
#= require bootstrap-sprockets
#= require dropzone


#= require cocoon
#= require redactor

#= require folio/console/tagsinput/tagsinput

#= require ./redactor-init
#= require ./redactor-imagemanager

#= require ./nodes
#= require ./files

$ ->
  switchNodes = (this_node, that_node) ->
    pos = this_node.find('input#node_position').val()
    that_node.find('input#node_position').val(pos)
    this_node.find('input#node_position').val(Number(pos) + 1)
    this_node_id = this_node.find('input#node_id').val()
    this_node_children = this_node.nextAll("tr[data-parent='#{this_node_id}']")
    that_node_id = that_node.find('input#node_id').val()
    that_node_children = that_node.nextAll("tr[data-parent='#{that_node_id}']")
    this_node.after(that_node)

    this_node_children.each ->
      this_node.after($(this))
    that_node_children.each ->
      that_node.after($(this))

  $(document).on 'change', '#filter-form', ->
    $(this).submit()

  $(document).on 'click', '.btn.node.position-up', ->
    $this_node = $(this).closest('tr')
    $that_node = $this_node.prevAll("tr[data-parent='#{$this_node.data('parent')}'][data-depth='#{$this_node.data('depth')}']:first")

    return if !$that_node

    pos = Number($this_node.find('input#node_position').val())
    data = {}
    data[$this_node.find('input#node_id').val()] = { position: pos + 1 }
    data[$that_node.find('input#node_id').val()] = { position: pos }

    $.ajax
      type: "POST"
      url: '/console/nodes/set_position.json'
      data: { node: data }
      success: (e) ->
        switchNodes($this_node, $that_node)
        return

  $(document).on 'click', '.btn.node.position-down', ->
    $this_node = $(this).closest('tr')
    $that_node = $this_node.nextAll("tr[data-parent='#{$this_node.data('parent')}'][data-depth='#{$this_node.data('depth')}']:first")

    return if !$that_node

    pos = Number($that_node.find('input#node_position').val())
    data = {}
    data[$this_node.find('input#node_id').val()] = { position: pos  }
    data[$that_node.find('input#node_id').val()] = { position: pos + 1 }

    $.ajax(
      type: "POST",
      url: '/console/nodes/set_position.json',
      data: { node: data },
      success: (e) ->
        switchNodes($that_node, $this_node)
    )

  $(document).on 'click', '.btn.atom.position-up', ->
    $this_atom = $(this).closest('.nested-fields')
    $that_atom = $this_atom.prevAll('.nested-fields:first')

    pos = $this_atom.find('.position').val()
    $that_atom.find('.position').val(pos)
    $this_atom.find('.position').val(pos - 1)
    $this_atom.after($that_atom)

  $(document).on 'click', '.btn.atom.position-down', ->
    $this_atom = $(this).closest('.nested-fields')
    $that_atom = $this_atom.nextAll(".nested-fields:first")

    pos = $that_atom.find('.position').val()
    $this_atom.find('.position').val(pos)
    $that_atom.find('.position').val(pos - 1)
    $that_atom.after($this_atom)

  $(document).on 'cocoon:after-insert', (e, insertedItem) ->
    pos = +$(insertedItem).prevAll(".nested-fields:first")
                          .find('.position')
                          .val()
    $(insertedItem).find('.position').val(pos + 1)
