$ ->
  changeBoolIcon = (element, attribute, bool) ->
    $e = $(element)
    $input = $e.find("input[name='node[#{attribute}]']")
    bool = $input.val() == 'true'
    $input.val(!bool)
    $icon = $e.find('.btn[type="submit"] i.fa')

    if attribute == 'featured'
      $icon
        .removeClass('fa-star fa-star-o')
        .addClass( if bool then 'fa-star' else 'fa-star-o')
    else
      $icon
        .removeClass('fa-toggle-on fa-toggle-off')
        .addClass( if bool then 'fa-toggle-on' else 'fa-toggle-off')
        if attribute == 'published'
          now = new Date()
          $e.closest('td')
            .nextAll("td:first")
            .html("#{now.getDate()}/#{now.getMonth() + 1}/#{now.getFullYear()}")


  $("form.published").on("ajax:success", (e, data) ->
    changeBoolIcon this, 'published'
  )

  $("form.featured").on("ajax:success", (e, data) ->
    changeBoolIcon this, 'featured'
  )
