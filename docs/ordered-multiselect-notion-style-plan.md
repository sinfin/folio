# Implementační plán: Notion-style inline CRUD pro ordered multiselect

## Co už existuje (branch `vd/ordered-multiselect-createable`)

| Soubor | Co tam je |
|--------|-----------|
| `Select/index.js` | `AsyncCreatableSelect` pro `createable + async`, formátování options |
| `OrderedMultiselectApp/index.js` | `onCreateOption` → `apiPost(createUrl, { label })` → `onSelect(res.data)` |
| `ducks/orderedMultiselect.js` | `createable`, `createUrl` v initialState |
| `index.js` (init) | Parsování `data-createable`, `data-create-url` z DOM |
| `react_helper.rb` | `createable: false` kwarg, generuje `data-createable` + `data-create-url` |
| `autocompletes_controller.rb` | `react_select_create` akce (POST) |
| `routes.rb` | `post :react_select_create` |
| `formatCreateLabel.js` | `Vytvořit "text"` label |

**Co funguje**: Vytváření nových záznamů inline.
**Co chybí**: Vizuální odlišení "Vytvořit", rename, delete z DB, varování.

---

## Kroky implementace

### Krok 1: Custom Option komponenta — vizuální odlišení Create + tříbodové menu

**Nový soubor**: `react/src/components/Select/OptionWithActions.js`

Jedna komponenta pokrývá oba případy:
- `data.__isNew__` → zelený ＋ prefix, oddělovač
- Existující položky → label + ⋮ ikona vpravo

**Úprava**: `react/src/components/Select/index.js`
- Importovat `OptionWithActions`
- Když `createable`, předat `components={{ Option: OptionWithActions, Input }}` místo `components={{ Input }}`
- Předat `onRenameOption` a `onDeleteOption` jako custom props na `SelectComponent` (react-select je propaguje do custom Option přes `selectProps`)

**Žádný mrtvý kód**: `formatCreateLabel.js` zůstane — nadále generuje text "Vytvořit X", `OptionWithActions` jen přidá ikonu a styl kolem něj.

---

### Krok 2: Rename handler v OrderedMultiselectApp

**Úprava**: `react/src/containers/OrderedMultiselectApp/index.js`
- Nová metoda `onRenameOption(option, newLabel)`:
  ```
  apiPatch(orderedMultiselect.updateUrl, { id: option.id, label: newLabel })
    → po úspěchu: dispatch(renameItem(option.id, newLabel))
    → force refresh Select options (key change)
  ```
- Předat `onRenameOption` do `<Select>` jako prop

**Úprava**: `react/src/ducks/orderedMultiselect.js`
- Nová akce `RENAME_ITEM` — najde item podle `value` (== id) a aktualizuje `label`
- Nové properties v initialState: `updateUrl: null`, `deleteUrl: null`

**Úprava**: `react/src/index.js`
- Parsovat nové data atributy: `updateUrl`, `deleteUrl`

---

### Krok 3: Delete handler v OrderedMultiselectApp

**Úprava**: `react/src/containers/OrderedMultiselectApp/index.js`
- Nová metoda `onDeleteOption(option)`:
  ```
  apiDelete(orderedMultiselect.deleteUrl, { id: option.id })
    → vrátí { usage_count, confirm_required }
    → pokud confirm_required: window.confirm("Přiřazena ke N plánům...")
    → po potvrzení: apiDelete(..., { id, confirmed: true })
    → dispatch(removeDeletedItem(option.id))  // odstraní z items i removedItems
    → force refresh Select options (key change)
  ```

**Úprava**: `react/src/ducks/orderedMultiselect.js`
- Nová akce `REMOVE_DELETED_ITEM` — odstraní z `items` (pokud tam je) I z dropdown options cache
- Existující `REMOVE_ITEM` zůstává — ten odebírá z plánu (přesouvá do removedItems)

---

### Krok 4: Backend — nové API endpointy

