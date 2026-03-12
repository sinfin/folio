# Postup testování: dva uživatelé editují stejný článek (TipTap + revize)

Cíl: ověřit chování **Console URL Bar** a **Autosave Info** komponenty ve všech situacích, kdy stejný článek editují dva uživatelé — s uložením i bez (revize se vytváří/aktualizuje automaticky v intervalech).

---

## Předpoklady

- Dva konzolové účty (např. **Alice** a **Bob**).
- Jeden článek (nebo jiný model s TipTap + autosave) — dále jen „článek“.
- Autosave revizí je zapnutý (TipTap konfigurace), revize se ukládají v intervalech bez nutnosti kliknout na „Uložit“.

---

## Co sledovat

### Console URL Bar (horní lišta)

- **Kdy se zobrazí:** jen na stránce **edit** (a update), a pouze pokud platí alespoň jedno:
  - na stejné URL je jiný uživatel (podle `console_url` + ping každých cca 10 s, platnost cca 5 min), **nebo**
  - aktuální uživatel má **zastaralou revizi** (je označená jako `superseded` — někdo mezitím uložil).
- **Tři stavy lišty:**
  1. **„Stránka byla upravena uživatelem X na novější verzi“** — máte zastaralou revizi (někdo uložil). Tlačítko: **„Zahodit změny a pokračovat v aktuální verzi“** (smazání vaší revize + reload).
  2. **„Tuto stránku nyní upravuje X (od …)“** — druhý uživatel má na téže URL revizi. Tlačítka: **„Převzít úpravu“** (takeover jeho revize do vaší + reload), **„Zpět“** (návrat na index).
  3. **„Tuto stránku nyní upravuje“** + jméno, **bez tlačítek** — druhý uživatel je na URL, ale nemá revizi (jen „přítomen“).

### Autosave Info (blok u editoru)

- **Kdy se zobrazí:** když má **aktuální uživatel** neuložené změny (existuje jeho revize pro tento článek/atribut).
- **Stavy:**
  - **„Editor obsahuje neuložené rozepsané změny“** — vždy když máte revizi.
  - **„Uživatel X uložil mezitím novou verzi obsahu!“** — vaše revize je starší než uložení záznamu (`outdated_revision?`). Tlačítko: **„Zahodit změny a pokračovat v aktuální verzi“** (reload stránky; v implementaci může volat takeover).
  - **„Uživatel X mezitím také přidal neuložené změny“** — konflikt revizí (vaše revize není ta nejnovější v DB). Text s porovnáním časů „Vy“ vs „X“. Tlačítka: **„Použít moji verzi“** (skrýt blok a pokračovat v editaci), **„Použít verzi jiného uživatele“** (takeover jeho revize + reload).

---

## Scénáře k projití

### 1. Oba editují, nikdo neuložil — druhý má revizi

- **Alice** otevře článek na edit, nechá načíst stránku (ping se odešle, `console_url` se nastaví).
- **Bob** otevře tentýž článek na edit.
  - **Bob:** Console Bar by se měla zobrazit: „Tuto stránku nyní upravuje Alice (od …)“ a tlačítka „Převzít úpravu“ / „Zpět“. Autosave Info se u Boba nezobrazí, dokud nezačne editovat (nemá svou revizi).
- **Alice** v editoru něco změní — po intervalu autosave se vytvoří/aktualizuje její revize.
- **Bob** obnoví stránku (F5) nebo počká na další vykreslení (např. po svém prvním zápisu).
  - **Bob:** Bar stále „Tuto stránku nyní upravuje Alice“ a nyní by měla být **s tlačítky** (Alice má revizi) — „Převzít úpravu“ / „Zpět“.
- **Bob** v editoru něco změní — vytvoří se jeho revize.
  - **Bob:** Autosave Info: „Editor obsahuje neuložené rozepsané změny“ a **„Uživatel Alice mezitím také přidal neuložené změny“** + porovnání časů + „Použít moji verzi“ / „Použít verzi jiného uživatele“.
