$('.simple_form')
  .filter(-> @className.match(/(new_|edit_)/))
  .dirty
    preventLeaving: true