**Úprava**: `app/controllers/folio/console/api/autocompletes_controller.rb`

Nová akce `react_select_update`:
```ruby
def react_select_update
  klass = params.require(:class_name).safe_constantize
  return render json: { error: "Invalid class" }, status: :unprocessable_entity unless klass&.<(ActiveRecord::Base)

  record = klass.find(params.require(:id))
  authorize!(:update, record)
  record.title = params.require(:label)

  if record.save
    render json: {
      data: {
        id: record.id,
        text: record.to_console_label,
        label: record.to_console_label,
        value: Folio::Console::StiHelper.sti_record_to_select_value(record),
        type: record.class.to_s,
      }
    }
  else
    render json: { error: record.errors.full_messages.join(", ") }, status: :unprocessable_entity
  end
end
```

Nová akce `react_select_destroy`:
```ruby
def react_select_destroy
  klass = params.require(:class_name).safe_constantize
  return render json: { error: "Invalid class" }, status: :unprocessable_entity unless klass&.<(ActiveRecord::Base)

  record = klass.find(params.require(:id))
  authorize!(:destroy, record)

  usage_count = if record.respond_to?(:usage_count_for_warning)
    record.usage_count_for_warning
  else
    0
  end

  if params[:confirmed] == "true"
    record.destroy!
    render json: { data: { id: record.id, destroyed: true } }
  else
    render json: {
      data: {
        id: record.id,
        usage_count: usage_count,
        confirm_required: usage_count > 0
      }
    }
  end
end
```

**Úprava**: `config/routes.rb`
```ruby
resource :autocomplete, only: %i[show] do
  get :field
  get :selectize
  get :select2
  get :react_select
  post :react_select_create     # existuje
  patch :react_select_update    # nové
  delete :react_select_destroy  # nové
end
```

---

### Krok 5: Rails helper — nové data atributy

**Úprava**: `app/helpers/folio/console/react_helper.rb`

V `react_ordered_multiselect`:
```ruby
update_url = if createable
  Folio::Engine.routes.url_helpers.url_for([
    :react_select_update, :console, :api, :autocomplete,
    { class_name: through_klass.to_s, only_path: true }
  ])
end

delete_url = if createable
  Folio::Engine.routes.url_helpers.url_for([
    :react_select_destroy, :console, :api, :autocomplete,
    { class_name: through_klass.to_s, only_path: true }
  ])
end
```

Přidat do content_tag:
```ruby
"data-update-url" => update_url,
"data-delete-url" => delete_url,
```

---

### Krok 6: Styly

**Úprava**: `app/assets/stylesheets/folio/console/modules/react/_ordered_multiselect_app.sass`

Přidat styly pro:
- `.f-c-r-select-option-with-actions` — flex layout, label + dots
- `.f-c-r-select-option-with-actions__dots` — opacity 0.4, hover 1
- `.f-c-r-select-option-with-actions__menu` — absolutní sub-menu
- `.f-c-r-select-option-with-actions__menu-item` — řádky menu
- `.f-c-r-select-option-rename` — inline input
- `.f-c-r-select-create-option` — zelený ＋ styl

---

### Krok 7: Překlad

**Úprava**: `config/locales/console.cs.yml` a `console.en.yml`

```yaml
folio:
  console:
    react:
      rename: "Přejmenovat"
      delete_from_db: "Smazat"
      delete_warning_one: "Tato položka je přiřazena k 1 dalšímu záznamu. Smazáním ji odeberete i z něj. Pokračovat?"
      delete_warning_other: "Tato položka je přiřazena ke %{count} dalším záznamům. Smazáním ji odeberete i z nich. Pokračovat?"
```

Přidat do JS translations v inicializaci konzole.

---

### Krok 8: Build + test

