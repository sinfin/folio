$ ->
  changeBoolIcon = (element, attribute, bool) ->
    $e = $(element)
    $input = $e.find("input[name='node[#{attribute}]']")
    bool = $input.val() == 'true'
    $input.val(!bool)
    $icon = $e.find('.btn[type="submit"] i.fa')

    if attribute == 'featured'
      console.log $icon
      $icon
        .removeClass('fa-star fa-star-o')
        .addClass( if bool then 'fa-star' else 'fa-star-o')
    else
      $icon
        .removeClass('fa-toggle-on fa-toggle-off')
        .addClass( if bool then 'fa-toggle-on' else 'fa-toggle-off')

  $("form.published").on("ajax:success", (e, data) ->
    changeBoolIcon this, 'published'
  )

  $("form.featured").on("ajax:success", (e, data) ->
    changeBoolIcon this, 'featured'
  )
