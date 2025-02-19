// converted via https://coffeescript.org/#try
$(function() {
  $('.f-c-new-record-modal').each(function() {
    var $modal, loadForm, submitForm;
    $modal = $(this);
    loadForm = function(e, opts = {}) {
      $modal.addClass('f-c-new-record-modal--loading');
      return $.ajax({
        method: opts.method || 'GET',
        url: opts.url || $modal.data('new-url'),
        data: opts.data,
        success: function(res) {
          var $form, $formControl, $group, $res, $toggle, option, selector;
          if (opts.create && res.id) {
            $toggle = $('.f-c-new-record-modal__toggle--active');
            $group = $toggle.prev('.form-group');
            selector = `.${$group.prop('className').replace(/ /g, '.')}`;
            option = new Option(res.label, res.id);
            $(selector).find('.form-control, .selectized').each(function() {
              var $formControl;
              $formControl = $(this);
              $formControl.append(option);
              if ($formControl[0].selectize) {
                return $formControl[0].selectize.addOption({
                  text: res.label,
                  id: res.id,
                  value: res.id
                });
              }
            });
            $formControl = $group.find('.form-control, .selectized');
            if ($formControl[0].selectize) {
              $formControl[0].selectize.setValue(res.id, true);
            }
            $formControl.val(res.id);
            $toggle.removeClass('f-c-new-record-modal__toggle--active');
            return $modal.modal('hide');
          } else {
            $res = $($.parseHTML(res));
            $form = $res.filter('.f-c-layout-main').find('.simple_form').first();
            $form.find('.f-c-form-header__inner, .f-c-form-footer').remove();
            return $modal.find('.modal-body').trigger('cocoon:before-remove', [$modal.find('.simple_form'), e]).html($form).trigger('cocoon:after-insert', [$form, e]);
          }
        },
        error: function(jxHr) {
          $modal.modal('hide');
          return alert(`${jxHr.status}: ${jxHr.statusText}`);
        },
        complete: function() {
          return $modal.removeClass('f-c-new-record-modal--loading');
        }
      });
    };
    submitForm = function(e) {
      e.preventDefault();
      return loadForm(e, {
        url: $modal.data('create-url'),
        method: 'POST',
        data: `${$modal.find('.simple_form').serialize()}&created_from_modal=1`,
        originalEvent: e,
        create: true
      });
    };
    return $modal.on('show.bs.modal', loadForm).on('submit', '.simple_form', submitForm).on('click', '.f-c-new-record-modal__submit', submitForm);
  });
  return $(document).on('click', '.f-c-new-record-modal__toggle', function(e) {
    var $toggle;
    e.preventDefault();
    $toggle = $(this);
    $toggle.addClass('f-c-new-record-modal__toggle--active');
    return $($toggle.data('target')).modal({
      show: true
    });
  });
});
