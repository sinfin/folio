# Systém Titulků - Kontrolní Seznam pro Manuální Testování

## Příprava Předpokladů

### Konfigurace Webu
- [ ] Přejít do Console → Nastavení webu
- [ ] Povolit "Automatické generování titulků" 
- [ ] Nastavit "Jazyky titulků" tak, aby obsahovaly alespoň `cs` a `en`
- [ ] Ověřit, že je ElevenLabs API klíč nakonfigurován v ENV: `ELEVENLABS_API_KEY`
- [ ] Ujistit se, že je povolen video transcription job v `app/overrides/models/folio/file/video_override.rb`

### Nastavení Databáze
- [ ] Spustit migrace: `rails db:migrate`
- [ ] Ověřit, že tabulka `folio_video_subtitles` existuje
- [ ] Ověřit, že `folio_sites` má sloupce `subtitle_languages` a `subtitle_auto_generation_enabled`

## 1. Nahrání Videa & Proces Zpracování

### Základní Nahrání
- [ ] Přejít do Console → Soubory → Videa
- [ ] Nahrát video soubor (nejlépe s českým nebo anglickým zvukem)
- [ ] Počkat na dokončení zpracování videa
- [ ] Ověřit, že se vygeneroval náhled videa
- [ ] Ověřit, že stav videa zobrazuje "Připraveno"

### Automatické Zpracování Titulků
- [ ] **Očekáváno**: Přepis titulků by se měl spustit automaticky po zpracování videa
- [ ] Otevřít modal videa → záložka Titulky
- [ ] **Očekáváno**: Zobrazuje se zpráva "Přepis probíhá..."
- [ ] **Očekáváno**: Zobrazuje se indikátor zpracování/spinner
- [ ] **Očekáváno**: Během zpracování se nezobrazují formuláře pro jazyky titulků
- [ ] Počkat na dokončení přepisu (2-5 minut v závislosti na délce videa)

### Dokončení Přepisu
- [ ] **Očekáváno**: Zpráva o zpracování zmizí
- [ ] **Očekáváno**: Objeví se formulář pro titulky v detekovaném jazyce (pravděpodobně `cs`)
- [ ] **Očekáváno**: Text titulků je vyplněn obsahem ve formátu VTT
- [ ] **Očekáváno**: Stavová značka zobrazuje "Připraven" (zelené zaškrtnutí)
- [ ] **Očekáváno**: Titulky jsou automaticky povoleny, pokud je obsah validní

## 2. Testování Stavů Titulků & UI

### Stav Zpracování
- [ ] Nahrát nové video
- [ ] Ihned otevřít modal videa → záložka Titulky
- [ ] **Očekáváno**: Stav zobrazuje "Zpracovává se" s ikonou spinneru
- [ ] **Očekáváno**: Zobrazuje se "Přepis spuštěn v: [časová značka]"
- [ ] **Očekáváno**: Během zpracování nejsou dostupné editační formuláře

### Stav Připraven (Validní Obsah)
- [ ] Počkat na dokončení přepisu
- [ ] **Očekáváno**: Stavová značka zobrazuje "Připraven" (zelená)
- [ ] **Očekáváno**: Je dostupný přepínač povolit/zakázat
- [ ] **Očekáváno**: Textová oblast obsahuje správně naformátovaný VTT obsah
- [ ] **Očekáváno**: Jsou dostupná tlačítka Uložit/Zrušit

### Stav Připraven (Nevalidní Obsah)
- [ ] Najít video s nevalidním obsahem titulků (nebo manuálně vytvořit nevalidní VTT)
- [ ] **Očekáváno**: Stavová značka zobrazuje "Zakázáno" (sekundární barva)
- [ ] **Očekáváno**: Zobrazuje se červené upozornění s validační chybou
- [ ] **Očekáváno**: Jsou zobrazeny konkrétní chybové zprávy (např. "nevalidní blok titulků poblíž řádku X")
- [ ] **Očekáváno**: Titulky zůstávají zakázané, ale obsah je zachován

### Stav Neúspěch
- [ ] Simulovat selhání API (dočasný problém se sítí nebo neplatný API klíč)
- [ ] **Očekáváno**: Stav zobrazuje "Neúspěch"
- [ ] **Očekáváno**: Zobrazuje se chybová zpráva
- [ ] **Očekáváno**: Je dostupná možnost opakovat

## 3. Manuální Správa Titulků

### Vytváření Manuálních Titulků
- [ ] Otevřít modal videa → záložka Titulky
- [ ] Kliknout na "Přidat titulky" pro jazyk (např. angličtina)
- [ ] Zadat validní VTT obsah:
  ```
  00:00:01.000 --> 00:00:03.000
  Ahoj světe
  
  00:00:04.000 --> 00:00:06.000
  Toto je test
  ```
