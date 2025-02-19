// converted via https://coffeescript.org/#try
$(document).on('single-nested-change', '[data-cocoon-single-nested]', function(e) {
  var $fields, $this;
  $this = $(this);
  $fields = $this.find('.nested-fields').not('[hidden]');
  return $this.toggleClass('folio-console-has-nested', $fields.length > 0);
});
