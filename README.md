# Folio

A collection of Ruby on Rails mixins and generators, an administration framework. Contains some basic models so that you don't have to make them for every website you create. Consists mostly of:

+ `Folio::Page` model for individual web pages, consisting of content parts called `Folio::Atom`
+ Administration in `/console` for administrators with a simple generator to add custom models.
+ User management for `Folio::User` model, roles defined for each site by `Folio::SiteUserLink` instances.

Folio uses [Trailblazer cells](https://github.com/trailblazer/cells) with [Slim](http://slim-lang.com/) templates, [MessageBus](https://github.com/discourse/message_bus) for WebSockets-like messaging, Sidekiq and PostgreSQL.

## Usage
Run `bundle exec rails app:folio:prepare_dummy_app`.

## Installation
Add this lines to your application's Gemfile:

```ruby
gem 'folio', github: 'sinfin/folio'
gem "dragonfly_libvips", github: "sinfin/dragonfly_libvips", branch: "more_geometry"
gem "view_component"
```

And then execute:
```bash
$ bundle
```

Run:
```bash
$ rails generate folio:install
```
which will copy bunch of things into your, hopefully clean, app.
Make some cleaning in `Gemfile` as generator will add  gems there.

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

Due usage of `dragonfly_libvips` gem from on-fly processing images, You need to have installed `libvips`, `jpegtran`, `jpgicc`,`exiftool`, `cwebp` and `gifsicle` on your system.

To run tests successfully, you need to have installed `ffmpeg` on your system.

## `Folio::Current` singleton

We use `Current` per request singleton to store few interesting data (`.site` , `.user` ...).
Using `current_user` and `current_site` is now deprecated.
If you app needs add something to `Folio::Current` use `Folio::Current.class_eval do ` in override.
If your `ApplicationController` do not include `Folio::ApplicationControllerBase` you have to fill data for yourself (or include at least `Folio::SetCurrentRequestDetails`).


## Attachments

### Image metadata module

If you want to analyse and store all Exif & IPTC data from uploaded Image files
you have to install ExifTool (https://www.sno.phy.queensu.ca/~phil/exiftool/index.html).

Ubuntu: `sudo apt install exiftool`
MacOS: `brew install exiftool`

Every uploaded file will be processed and all the metadata will be saved
to the `Folio::File::Image.file_metadata` field.

For a manual analysis of a file call `Dragonfly.app.fetch(Folio::File::Image.last.file_uid).metadata`
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

## Abilities
What can user do now with object is defined by two things, what is allowed to him/her by ability and what are `currently_available_actions` of object.
In `Folio::Ability` there are rules what user (mainly based by roles in SiteUserLink) is allowed to do. You can extend these rules by overriding
`Folio::Ability#ability_rules` to include methods with app specific rules. Eg.

```ruby
Folio::Ability.class_eval do
  def ability_rules
    if user.superadmin?
      can :do_anything, :all
    end

    folio_console_rules
    sidekiq_rules
    app_rules
  end
end
```
You can use `user` (current user) and `site` (current site) in your rules.

Then You can define `object.currently_available_actions(user)` on your objects. If You don't, it will pretend than any action is available now.
Finally **use method `can_now?(:action, object)`** to check permissions.
There is also handy methods `user.can_now?(action, subject = nil, site: nil)` and `user.currently_allowed_actions_with(subject, ability_class = nil)`.


## Tips and Tricks
- Check [Wiki](https://github.com/sinfin/folio/wiki)

- If  class responds to `:console_sidebar_count` , such number is displayed in Folio console sidebar
- If aasm event have option `confirm`, confirmation alert is displayed in change (in Foio console). You can pass `true` (defaults to `t("folio.console.confirmation")`) or string ` event :pay, confirm: "Do You really want to pay this" do ... end`

- Some Oauth providers (eg. apple) requires HTTPS for callback. Set `dev.dummy.cz` to `127.0.0.1` (`/etc/hosts`) and start `test/dummy`app as in ssl mode by
  `rails s -b 'ssl://dev.dummy.cz:3000?key=./certificates/dev.dummy.cz.key&cert=./certificates/dev.dummy.cz.crt'. And set callbacks to `https://dev.dummy.cz:3000/users/auth/apple/callback`

- Including `Folio::Audited` in model requires also setting routes in console
  ```
    scope module: :folio do
      namespace :console do
        resources :x do
          member do
            get :revision, path: "revision/:version"
            post :restore, path: "restore/:version"
          end
        end
      end
    end
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