1. `cd react && npm run build`
2. Otestovat v Boutique (branch s `createable: true` na subscription plans)
3. Zkontrolovat:
   - [ ] Create: ＋ ikona, zelená barva, oddělovač
   - [ ] Dropdown: ⋮ u každé existující položky
   - [ ] Rename: klik ⋮ → Přejmenovat → inline input → Enter uloží
   - [ ] Delete: klik ⋮ → Smazat → varování s počtem → potvrzení smaže
   - [ ] Keyboard: Escape zavře rename, Enter uloží
   - [ ] Klik na ⋮ nezavře dropdown a nezvolí položku
   - [ ] Po rename se aktualizuje label v přiřazených items
   - [ ] Po delete z DB zmizí z dropdownu i z přiřazených items

---

## Soubory — kompletní přehled

### Nové (1)
| Soubor | Popis |
|--------|-------|
| `react/src/components/Select/OptionWithActions.js` | Custom Option: create styl + ⋮ menu + rename + delete |

### Upravené (9)
| Soubor | Co se mění |
|--------|-----------|
| `react/src/components/Select/index.js` | Předat `OptionWithActions` jako custom Option když `createable` |
| `react/src/containers/OrderedMultiselectApp/index.js` | `onRenameOption`, `onDeleteOption` handlery |
| `react/src/ducks/orderedMultiselect.js` | `RENAME_ITEM`, `REMOVE_DELETED_ITEM`, `updateUrl`, `deleteUrl` |
| `react/src/index.js` | Parsovat `updateUrl`, `deleteUrl` |
| `app/controllers/folio/console/api/autocompletes_controller.rb` | `react_select_update`, `react_select_destroy` |
| `app/helpers/folio/console/react_helper.rb` | `data-update-url`, `data-delete-url` |
| `config/routes.rb` | `patch :react_select_update`, `delete :react_select_destroy` |
| `config/locales/console.{cs,en}.yml` | Překlady pro rename, delete, warning |
| `app/assets/stylesheets/.../react/_ordered_multiselect_app.sass` | Styly pro OptionWithActions |

### Beze změny (ponecháno, žádný mrtvý kód)
| Soubor | Proč zůstává |
|--------|-------------|
| `formatCreateLabel.js` | Generuje text "Vytvořit X" — `OptionWithActions` ho doplní o ikonu a styl |
| `react_select_create` akce | Create endpoint zůstává funkční |
| `CHANGELOG.md` | Doplníme o rename/delete |

### Build (automaticky)
| Soubor | Popis |
|--------|-------|
| `app/assets/javascripts/folio/console/react.js` | Rebuild po změnách |

---

## Mrtvý kód — audit

Po implementaci žádný mrtvý kód nezůstane:

| Existující kód | Status | Důvod |
|---------------|--------|-------|
| `createable` prop v Select | **Používá se** | Přepíná mezi ReactSelect a AsyncCreatableSelect |
| `AsyncCreatableSelect` import | **Používá se** | Základ pro createable dropdown |
| `formatCreateLabel.js` | **Používá se** | Stále generuje text, OptionWithActions přidá styling |
| `onCreateOption` v OrderedMultiselectApp | **Používá se** | Handlesr pro POST create |
| `createUrl`/`createable` v Redux | **Používá se** | Předávají se do Select a OrderedMultiselectApp |
| `isValidNewOption` v Select | **Používá se** | Zabraňuje duplicitám |
| `apiPost` import v OrderedMultiselectApp | **Používá se** | Pro create; doplníme `apiPatch`, `apiDelete` |

Vše z aktuální implementace se aktivně používá. Nový kód jen rozšiřuje, nic nenahrazuje.

---

## Pořadí implementace (doporučené)

1. **Routes + Controller** (backend) — aby API fungovalo
2. **Redux duck** — nové akce a state
3. **index.js init** — parsování nových atributů
4. **react_helper.rb** — nové data atributy
5. **OptionWithActions.js** — nová komponenta (jádro)
6. **Select/index.js** — napojení komponenty
7. **OrderedMultiselectApp/index.js** — rename/delete handlery
8. **Styly** — SASS
9. **Překlady** — cs/en
10. **Build + test**
