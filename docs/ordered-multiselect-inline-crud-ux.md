# Ordered Multiselect: Notion-style Inline CRUD — Návrh

## Existující Folio patterns, na které stavíme

| Pattern | Kde ve Folio | Co z toho použijeme |
|---------|-------------|-------------------|
| **DropdownComponent** (tříbodové menu) | `app/components/folio/console/ui/dropdown_component` | Vizuální vzor — `dots_vertical` ikona, Bootstrap dropdown |
| **FolioUiIcon** | `react/src/components/FolioUiIcon` | React wrapper pro SVG ikony (`delete`, `edit_box`, `dots_vertical`) |
| **makeConfirmed** | `react/src/utils/confirmed.js` | Confirm dialog před destruktivní akcí |
| **apiPost / apiGet** | `react/src/utils/api.js` | API volání pro CRUD operace |
| **InPlaceInputComponent** | `app/components/folio/console/ui/in_place_input_component` | Click-to-edit vzor (Stimulus, ale logiku replikujeme v Reactu) |
| **formatCreateLabel** | `react/src/components/Select/formatCreateLabel.js` | Stávající "Vytvořit" label |
| **Collapsed index actions** | `app/cells/folio/console/index/actions_cell.rb` | Pattern: akce v tříbodovém menu na řádku |

---

## Cílový UX

### 1. Vylepšený Create v dropdownu

```
┌───────────────────────────────────────────────────┐
│  Přístup k prémiovému obsahu                      │
│  Mobilní aplikace                                 │
│  ─────────────────────────────────────────────    │
│  ＋ Vytvořit "Nová vlastnost"                     │  ← zelená, tučné ＋
└───────────────────────────────────────────────────┘
```

Implementace: Custom `Option` komponenta v react-select, detekce `data.__isNew__`.

### 2. Tříbodové menu u položek v dropdownu

Každá existující položka v dropdownu (ne nově vytvářená) má tříbodové menu vpravo:

```
┌───────────────────────────────────────────────────┐
│  Přístup k prémiovému obsahu              ⋮       │
│  Mobilní aplikace                         ⋮       │
│  Nová vlastnost.                          ⋮       │
│  ─────────────────────────────────────────────    │
│  ＋ Vytvořit "Jiná vlastnost"                     │
└───────────────────────────────────────────────────┘
```

Klik na ⋮ otevře sub-menu (Bootstrap dropdown nebo absolutně pozicovaný div):

```
                                    ┌──────────────────┐
│  Mobilní aplikace            ⋮  → │ ✏️ Přejmenovat    │
│  ...                              │ 🗑 Smazat (2×)    │
                                    └──────────────────┘
```

"(2×)" = "použito ve 2 plánech" — informace z API.

### 3. Přejmenovat (inline v sub-menu)

Klik na "Přejmenovat" → sub-menu se změní na input:

```
                                    ┌──────────────────────┐
│  Mobilní aplikace            ⋮  → │ [Mobilní aplikace ✓] │
│  ...                              └──────────────────────┘
```

Enter nebo ✓ = uloží přes API PATCH. Escape = zruší.

### 4. Smazat z DB (s varováním)

Klik na "Smazat" → pokud je záznam použit jinde:

```
┌─────────────────────────────────────────────────┐
│  ⚠ Smazat "Mobilní aplikace"?                  │
│                                                 │
│  Tato vlastnost je přiřazena ke 2 typům         │
│  předplatného. Smazáním ji odeberete i z nich.  │
│                                                 │
│               [Zrušit]  [Smazat]                │
└─────────────────────────────────────────────────┘
```

Pokud není nikde jinde použita → jednoduchý `window.confirm()`.

---

## Implementační plán

### Fáze 1: Vizuální odlišení "Vytvořit" (malá změna)

**Soubory:**
- `react/src/components/Select/index.js` — přidat custom `Option` komponentu
- `app/assets/stylesheets/folio/console/modules/react/_ordered_multiselect_app.sass` — styly

**Kód (Option komponenta):**
```jsx
// react/src/components/Select/CreatableOption.js
import React from 'react'
import { components } from 'react-select'

export default function CreatableOption(props) {
  const { data, children } = props
  if (data.__isNew__) {
    return (
      <components.Option {...props}>
        <span className="f-c-r-select-create-option">
          <span className="f-c-r-select-create-option__icon">＋</span>
          {children}
        </span>
      </components.Option>
    )
  }
  return <components.Option {...props}>{children}</components.Option>
}
```

**Styly:**
```sass
.f-c-r-select-create-option
  font-weight: 500
  color: var(--bs-success)

  &__icon
    margin-right: 6px
    font-weight: 700
```

### Fáze 2: Tříbodové menu + Rename v dropdownu

**Nové soubory:**
- `react/src/components/Select/OptionWithActions.js` — custom Option s ⋮ menu

**Upravené soubory:**
- `react/src/components/Select/index.js` — přepnout na OptionWithActions když `createable`
- `react/src/containers/OrderedMultiselectApp/index.js` — předat `onRename` callback
- `react/src/ducks/orderedMultiselect.js` — `RENAME_ITEM` action (aktualizuje label v items)

