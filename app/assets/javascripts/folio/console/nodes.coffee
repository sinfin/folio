$ ->
  setPagination = (li, page, total_pages) ->
    if page >= 6
      li.prevAll("li.disabled").show()
    else
      li.prevAll("li.disabled").hide()
    if page >= total_pages - 4
      li.nextAll("li.disabled").hide()
    else
      li.nextAll("li.disabled").show()

    li.nextAll("li:not(.disabled)")
      .add(li.prevAll(':not(.disabled)'))
      .hide()
    li.nextAll("li:not(.disabled)").slice(0, 4)
      .add(li.prevAll("li:not(.disabled)").slice(0, 4))
      .show()

  selectRightForm = (element) ->
    $t = $(element)
    klass = $t.val()
    form = $t.find(':selected').data('form')
    $fields = $t.closest('.nested-fields')

    $selects = $fields.find(".atom-model-select:not(.disabled[data-class='#{klass}'])")
    $selects.addClass('disabled').prop('disabled', true)
    $selects.parent().addClass('disabled')
    $selects.parent().hide()

    $selects = $fields.find(".atom-model-select.disabled[data-class='#{klass}']")
    $selects.removeClass('disabled').prop('disabled', false)
    $selects.parent().removeClass('disabled')
    $selects.parent().show()

    $content = $fields.find('.atom-content')
    switch form
      when 'redactor'
        $content.show()
        $textarea = $content.find('textarea')
        # check if redactor is active
        if $textarea.is(':visible')
          $textarea.redactor()
      when 'string'
        $content.show()
        $textarea = $content.find('textarea')
        unless $textarea.is(':visible')
          $textarea.redactor('core.destroy')
      when 'none'
        $content.hide()

  $(document).on 'cocoon:after-insert', (e, insertedItem) ->
    selectRightForm($(insertedItem).find('select.atom-type-select'))

  $(document).on 'change', '.atom-type-select', ->
    selectRightForm(this)

  $(document).on 'change', '.atom-model-select', ->
    $t = $(this)
    $textarea = $t.closest('.nested-fields').find('textarea')
    $textarea.redactor('code.set', $t.find(':selected').data('content'))

  $('#paginate-images a').on 'ajax:success', (e, data, status, json) ->
    # pagination
    $t = $(this)
    $li = $t.parent()
    $ul = $li.parent()

    # pagination
    $ul.find('li.active').removeClass('active')
    $li.addClass('active')

    page = $li.data('page')
    total_pages = $ul.find('li:not(.disabled)').length
    setPagination($li, page, total_pages)

    # change images
    $t.closest('.modal-body').find('.row > .col-image')
      .each (index) ->
        $template = $(this)
        image = data[index]
        if image
          $template.find('a.card.select-file')
            .data('file-id', image.id)
            .data('file-filesize', image.file_size)
            .data('file-size', image.size)
            .removeClass('active')
          $template.find('img')
            .attr('src', image.thumb)
          $template.removeClass('hidden')
        else
          $template.addClass('hidden')


  $('#paginate-documents a').on 'ajax:success', (e, data, status, json) ->
    # pagination
    $t = $(this)
    $li = $t.parent()
    $ul = $li.parent()

    # pagination
    $ul.find('li.active').removeClass('active')
    $li.addClass('active')

    page = $li.data('page')
    total_pages = $ul.find('li:not(.disabled)').length
    setPagination($li, page, total_pages)

    $t.closest('.modal-body').find('tr.select-file:not(.template)')
      .each (index) ->
        $template = $(this)
        doc = data[index]
        if doc
          $template
            .data('file-id', doc.id)
            .data('file-filesize', doc.file_size)
          $template.find("[name='file_size']").html(doc.file_size)
          $template.find("[name='file_name']").html(doc.file_name)
          $template.removeClass('hidden active')
        else
          $template.addClass('hidden')

  $(document).on 'click', '.select-file', ->
    $image = $(this)
    if $image.hasClass('active')
      $image.removeClass('active')
    else
      $image.addClass('active')

  $(document).on 'click', '.save-modal', ->
    $modal = $(this).closest('.modal')
    $target = $($modal.data('target'))
    $modal.find('.select-file.active').each () ->
      $file = $(this)
      $copy = $target.find('.file-placement-new').clone()
      index_counter = Date.now()
      $last = $target.children('.nested-fields:not(.file-placement-new)').last()
      if $last.length
        position = Number($last.find('input.position').val()) + 1
      else
        position = 0

      $copy.removeClass('file-placement-new').removeAttr('id hidden')
      $copy.find('img').attr('src', $file.find('img').attr('src'))
      $copy.find('input').each () ->
        $input = $(this)
        $input.prop('disabled', false)
        $input.attr('id', $input.attr('id')
          .replace(/__i__/, "#{index_counter}"))
        $input.attr('name', $input.attr('name')
          .replace(/{{i}}/, "#{index_counter}"))
        if $input.attr('type') == 'hidden'
          if $input.hasClass('position')
            $input.val(position)
          else
            $input.val($file.data('file-id'))
      $copy.find("[name='file_name']").html($file.data('file-filename'))
      $copy.find("[name='file_size']").html($file.data('file-filesize'))
      $copy.find("[name='size']").html($file.data('file-size'))
      if $last.length
        $last.after($copy)
      else
        $copy.prependTo($target)

      # FIXME
      $target.find('.remove-after').hide()

  $(document).on 'show.bs.modal', '#images-modal', (event) ->
    $button = $(event.relatedTarget)
    $(this).data('target', $button.closest('.row'))

  $(document).on 'hidden.bs.modal', '.modal', (event) ->
    $(this).closest('.modal').find('.select-file.active').removeClass('active')

  $(document).on 'click', '.remove', (event) ->
    event.preventDefault()
    $(this).closest('.nested-fields').nextAll('.remove-after:first').show()
    $(this).closest('.nested-fields').remove()

  $(document).on 'click', '.btn.destroy', (event) ->
    event.preventDefault()
    $button = $(this)
    $button.find('input[type="hidden"]:first').val(1)
    $button.closest('.nested-fields').fadeOut(500)

  $(document).on 'click', '.btn.destroy-image', (e) ->
    e.preventDefault()
    $button = $(this)
    $button.find('input[type="hidden"]').filter(->
      $(this).attr('name').indexOf('_destroy') isnt -1
    ).val(1)
    $button.closest('.nested-fields').fadeOut(500)
    $parent = $button.closest('.nested-fields')
    $parent.fadeOut(500, ->
      $parent.nextAll('.remove-after:first').show(500)
    )

  $(document).on 'click', '.btn.image.position-up', ->
    $this_image = $(this).closest('.nested-fields')
    $that_image = $this_image.prevAll('.nested-fields:first')

    this_pos = $this_image.find('.position').val()
    that_pos = $that_image.find('.position').val()
    $that_image.find('.position').val(this_pos)
    $this_image.find('.position').val(that_pos)
    $this_image.after($that_image)

  $(document).on 'click', '.btn.image.position-down', ->
    $this_image = $(this).closest('.nested-fields')
    $that_image = $this_image.nextAll(".nested-fields:first")

    that_pos = $that_image.find('.position').val()
    this_pos = $this_image.find('.position').val()
    $this_image.find('.position').val(that_pos)
    $that_image.find('.position').val(this_pos)
    $that_image.after($this_image)