- **Alice** obnoví stránku.
  - **Alice:** Bar: „Tuto stránku nyní upravuje Bob“ + tlačítka. Autosave Info: její neuložené změny + „Uživatel Bob mezitím také přidal neuložené změny“ + stejná tlačítka.

**Ověřit:**
- Kdo má revizi → u toho se v Autosave Info ukazuje konflikt nebo info o neuložených změnách.
- Kdo nemá revizi ale je na URL → u toho jen Bar s „upravuje X“ (s nebo bez tlačítek podle toho, jestli X má revizi).

---

### 2. Alice uloží, Bob má starou revizi (zastaralá revize)

- **Alice** a **Bob** mají oba otevřený stejný článek; oba něco napsali (existují obě revize).
- **Alice** klikne **Uložit** (uloží formulář).
  - Na backendu: Alice revize se smažou, Bobovy revize se označí jako `superseded_by_user_id = Alice`.
- **Bob** neobnoví stránku; má stále otevřený starý stav.
  - **Bob:** Console Bar by měla přejít do režimu **zastaralé revize**: „Stránka byla upravena uživatelem Alice na novější verzi (…)“ a tlačítko **„Zahodit změny a pokračovat v aktuální verzi“**. (Bar se může aktualizovat po dalším requestu, např. po dalším autosave nebo po obnovení.)
  - **Bob:** Autosave Info: „Editor obsahuje neuložené rozepsané změny“ a **„Uživatel Alice uložil mezitím novou verzi obsahu!“** a tlačítko **„Zahodit změny a pokračovat v aktuální verzi“**.

**Ověřit:**
- U Boba se zobrazí zastaralá verze (Bar i Autosave Info).
- Po kliknutí na „Zahodit změny a pokračovat v aktuální verzi“ v **Bar** (delete revize + reload): Bobův editor ukáže aktuální uložený obsah od Alice.
- Stejná akce v **Autosave Info** by měla vést k načtení aktuální verze (reload); ověřit, že nedojde k chybě (např. pokud se volá takeover s `from_user_id`).

---

### 3. Bob převzetím převezme Alicinu revizi (takeover)

- **Alice** má článek otevřený a má neuložené změny (revize existuje).
- **Bob** otevře tentýž článek.
  - **Bob:** Bar: „Tuto stránku nyní upravuje Alice“ + **„Převzít úpravu“** / „Zpět“.
- **Bob** klikne **„Převzít úpravu“**.
  - Backend: vytvoří/aktualizuje Bobovu revizi obsahem z Aliciny revize; Alici se nastaví `console_url = nil`.
  - Stránka se u Boba reloadne.
- **Bob:** Editor ukáže obsah, který měla Alice v revizi (ne nutně to, co je uloženo v článku).
- **Alice** obnoví stránku nebo přejde jinam a zpět.
  - **Alice:** Bar by se už neměla zobrazovat (Bob „vzal“ úpravu; Alice už není považována za toho, kdo stránku edituje).

**Ověřit:**
- Po takeover má Bob v editoru obsah z Aliciny revize.
- Po reloadu/refreshi u Alice už Bar neukazuje „druhý uživatel na této stránce“ (pokud tam není nikdo jiný).

---

### 4. Bob pouze na stránce, bez revize (jen „přítomen“)

- **Alice** otevře článek a má revizi (něco napsala, autosave proběhl).
- **Bob** otevře tentýž článek, ale **v editoru nic nezmění** (nemá revizi).
  - **Bob:** Bar: „Tuto stránku nyní upravuje Alice“ — pokud logika rozliší „má revizi“ vs „jen na URL“, může být **bez tlačítek** (protože převzetí má smysl jen když Alice má revizi; v kódu je `other_user_has_revision?` pro zobrazení tlačítek).