**Nový API endpoint ve Folio:**
- `PATCH /console/api/autocomplete/react_select_update` — přejmenování záznamu
  ```ruby
  def react_select_update
    klass = params.require(:class_name).safe_constantize
    record = klass.find(params.require(:id))
    authorize!(:update, record)
    record.title = params.require(:label)
    if record.save
      render json: { data: { id: record.id, label: record.to_console_label } }
    else
      render json: { error: record.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end
  ```

**Kód (OptionWithActions):**
```jsx
// react/src/components/Select/OptionWithActions.js
import React, { useState, useRef, useEffect } from 'react'
import { components } from 'react-select'
import FolioUiIcon from 'components/FolioUiIcon'

export default function OptionWithActions(props) {
  const { data, selectProps } = props
  const [menuOpen, setMenuOpen] = useState(false)
  const [renaming, setRenaming] = useState(false)
  const [renameValue, setRenameValue] = useState(data.label || '')
  const inputRef = useRef(null)

  // Nově vytvářené položky — zelený styl
  if (data.__isNew__) {
    return (
      <components.Option {...props}>
        <span className="f-c-r-select-create-option">
          <span className="f-c-r-select-create-option__icon">＋</span>
          {props.children}
        </span>
      </components.Option>
    )
  }

  useEffect(() => {
    if (renaming && inputRef.current) inputRef.current.focus()
  }, [renaming])

  const onDotsClick = (e) => {
    e.preventDefault()
    e.stopPropagation()
    setMenuOpen(!menuOpen)
  }

  const onRenameClick = (e) => {
    e.preventDefault()
    e.stopPropagation()
    setRenaming(true)
    setMenuOpen(false)
  }

  const onRenameSubmit = (e) => {
    e.preventDefault()
    e.stopPropagation()
    if (renameValue.trim() && renameValue !== data.label) {
      selectProps.onRenameOption?.(data, renameValue.trim())
    }
    setRenaming(false)
  }

  const onRenameKeyDown = (e) => {
    e.stopPropagation()  // brání react-select v zachycení
    if (e.key === 'Enter') onRenameSubmit(e)
    if (e.key === 'Escape') { setRenaming(false); setRenameValue(data.label) }
  }

  const onDeleteClick = (e) => {
    e.preventDefault()
    e.stopPropagation()
    setMenuOpen(false)
    selectProps.onDeleteOption?.(data)
  }

  if (renaming) {
    return (
      <div className="f-c-r-select-option-rename">
        <input
          ref={inputRef}
          className="f-c-r-select-option-rename__input"
          value={renameValue}
          onChange={(e) => setRenameValue(e.target.value)}
          onKeyDown={onRenameKeyDown}
          onBlur={onRenameSubmit}
        />
      </div>
    )
  }

  return (
    <components.Option {...props}>
      <div className="f-c-r-select-option-with-actions">
        <span className="f-c-r-select-option-with-actions__label">
          {props.children}
        </span>
        <span
          className="f-c-r-select-option-with-actions__dots"
          onClick={onDotsClick}
        >
          <FolioUiIcon name="dots_vertical" height={16} />
        </span>

        {menuOpen && (
          <div className="f-c-r-select-option-with-actions__menu">
            <div
              className="f-c-r-select-option-with-actions__menu-item"
              onClick={onRenameClick}
            >
              <FolioUiIcon name="edit_box" height={14} />
              <span>{window.FolioConsole.translations.rename || 'Přejmenovat'}</span>
            </div>
            <div
              className="f-c-r-select-option-with-actions__menu-item
                          f-c-r-select-option-with-actions__menu-item--danger"
              onClick={onDeleteClick}
            >
              <FolioUiIcon name="delete" height={14} />
              <span>{window.FolioConsole.translations.delete || 'Smazat'}</span>
            </div>
          </div>
        )}
      </div>
    </components.Option>
  )
}
```

**Styly:**
```sass
.f-c-r-select-option-with-actions
  display: flex
  align-items: center
  justify-content: space-between
  width: 100%

  &__label
    flex: 1
    overflow: hidden
    text-overflow: ellipsis
    white-space: nowrap

  &__dots
    flex-shrink: 0
    padding: 2px 4px
    cursor: pointer
    opacity: 0.4
    border-radius: $border-radius-sm
    margin-left: $spacer / 2

    &:hover
      opacity: 1
      background: rgba(0, 0, 0, 0.08)

  &__menu
    position: absolute
    right: 8px
    top: 50%
    transform: translateY(-50%)
    background: $white
    border: 1px solid $border-color
    border-radius: $border-radius
    box-shadow: $box-shadow-sm
    z-index: 10
    min-width: 140px
    padding: 4px 0

  &__menu-item
    display: flex
    align-items: center
    gap: 8px
    padding: 6px 12px
    cursor: pointer
    font-size: $font-size-sm
    white-space: nowrap

    &:hover
      background: $gray-100

    &--danger
      color: var(--bs-danger)

      &:hover
        background: rgba(var(--bs-danger-rgb), 0.08)

.f-c-r-select-option-rename
  padding: 4px 8px

  &__input
    width: 100%
    border: 1px solid $primary
    border-radius: $border-radius-sm
    padding: 4px 8px
    font-size: $font-size-sm
    outline: none

.f-c-r-select-create-option
  font-weight: 500
  color: var(--bs-success)

  &__icon
    margin-right: 6px
    font-weight: 700
```

