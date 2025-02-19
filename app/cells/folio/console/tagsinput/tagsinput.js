// converted via https://coffeescript.org/#try

(function () {
var dispose, init, makeItems, optionMapper;

optionMapper = function(str) {
  return {
    value: str
  };
};

makeItems = function(string) {
  if (string) {
    return string.split(', ').map(optionMapper);
  } else {
    return [];
  }
};

init = function() {
  var $inputs;
  $inputs = $('.f-c-tagsinput');
  if ($inputs.length === 0) {
    return;
  }
  return $inputs.each(function() {
    var $formGroup, $selectize, createOption;
    $selectize = $(this);
    $formGroup = $selectize.closest('.form-group');
    if ($formGroup.data('allow-create')) {
      createOption = optionMapper;
    } else {
      createOption = false;
    }
    return $selectize.selectize({
      dropdownParent: 'body',
      labelField: 'value',
      searchField: 'value',
      delimiter: ', ',
      plugins: ['remove_button'],
      create: createOption,
      createFilter: function(val) {
        var valid;
        if (this.items.indexOf(val) !== -1) {
          return false;
        }
        valid = true;
        this.currentResults.items.forEach(function(item) {
          return valid = valid && item.id !== val;
        });
        return valid;
      },
      maxOptions: 50000,
      preload: 'focus',
      onChange: function(_value) {
        return $selectize.trigger('change')[0].dispatchEvent(new window.Event('change', {
          bubbles: true
        }));
      },
      load: function(q, callback) {
        return $.ajax({
          url: '/console/api/tags/react_select',
          method: 'GET',
          data: {
            q: q,
            context: $selectize.data('context')
          },
          error: function() {
            return callback();
          },
          success: function(res) {
            return callback(res.data.map(optionMapper));
          }
        });
      },
      render: {
        option_create: function(data, escape) {
          return `<div class="create">
  ${window.FolioConsole.translations.add}
  <strong>${escape(data.input)}</strong>&hellip;
</div>`;
        }
      }
    });
  });
};

dispose = function() {
  return $('.f-c-tagsinput').each(function() {
    var ref;
    return (ref = this.selectize) != null ? ref.destroy() : void 0;
  });
};

if (typeof Turbolinks !== "undefined" && Turbolinks !== null) {
  $(document).on('turbolinks:load', init).on('turbolinks:before-cache', dispose);
} else {
  $(init);
}
})()