- [ ] Povolit titulky
- [ ] Kliknout na Uložit
- [ ] **Očekáváno**: Stav zobrazuje "Připraven"
- [ ] **Očekáváno**: Poslední aktivita zobrazuje "Manuální zadání"

### Editace Automaticky Generovaných Titulků
- [ ] Otevřít video s automaticky generovanými titulky
- [ ] Editovat text titulků
- [ ] Uložit změny
- [ ] **Očekáváno**: Stav se změní na "Manuální Úprava"
- [ ] **Očekáváno**: Poslední aktivita zobrazuje "Automaticky vygenerováno před X, manuálně upraveno před Y (Z úprav)"
- [ ] **Očekáváno**: Počet úprav se zvyšuje s každým uložením

### Povolování/Zakazování Titulků
- [ ] Přepnout povolit/zakázat titulky
- [ ] **Očekáváno**: Stav se okamžitě aktualizuje
- [ ] **Očekáváno**: Video přehrávač odráží změnu
- [ ] **Očekáváno**: Ve video přehrávači se zobrazují pouze povolené titulky

### Mazání Titulků
- [ ] Kliknout na tlačítko "Smazat titulky"
- [ ] Potvrdit smazání
- [ ] **Očekáváno**: Titulky jsou úplně odstraněny
- [ ] **Očekáváno**: Stránka se obnoví pro zobrazení aktualizovaného stavu

## 4. Integrace s Video Přehrávačem

### Zobrazení Titulků v Přehrávači
- [ ] Otevřít video s povolenými titulky
- [ ] Přehrát video
- [ ] **Očekáváno**: Titulky se zobrazují ve video přehrávači
- [ ] **Očekáváno**: Je dostupný výběr jazyka titulků
- [ ] **Očekáváno**: Časování odpovídá VTT časovým značkám

### Podpora Více Jazyků
- [ ] Přidat titulky pro více jazyků (cs, en)
- [ ] Povolit oba
- [ ] **Očekáváno**: Video přehrávač zobrazuje výběr jazyka
- [ ] **Očekáváno**: Lze přepínat mezi jazyky během přehrávání
- [ ] **Očekáváno**: Každý jazyk se zobrazuje správně

## 5. Detekce Jazyka & Záložní Řešení

### Silná Detekce Jazyka
- [ ] Nahrát video s jasným českým zvukem
- [ ] **Očekáváno**: Systém detekuje češtinu (spolehlivost > 50%)
- [ ] **Očekáváno**: Vytvoří titulky pro jazyk `cs`
- [ ] **Očekáváno**: Titulky jsou automaticky povoleny, pokud jsou validní

### Slabá Detekce Jazyka
- [ ] Nahrát video s nejasným/smíšeným jazykovým zvukem
- [ ] **Očekáváno**: Systém se vrátí k češtině (`cs`)
- [ ] **Očekáváno**: Zpracování pokračuje normálně
- [ ] **Očekáváno**: Manuální výběr jazyka je stále dostupný

### Detekce Nepodporovaného Jazyka
- [ ] Nahrát video s nepodporovaným jazykem (např. němčina)
- [ ] **Očekáváno**: Systém se vrátí k češtině (`cs`)
- [ ] **Očekáváno**: Uživatel může manuálně přidat podporované jazyky

## 6. Ošetření Chyb & Hraniční Případy

### Nevalidní VTT Formát
- [ ] Manuálně zadat nevalidní VTT obsah:
  ```
  Toto není VTT formát
  Náhodný text bez časových značek
  ```
- [ ] Pokusit se povolit titulky
- [ ] **Očekáváno**: Zobrazuje se validační chyba
- [ ] **Očekáváno**: Titulky zůstávají zakázané
- [ ] **Očekáváno**: Obsah je zachován pro editaci

### Síťová Selhání
- [ ] Dočasně zakázat internetové připojení
- [ ] Nahrát video (selže během přepisu)
- [ ] **Očekáváno**: Elegantní ošetření chyb
- [ ] **Očekáváno**: Možnost opakovat přepis
- [ ] **Očekáváno**: Manuální vytváření titulků stále funguje

### Velké Video Soubory
- [ ] Nahrát video větší než 2GB
- [ ] **Očekáváno**: Chyba validace velikosti souboru
- [ ] **Očekáváno**: Jasná chybová zpráva o limitech velikosti
- [ ] **Očekáváno**: Manuální vytváření titulků je stále dostupné

## 7. Hromadné Operace & Legacy API