### Fáze 3: Delete z DB s varováním

**Nový API endpoint:**
- `DELETE /console/api/autocomplete/react_select_destroy`
  ```ruby
  def react_select_destroy
    klass = params.require(:class_name).safe_constantize
    record = klass.find(params.require(:id))
    authorize!(:destroy, record)

    # Počet plánů/záznamů kde je použito (pro varování)
    usage_count = record.respond_to?(:usage_count_for_warning) ?
                    record.usage_count_for_warning : 0

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

**Flow:**
1. Klik na "Smazat" → API volání BEZ `confirmed=true` → vrátí `usage_count`
2. Pokud `usage_count > 0` → zobrazit varování s počtem
3. Po potvrzení → API volání S `confirmed=true` → smaže
4. Redux: odebrat z `items` (pokud byl přiřazený) + odebrat z dropdown options

**Varování (v React kódu):**
```javascript
onDeleteOption = (option) => {
  const { orderedMultiselect } = this.props
  apiDelete(orderedMultiselect.deleteUrl, { id: option.id })
    .then((res) => {
      if (res.data.confirm_required) {
        const count = res.data.usage_count
        const msg = count === 1
          ? `Tato vlastnost je přiřazena k 1 dalšímu typu předplatného. Smazáním ji odeberete i z něj.`
          : `Tato vlastnost je přiřazena ke ${count} dalším typům předplatného. Smazáním ji odeberete i z nich.`
        if (window.confirm(msg)) {
          apiDelete(orderedMultiselect.deleteUrl, { id: option.id, confirmed: true })
            .then(() => {
              this.props.dispatch(removeItemFromAll(option.id))
            })
        }
      } else {
        if (window.confirm(window.FolioConsole.translations.removePrompt)) {
          apiDelete(orderedMultiselect.deleteUrl, { id: option.id, confirmed: true })
            .then(() => {
              this.props.dispatch(removeItemFromAll(option.id))
            })
        }
      }
    })
}
```

Poznámka: varování je přes `window.confirm()` — v souladu s Folio konvencí (viz `makeConfirmed`).
Custom modal by byl hezčí, ale window.confirm je konzistentní se zbytkem Folia.

---

## Nové API endpointy (shrnutí)

| Method | Endpoint | Popis |
|--------|---------|-------|
| `POST` | `/console/api/autocomplete/react_select_create` | Vytvořit nový záznam (existuje) |
| `PATCH` | `/console/api/autocomplete/react_select_update` | Přejmenovat záznam |
| `DELETE` | `/console/api/autocomplete/react_select_destroy` | Smazat z DB (2-step: info → confirm) |

---

## Nové data atributy na komponentě

```ruby
"data-createable" => createable ? "1" : nil,        # existuje
"data-create-url" => create_url,                      # existuje
"data-update-url" => update_url,                      # nové
"data-delete-url" => delete_url,                      # nové
```

---

## Souhrn souborů ke změně

### Nové soubory (2)
- `react/src/components/Select/OptionWithActions.js`
- `react/src/components/Select/OptionWithActions.sass` (nebo do existujícího)

### Upravené soubory (8)
- `react/src/components/Select/index.js` — custom Option komponenta
- `react/src/containers/OrderedMultiselectApp/index.js` — onRename, onDelete handlers
- `react/src/ducks/orderedMultiselect.js` — RENAME_ITEM, REMOVE_ITEM_FROM_ALL actions
- `react/src/index.js` — parsování nových data atributů
- `app/controllers/folio/console/api/autocompletes_controller.rb` — 2 nové akce
- `app/helpers/folio/console/react_helper.rb` — nové data atributy
- `config/routes.rb` — nové routy
- `app/assets/stylesheets/folio/console/modules/react/_ordered_multiselect_app.sass` — styly

### Build
- `app/assets/javascripts/folio/console/react.js` — rebuilt

---

## Rizika a omezení

1. **Sub-menu uvnitř react-select dropdownu** — technicky náročné, protože klik na ⋮ nesmí vybrat položku ani zavřít dropdown. Řešení: `e.stopPropagation()` + `e.preventDefault()` na dots click.

2. **Rename input uvnitř dropdownu** — klávesové vstupy (šipky, enter) zachytává react-select. Řešení: `e.stopPropagation()` na keydown v rename inputu.

3. **Z-index sub-menu** — sub-menu musí být nad react-select dropdown menu. Řešení: `position: absolute` + `z-index` vyšší než dropdown.

4. **Refresh dropdown options po rename/delete** — po rename se musí aktualizovat options cache. `AsyncCreatableSelect` nemá native cache invalidation. Řešení: force remount přes `key` prop change.

5. **Generičnost** — `react_select_update` a `react_select_destroy` potřebují vědět název modelu. Přidáme `class_name` do URL parametrů, stejně jako u `react_select_create`.
