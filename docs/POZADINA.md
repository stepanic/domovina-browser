# Pozadina i odluke — DOMOVINA Browser

Ovaj dokument hvata *zašto* ovaj projekt postoji i *kako* je nastao, da kontekst
ne ostane samo u glavi. Pisano kronološki, kako se razvijala sesija.

---

## 1. Problem

macOS browseri troše previše resursa:

- **RAM i disk cache** — Chromium browseri (Brave, Chrome, Arc, Edge) svaki nosi
  vlastitu kopiju cijelog enginea; svaki tab je zaseban proces.
- **Brave + Google Meet** — screensharing puca svakih par minuta (poznat bug u
  Braveovom Chromium buildu, najčešće vezan uz hardware acceleration / screen
  capture API).

Cilj: **brz, CPU/RAM-lagan, open-source browser** — ili, ako toga nema, isprintati
vlastiti.

## 2. Temeljna istina o browserima na macOS-u

Svaki browser je ili **WebKit**, ili **Chromium**, ili **Gecko (Firefox)**. Težina
dolazi od toga koliko engine-a app nosi sa sobom:

- **Chromium** (Brave/Chrome/Arc/Edge) → bundla cijeli engine → gigabajti RAM-a.
- **WebKit** → koristi **sistemski `WKWebView`** koji je već u macOS-u i Apple ga
  agresivno optimizira za bateriju/RAM. **Najlakša moguća opcija.**
- **Gecko** → srednja težina, potpuno open-source.

## 3. Razmotrene alternative (od najlakšeg)

| Browser | Engine | Open-source | Napomena |
|---|---|---|---|
| **Orion** (Kagi) | WebKit | ne (besplatan) | Najbolji "brz/lagan/native"; Chrome+Firefox extensioni |
| **Safari** | WebKit | ne | Najlakši za bateriju, dio sistema |
| **LibreWolf / Firefox** | Gecko | da | Ako je open-source tvrdi zahtjev |
| **qutebrowser / Nyxt** | QtWebEngine / WebKit | da | Keyboard-driven, power user |
| **Ladybird** | vlastiti | da | U 2026 još alpha, nije za daily driver |

## 4. Odluka: isprintati vlastiti

| Pristup | Izvedivost | Težina |
|---|---|---|
| Vlastiti engine (kao Ladybird) | ne | godine rada |
| **Wrap sistemskog WebKita** (SwiftUI + `WKWebView`) | **da, vikend projekt** | par stotina linija Swifta |

Drugi red odgovara cilju: native Swift app oko `WKWebView` koristi *isti* engine kao
Safari → jednako lagan, bez drugog Chromiuma. Trade-off: nema Chrome extensiona
(`WKWebView` ih ne podržava) i nešto DRM caveata.

## 5. Što je izgrađeno

- **Jedan Swift file** (`DomovinaBrowser.swift`), SwiftUI + `WKWebView`.
- **Build bez Xcode-a** — `./build.sh` je samo `swiftc` + ručni `.app` bundle + ad-hoc potpis
  (dovoljno za trajnu lokalnu instalaciju; sve radi osim passkeya, vidi §7).
- **Xcode projekt** (za pravi potpis/passkey) generira se iz [`project.yml`](../project.yml)
  s `xcodegen generate` — `.xcodeproj`/`Info.plist`/`.entitlements` su gitignorani jer
  je `project.yml` izvor istine.
- **Tvrdi cap na tabove** — `MAX_TABS` (default `7`); "+" se disabla na maksimumu.
- Adresna traka radi i kao Google pretraga; back/forward/reload; swipe geste.
- Tipkovnica: `⌘T` novi tab, `⌘W` zatvori, `⌘R` osvježi.
- `window.open` / `target=_blank` → otvara se u istom tabu (bez novih prozora).

Namjerno **nema**: bookmarka, historyja, sync-a, postavki. To su "kerefeke".

## 6. Brendiranje (DOMOVINA)

Brand tokeni: navy `#002F6C`, red `#FF0000`, white. Stripe red→white→navy.

