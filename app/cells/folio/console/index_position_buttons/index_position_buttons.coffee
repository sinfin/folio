rowChildren = ($row) ->
  id = $row.find('.folio-console-input-id').val()
  $row.nextAll("tr[data-parent='#{id}']")

switchRows = (tr) ->
  inputs =
    btn: tr.btn.find('.folio-console-input-position')
    target: tr.target.find('.folio-console-input-position')

  pos =
    btn: inputs.btn.val()
    target: inputs.target.val()

  inputs.btn.val pos.target
  inputs.target.val pos.btn

  # using past value
  if parseInt(pos.btn) > parseInt(pos.target)
    tr.btn.add(rowChildren(tr.btn)).insertBefore tr.target
  else
    tr.btn.add(rowChildren(tr.btn)).insertAfter tr.target

#   this_pos = this_node.find('input#node_position').val()
#   that_pos = that_node.find('input#node_position').val()
#   this_node.find('input#node_position').val(that_pos)
#   that_node.find('input#node_position').val(this_pos)
#   this_node_id = this_node.find('input#node_id').val()
#   this_node_children = this_node.nextAll("tr[data-parent='#{this_node_id}']")
#   that_node_id = that_node.find('input#node_id').val()
#   that_node_children = that_node.nextAll("tr[data-parent='#{that_node_id}']")
#   this_node.after(that_node)

#   if this_node_children
#     moveChildrenRows(this_node, this_node_children)
#   if that_node_children
#     moveChildrenRows(that_node, that_node_children)

# moveChildrenRows = (node, children) ->
#   last_row = node
#   children.each ->
#     $t = $(this)
#     last_row.after($t)
#     last_row = $t

getTr = ($btn) ->
  $btnTr = $btn.closest('tr')
  dataParent = $btnTr.data('parent')
  dataDepth = $btnTr.data('depth')

  switch $btn.data('direction')
    when 'up'
      if dataParent? and dataDepth?
        $targetTr = $btnTr.prevAll("tr[data-parent='#{dataParent}'][data-depth='#{dataDepth}']:first")
      else
        $targetTr = $btnTr.prevAll("tr:first")

    when 'down'
      if dataParent? and dataDepth?
        $targetTr = $btnTr.nextAll("tr[data-parent='#{dataParent}'][data-depth='#{dataDepth}']:first")
      else
        $targetTr = $btnTr.nextAll("tr:first")

    else
      return null

  return null if $targetTr.length isnt 1

  {
    btn: $btnTr
    target: $targetTr
  }

post = (tr, url) ->
  data = {}

  data[tr.btn.find('.folio-console-input-id').val()] =
    position: tr.target.find('.folio-console-input-position').val()

  data[tr.target.find('.folio-console-input-id').val()] =
    position: tr.btn.find('.folio-console-input-position').val()

  tr.btn.addClass('folio-console-loading')
  tr.target.addClass('folio-console-loading')

  ajax = $.ajax({
    url: url
    type: 'POST'
    data: { positions: data }
  })

  ajax
    .done -> switchRows(tr)
    .always ->
      tr.btn.removeClass('folio-console-loading')
      tr.target.removeClass('folio-console-loading')

$(document).on 'click', '.folio-console-index-position-button', (e) ->
  e.preventDefault()
  $btn = $(this)
  $btn.blur()
  tr = getTr($btn)
  return unless tr
  return if tr.btn.hasClass('folio-console-loading')
  return if tr.target.hasClass('folio-console-loading')
  post(tr, $btn.data('url'))