- **Alice** obnoví stránku.
  - **Alice:** Bar: „Tuto stránku nyní upravuje Bob“ — protože Bob je na URL. Tlačítka by se **nezobrazila** (`other_user_has_revision?` je false), jen text s Bobovým jménem.

**Ověřit:**
- Když druhý uživatel nemá revizi, Bar ukazuje jen informaci „stránku upravuje X“, bez „Převzít úpravu“.

---

### 5. Časový limit „kdo je na stránce“ (console_url)

- **Alice** otevře článek na edit a pak zavře prohlížeč nebo dlouho nechá záložku neaktivní (např. > 5 minut bez pingu).
- **Bob** otevře tentýž článek.
  - Očekávání: pokud Alice nepingovala víc než cca 5 minut, `currently_editing_url` ji už nevrátí — **Bob** by **neměl** vidět Bar „Tuto stránku nyní upravuje Alice“.

**Ověřit:**
- Po vypršení okna (např. 5 min bez aktivity) Bar u druhého uživatele zmizí.

---

### 6. Autosave Info — „Použít moji verzi“ vs „Použít verzi jiného uživatele“

- Oba mají revize (konflikt).
- **Bob** klikne **„Použít moji verzi“**: blok Autosave Info se skryje, Bob dál edituje svojí verzi (žádný reload, žádný takeover).
- **Bob** klikne **„Použít verzi jiného uživatele“**: volá se takeover (obsah od Alice do Bobovy revize) + reload — Bob vidí Alicin obsah.

**Ověřit:**
- „Použít moji verzi“ jen skryje upozornění a nezmění obsah.
- „Použít verzi jiného uživatele“ načte obsah druhého uživatele a stránka se přenačte.

---

## Shrnutí — kdo co vidí

| Situace | Console URL Bar | Autosave Info |
|--------|------------------|----------------|
| Druhý uživatel na URL, nemá revizi | „Upravuje X“, bez tlačítek | — (pokud já nemám revizi) |
| Druhý uživatel na URL, má revizi | „Upravuje X“ + Převzít / Zpět | Pokud mám revizi: konflikt „X mezitím přidal změny“ + Použít moji / jeho verzi |
| Já mám revizi, nikdo jiný neuložil | — (pokud na URL nikdo jiný není) | „Neuložené rozepsané změny“ |
| Někdo mezitím uložil (moje revize je superseded) | „Stránka byla upravena X na novější verzi“ + Zahodit a pokračovat | „X uložil mezitím novou verzi“ + Zahodit a pokračovat |

Tím pokryješ kombinace s/bez uložení a s automatickými revizemi a ověříš, kdo co udělal a co se komu zobrazuje v Console Bar i v Autosave Info komponentě.


### Nebo jinak (a ručně)
1) Alice otevře a nic nepíše + Bob otevře a nic nepíše = pro oba varování o editaci v console baru, bez tlačítek
2) Alice něco zapíše (má revizi) => Bobovi přibudou tlačítka
3a) Bob nepřevezme a edituje svoje (oba mají revizi, každý jinou) => tlačítka u obou pro převzetí
3b) Bob převezme a nic nedělá (oba mají své revize se stejným obsahem) => žádná tlačítka (?)

4) Alice uloží svůj článek (její revize se smažou, u ostatních se nastaví superseeded) => U Alice jen varování jako v 1)
   U Boba varování o uloženém obsahu a tlačítko na reload


  Co vidí Alice:

   Alice \ Bob | bez revize | jeho revize    | uložil |
   ----------------------------------------------------
   bez revize  | VSE        | VSE+VCNZ       | VSE+VNUV
   její revize | VSE + VVNZ | VSE+VVNZ+VCNZ  | VSE+VNUV
   uložila     | VSE        | VSE            | ?

   VSE = varování o souběžné editaci (console bar)
   VNUV = varování o novější uložené verzi + reload button (console bar)
   VVNZ = Varování o vlastních neuložených změnách (tiptap)
   VCNZ = Varování o cizích neuložených změnách (tiptap) + tlačítka na převzetí / ponechání
