# Přehled Rails enginu Folio

Tento projekt poskytuje sadu mixinů, generátorů a administrační rozhraní pro aplikace na Ruby on Rails. Následující informace slouží jako rychlý úvod pro nové vývojáře.

## Základní funkce
- `Folio::Page` pro webové stránky skládající se z atomů (`Folio::Atom`)
- Administrace dostupná na `/console` s generátory pro vlastní modely
- Správa uživatelů prostřednictvím `Folio::User` a vazeb `Folio::SiteUserLink`
- Engine původně využíval [Trailblazer Cells](https://github.com/trailblazer/cells) se šablonami [Slim](http://slim-lang.com/),
  které jsou postupně nahrazovány komponentami [ViewComponent](https://github.com/github/view_component).
  Pro zprávy v reálném čase se používá [MessageBus](https://github.com/discourse/message_bus), dále Sidekiq a PostgreSQL.

(zdroj: README.md)

## Instalace
1. Do `Gemfile` přidejte závislosti a spusťte `bundle`:
   ```ruby
   gem 'folio', github: 'sinfin/folio'
   gem 'dragonfly_libvips', github: 'sinfin/dragonfly_libvips', branch: 'more_geometry'
   gem 'view_component'
   ```
2. Spusťte generátor enginu a migrace:
   ```bash
   rails generate folio:install
   rails db:migrate
   ```
3. Volitelně můžete nahrát základní data:
   ```bash
   rails db:seed
   ```

(zdroj: README.md)

Pro správnou funkci je nutné mít v systému nainstalovány nástroje `libvips`, `jpegtran`, `jpgicc`, `exiftool`, `cwebp` a `gifsicle`. Pro běh testů je potřeba také `ffmpeg`.

## Struktura projektu
- `app/models` – modely enginu (např. `Folio::Site`, `Folio::Page`, `Folio::User`)
- `app/controllers` – kontrolery včetně administrační sekce `/console`
- `app/components` – komponenty postavené na [ViewComponent](https://github.com/github/view_component)
- `app/cells` – starší komponenty založené na [Trailblazer Cells](https://github.com/trailblazer/cells) (postupně se odstraňují)
- `app/overrides` – místo pro úpravy a rozšíření tříd enginu. Rails je načítá při startu aplikace (viz `config/application.rb` v dummy aplikaci)
- `lib/generators` – generátory usnadňující vytvoření komponent, atomů nebo celé administrace
- `lib/tasks` – rake úlohy pro údržbu (např. doplnění metadat souborů nebo nástroje pro vývojáře)

### Ukázka konfigurace (viz `test/dummy/config/application.rb`)
```ruby
config.folio_leads_from_component_class_name = "Folio::Leads::FormComponent"
config.folio_newsletter_subscriptions = true
config.folio_site_default_test_factory = :dummy_site
```


## Doporučené postupy
- Využívejte `Folio::Current` pro data platná pouze pro jedno request– např. `site` nebo `user`.
- Práva uživatelů nastavujte v `Folio::Ability` (možno rozšířit pomocí `#ability_rules`). K ověření použijte metodu `can_now?`.
- Vlastní kód enginu nepřepisujte, místo toho použijte soubory v `app/overrides`.
- Nové části administračního rozhraní lze snadno scaffoldovat pomocí `rails generate folio:console:scaffold ModelName` a následnou úpravou `config/initializers/folio.rb`.
- Pro generování nových komponent slouží další generátory v adresáři `lib/generators`.

### Generátor konzolového rozhraní

```bash
$ rails generate folio:console:scaffold Article
```

Poté přidejte do `config/routes.rb` odpovídající zdroje a model zveřejněte v postranním menu
v `config/initializers/folio.rb` pomocí `Rails.application.config.folio_console_sidebar_link_class_names`.

### Příklad rozšíření oprávnění

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

Nad objektech lze definovat metodu `currently_available_actions(user)` a oprávnění pak ověřovat přes `can_now?(:action, objekt)`.

## Uživatelská administrace
Administrace je dostupná na `/console`. Odkazy v postranním menu lze ovlivnit pomocí nastavení `Rails.application.config.folio_console_sidebar_link_class_names`. V administraci jsou připravené CRUD operace pro většinu modelů, součástí je i práce se soubory (`Folio::File`), správou stránek (`Folio::Page`) a nastavením webu (`Folio::Site`).

## Přílohy a metadata
Pokud chcete analyzovat a ukládat metadata obrázků, nainstalujte na systém `exiftool` a spusťte
`rake folio:file:metadata` pro dávkové zpracování. Metadata jsou ukládána do pole `Folio::File::Image.file_metadata`.

## Rake úlohy
Engine dodává několik pomocných úloh:
- `rake folio:developer_tools:idp_fill_up_site_to_folio_records` – doplní chybějící `site_id`
- `rake folio:developer_tools:idp_split_users_to_sites` – rozdělí uživatele při přechodu z cross-domain režimu
- `rake folio:file:fill_missing_metadata` – dopočítá metadata k souborům
- `rake folio:session_attachments:clear_unpaired` – smaže nevyužité dočasné přílohy

## Další zdroje
- Projekt obsahuje složku `test/dummy`, která slouží jako demonstrační aplikace.
- Podrobnější návody a specifické postupy je možné najít na [Wiki projektu](https://github.com/sinfin/folio/wiki).
