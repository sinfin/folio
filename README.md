# Folio
Short description and motivation.

## Usage
Copy `redactor.js` and `redactor.css` to `test/dummy/vendor/assets/redactor`.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'folio'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ rails generate folio:install
```

## Attachments

### Image metadata module

If you want to analyse and store all Exif & IPTC data from uploaded Image files
you have to install ExifTool (https://www.sno.phy.queensu.ca/~phil/exiftool/index.html).

Ubuntu: `sudo apt install exiftool`
MacOS: `brew install exiftool`

Every uploaded file will be processed and all the metadata will be saved
to the `Folio::Image.file_metadata` field.

For a manual analysis of a file call `Dragonfly.app.fetch(Folio::Image.last.file_uid).metadata`
or `rake folio:file:metadata` for batch processing of already downloaded but not
 processed files.

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