### Legacy Update API
- [ ] Použít vývojářské nástroje prohlížeče k testování legacy API:
  ```javascript
  // V konzoli prohlížeče
  fetch('/console/api/file/videos/[VIDEO_ID]/update_subtitles', {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
    },
    body: JSON.stringify({
      file: {
        subtitles_cs_text: "00:00:01.000 --> 00:00:03.000\nLegacy test",
        subtitles_cs_enabled: "1"
      }
    })
  })
  ```
- [ ] **Očekáváno**: Titulky jsou vytvořeny/aktualizovány
- [ ] **Očekáváno**: Odpověď obsahuje aktualizované HTML komponenty

### Přepsat Vše
- [ ] Kliknout na tlačítko "Přepsat vše"
- [ ] **Očekáváno**: Všechny existující automaticky generované titulky jsou přezpracovány
- [ ] **Očekáváno**: Manuální titulky jsou zachovány
- [ ] **Očekáváno**: Indikátory zpracování se objeví pro všechny jazyky

## 8. Výkon & Stabilita

### Souběžné Zpracování
- [ ] Nahrát více videí současně
- [ ] **Očekáváno**: Každé se zpracovává nezávisle
- [ ] **Očekáváno**: Žádné konflikty nebo race conditions
- [ ] **Očekáváno**: UI se aktualizuje správně pro každé video

### Obnovení Prohlížeče Během Zpracování
- [ ] Spustit nahrávání/zpracování videa
- [ ] Obnovit prohlížeč během zpracování
- [ ] **Očekáváno**: Stav zpracování je zachován
- [ ] **Očekáváno**: Pokrok pokračuje správně
- [ ] **Očekáváno**: UI odráží aktuální stav

### Správa Paměti
- [ ] Nahrát a zpracovat několik velkých videí
- [ ] **Očekáváno**: Žádné úniky paměti
- [ ] **Očekáváno**: Dočasné soubory jsou vyčištěny
- [ ] **Očekáváno**: Systém zůstává responzivní

## 9. Finální Integrační Test

### End-to-End Workflow
1. [ ] Nahrát video s českým zvukem
2. [ ] Počkat na dokončení zpracování videa
3. [ ] Ověřit, že se spustí automatický přepis titulků
4. [ ] Počkat na dokončení přepisu
5. [ ] Ověřit, že jsou titulky automaticky povoleny
6. [ ] Přehrát video a ověřit zobrazení titulků
7. [ ] Manuálně editovat obsah titulků
8. [ ] Ověřit, že se stav změní na "Manuální Úprava"
9. [ ] Manuálně přidat anglické titulky
10. [ ] Ověřit, že video přehrávač zobrazuje výběr jazyka
11. [ ] Otestovat přepínání mezi jazyky
12. [ ] Smazat jeden jazyk titulků
13. [ ] Ověřit, že se video přehrávač odpovídajícím způsobem aktualizuje

## Běžné Problémy, Na Které Je Třeba Dávat Pozor

### ⚠️ Červené Vlajky
- [ ] Databázové chyby během vytváření titulků
- [ ] Nekonečné stavy zpracování
- [ ] UI se neaktualizuje po operacích
- [ ] Video přehrávač nereflektuje změny titulků
- [ ] Úniky paměti během zpracování
- [ ] Race conditions s konkurentními nahrávkami
- [ ] Validační chyby brání uložení videa

### ✅ Indikátory Úspěchu
- [ ] Plynulé nahrání videa do stavu připraven
- [ ] Automatické zpracování titulků bez zásahu
- [ ] Jasné přechody stavů s odpovídající zpětnou vazbou UI
- [ ] Manuální editace zachovává metadata automaticky generovaná
- [ ] Integrace s video přehrávačem funguje bezproblémově
- [ ] Chybové stavy jsou obnovitelné
- [ ] Výkon zůstává přijatelný s více videi

---

## Poznámky k Testovacímu Prostředí

- **Doporučená testovací videa**: 30-60 sekundové klipy s jasnou českou/anglickou řečí
- **Monitorování API**: Sledovat Rails logy pro spouštění jobů a chybové zprávy
- **Testování prohlížeče**: Testovat v Chrome, Firefox, Safari pro kompatibilitu
- **Mobilní testování**: Ověřit responzivní design na tabletu/telefonu
- **Síťové podmínky**: Testovat s rychlým i pomalým připojením

## Hlášení Problémů

Při hlášení problémů uvést:
- [ ] Přesné kroky pro reprodukci
- [ ] Očekávané vs skutečné chování
- [ ] Prohlížeč a verze
- [ ] Úryvky z Rails logů
- [ ] Charakteristiky video souboru (velikost, formát, jazyk)
- [ ] Detaily konfigurace webu 