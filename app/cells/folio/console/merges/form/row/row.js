// converted via https://coffeescript.org/#try

(function () {
$(function() {
  var $cols;
  $cols = $('.f-c-merges-form-row__col');
  if ($cols.length === 0) {
    return;
  }
  return $cols.on('click', function() {
    var $col;
    $col = $(this);
    return $col.find('.f-c-merges-form-row__radio').prop('checked', true);
  });
});

// $group = $col.find('.form-group')
// $group.removeClass('disabled')
// $group.find('.disabled').removeClass('disabled')
// $group.find('.form-control').prop('disabled', false)

// $sibling = $col.siblings('.f-c-merges-form-row__col')
// $siblingGroup = $sibling.find('.form-group')
// $siblingGroup.addClass('disabled')
// $siblingGroup.find('label, .form-control').addClass('disabled')
// $siblingGroup.find('.form-control').prop('disabled', true)
})()
