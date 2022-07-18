# Folio

A collection of Ruby on Rails mixins and generators, an administration framework. Contains some basic models so that you don't have to make them for every website you create. Consists mostly of:

+ `Folio::Page` model for individual web pages, consisting of content parts called `Folio::Atom`
+ Administration in `/console` for `Folio::Account` administrators with a simple generator to add custom models.

Folio uses [Trailblazer cells](https://github.com/trailblazer/cells) with [Slim](http://slim-lang.com/) templates, [MessageBus](https://github.com/discourse/message_bus) for WebSockets-like messaging, Sidekiq and PostgreSQL.

## Usage
Run `bundle exec rails app:folio:prepare_dummy_app`.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'folio', github: 'sinfin/folio'
```

And then execute:
```bash
$ bundle
```

Run:
```bash
$ rails generate folio:install
```
which will copy bunch of things into your, hopefully clean, app

Then run migrations
```bash
$ rails db:migrate
```

Then You can seed some pages and sites
```bash
$ rails db:seed
```

Folio is build on philosophy "You can have it, if You want, but it is not required."
So for example, You can build CMS pages bysed on Atoms, but they are not added  during installation of gem. You have to add them for Yourself (see Github Wiki).
Take a look to, not only Folio, handy generators by
```bash
$ rails g
```

Due usage of `dragonfly_libvips` gem from onfly processing images, You need to have installed `libvips` and `gifsicle` on your system.

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
Then add correct routes to `config/routes`
```
scope module: :folio do
  namespace :console do
    ...
    resources :model_names
    ...
  end
end
```
and update Folio console config (`config/initializers/folio.rb`) to see this `ModelName` in console menu
```
Rails.application.config.folio_console_sidebar_link_class_names = [
  %w[
    ...
    ModelName
  ],
  %w[...]
  ....
```

## Tips and Tricks
- Check [Wiki](https://github.com/sinfin/folio/wiki)

- If  class responds to `:console_sidebar_count` , such number is displayed in Folio console sidebar
- If aasm event have option `confirm`, confirmation alert is displayed in change (in Foio console). You can pass `true` (defaults to `t("folio.console.confirmation")`) or string ` event :pay, confirm: "Do You really want to pay this" do ... end`

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