- **Brand stripe** 6px na vrhu prozora.
- Navy akcenti (tabovi, nav gumbi), crveni "+".
- **Light DOMOVINA tema forsirana** (`.preferredColorScheme(.light)`) — prvi pokušaj
  je imao navy tekst na sistemskom dark backgroundu → nečitljivo. Light tema daje
  čist kontrast bez obzira na sistemski mode.
- **Ikona** generirana iz mediakit glypha: `mediakit.domovina.tv/domovina_browser_logo_square.svg`
  (flag-"D" + navy prozor, **lijeva točka crvena** kao accent) → `rsvg-convert` →
  `sips`/`iconutil` → `AppIcon.icns`. Prati isti template kao ostali sub-brandovi
  (`domovina_<ime>_logo_square`).

## 7. Passkey / WebAuthn — dva puta (i koji smo odabrali)

Postoje dva odvojena načina da passkey radi u `WKWebView`-u — gate ovisi o tome za
**koje domene** ga treba:

| | **Associated Domains** (odabrano) | **Web Browser entitlement** |
|---|---|---|
| Za koje domene | samo **vlastite** (`domovina.ai`, `pinka.io`) | bilo koji site na internetu |
| Apple ručno odobrenje | **NE** | DA (restricted) |
| Entitlement | `com.apple.developer.associated-domains` | `…web-browser.public-key-credential` |
| Uvjet | AASA file na svakoj domeni + RP ID = domena | Appleovo odobrenje |

**Zašto je WKWebView uopće gated:** anti-phishing — bez entitlementa bilo koja app
mogla bi ubaciti nevidljivi webview i pokupiti passkey. Apple zato `navigator.credentials`
u `WKWebView`-u dopušta samo (a) odobrenim browserima za sve domene, ili (b) appovima
za **njihove vlastite** associated domene.

**Odluka:** trebaju nam samo `domovina.ai` i `pinka.io` (vlastiti servisi) → idemo
Associated Domains putem, bez Appleovog odobrenja. Restricted browser entitlement bismo
trebali samo da želimo biti univerzalni browser za cijeli internet (ili bismo morali
mijenjati engine na Chromium/Gecko — što ubija lagani WebKit pristup, vidi §2).

Uvjeti da proradi (svi u našim rukama):

1. **AASA file** na svakoj domeni, HTTPS, bez redirecta, `Content-Type: application/json`:
   `https://domovina.ai/.well-known/apple-app-site-association` (i isto za `pinka.io`)
   ```json
   { "webcredentials": { "apps": ["6SCK58757K.ai.domovina.browser"] } }
   ```
   (sadržaj živi u [`docs/apple-app-site-association`](apple-app-site-association))
2. **Relying Party ID** na stranici = točno ta domena.
3. **Pravi Development potpis** (ITalk team `6SCK58757K`) — ad-hoc NE poštuje ovaj
   managed entitlement; treba provisioning profil koji ga sadrži. Xcode to stvori
   automatski uz "Automatically manage signing".

Caveat: passkey-u-WKWebView dobro je dokumentiran za iOS; na macOS-u je sivo područje
→ testira se na stvarnoj stranici, fallback je native `ASAuthorization` flow.

Ožičeno (sve preko [`project.yml`](../project.yml), xcodegen generira ostalo):
- `com.apple.developer.associated-domains` (oba `webcredentials:`) + `device.bluetooth`
- `NSBluetoothAlwaysUsageDescription` u Info.plistu (cross-device passkey s telefona)
- Bundle: `ai.domovina.browser`; signing: Automatic, team ITalk `6SCK58757K`

## 8. Bonus nalaz: pravi uzrok RAM pritiska

Tijekom testiranja iskočio je macOS "system has run out of application memory"
dialog koji je otkrio prave krivce — **ne browser**:

| Proces | RAM |
|---|---|
| iTerm2 | **~33 GB** |
| Docker Desktop | **~9 GB** |
| DOMOVINA Browser | ~120–270 MB |

Zaključak: restartati iTerm2 (vjerojatno scrollback/leak) i pauzirati Docker kad se
ne koristi rješava više nego mijenjanje browsera.

---

*Repo: https://github.com/stepanic/domovina-browser · dio DOMOVINA projekata 🇭🇷*
