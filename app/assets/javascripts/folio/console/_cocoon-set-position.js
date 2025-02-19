// converted via https://coffeescript.org/#try

(function () {
var INPUT_SELECTOR;

INPUT_SELECTOR = '.position, .folio-console-nested-model-position-input';

$(document).on('cocoon:after-insert', function(e, insertedItem) {
  var $input, $item, pos;
  $item = $(insertedItem);
  $input = $(insertedItem).find(INPUT_SELECTOR);
  if (!$input.length) {
    return;
  }
  pos = $item.prevAll('.nested-fields:first').find(INPUT_SELECTOR).val();
  return $input.val((parseInt(pos) || 0) + 1);
});
})()
