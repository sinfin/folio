# Folio
Short description and motivation.

## Usage
Copy `redactor.js` and `redactor.css` to `test/dummy/vendor/assets/redactor`. 

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'folio', github: 'sinfin/folio'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ rails generate folio:install
```

## Scaffolding

Easily scaffold console controller and views for existing models.

```bash
$ rails generate folio:console:scaffold ModelName
```

## Contributing

Clone & setup

```
git clone git@github.com:sinfin/folio.git
cd folio
bundle install
bin/rails db:setup
```

Run

```
bin/rails s
```

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
