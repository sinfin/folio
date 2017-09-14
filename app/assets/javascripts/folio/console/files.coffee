$ ->
  # grap our upload form by its id
  $('#new_file').dropzone
    maxFilesize: 10 # MB
    paramName: 'file[file]'
