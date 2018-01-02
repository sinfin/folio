$ ->
  changeBoolIcon = (element, attribute, bool) ->
    $e = $(element)
    $input = $e.find("input[data-attribute='#{attribute}']")
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
        # if bool && attribute == 'published'
        #   $published_at_row = $e.closest('td')
        #     .nextAll("td:first.published_at")
        #   if $published_at_row
        #     now = new Date()
        #     $published_at_row.html("#{now.getDate()}/#{now.getMonth() + 1}/#{now.getFullYear()}")


  $("form.published").on("ajax:success", (e, data) ->
    changeBoolIcon this, 'published'
  )

  $("form.featured").on("ajax:success", (e, data) ->
    changeBoolIcon this, 'featured'
  )
