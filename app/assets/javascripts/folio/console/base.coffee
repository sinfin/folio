#= require jquery
#= require jquery_ujs
#= require bootstrap-sprockets
#= require dropzone

$ ->

  $(document).on 'change', '#filter-form', ->
    $(this).submit()
    
  $(document).on 'click', '.selectImage', ->
    $image = $(this)
    if $image.hasClass('active')
      $image.removeClass('active')
    else
      $image.addClass('active')
  
  index_counter = undefined
  
  $(document).on 'click', '#saveModal', ->
    $modal = $(this).closest('.modal')
    $modal.find('.selectImage.active').each () ->
      $image = $(this)
      $copy = $('#file-placement-new').clone()
      index_counter = index_counter || $copy.data('fp-index')
      
      $copy.removeClass('hidden').removeAttr('id')
      $copy.find('img').attr('src', $image.find('img').attr('src'))
      $copy.find('input').each () ->
        $input = $(this)
        $input.prop('disabled', false)
        $input.attr('id', $input.attr('id').replace(/_[0-9]+_/, "_#{index_counter}_"))
        $input.attr('name', $input.attr('name').replace(/\[[0-9]+\]/, "[#{index_counter}]"))
        $input.val($image.data('file-id')) if $input.attr('type') == 'hidden'
      
      $copy.appendTo('#file_placements')
      index_counter++
  
  $(document).on 'hidden.bs.modal', '#filesModal', (event) ->
    $(this).closest('.modal').find('.selectImage.active').removeClass('active')
      
  $(document).on 'click', '#removeFile', ->
    $(this).closest('.nestedField').remove()
    index_counter--
    
  # disable auto discover
  Dropzone.autoDiscover = false
  # grap our upload form by its id
  dropzone = $('#new_file').dropzone
    maxFilesize: 1
    paramName: 'file[file]'        
