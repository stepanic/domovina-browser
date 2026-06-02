<div align="center">

<!-- DOMOVINA brand stripe: red → white → navy -->
![](https://img.shields.io/badge/-%20-FF0000) ![](https://img.shields.io/badge/-%20-FFFFFF) ![](https://img.shields.io/badge/-%20-002F6C)

# DOMOVINA Browser

**Maksimalno lagan native macOS browser — tabovi i ništa više.**

</div>

Native macOS app oko sistemskog **WebKita** (`WKWebView`) — isti engine kao Safari,
bez bundlanog Chromiuma. Znači: lagan na RAM-u, disku i CPU-u, bez 100 nepotrebnih
opcija. Jedno pravilo: **najviše `MAX_TABS` tabova** i to je sve.

## Zašto

Chromium browseri (Brave, Chrome, Arc, Edge) nose vlastitu kopiju cijelog enginea →
gigabajti RAM-a, golem cache na disku, svaki tab zaseban proces. DOMOVINA Browser
koristi WebKit koji je **već dio macOS-a** i Apple ga agresivno optimizira za
bateriju i memoriju.

## Značajke

- ⚡️ Sistemski WebKit — lagan kao Safari, bez bundlanog enginea
- 🔢 Tvrdi cap na broj tabova (`MAX_TABS`, default `7`)
- 🔎 Adresna traka radi i kao Google pretraga
- ⬅️➡️ Back / forward / reload, swipe geste
- ⌨️ `⌘T` novi tab · `⌘W` zatvori tab · `⌘R` osvježi
- 🇭🇷 Hrvatski UI, DOMOVINA brending (navy `#002F6C` / red `#FF0000`)
- 📦 Bez Xcode-a — build je jedan `swiftc` poziv

## Build

```bash
./build.sh
open "DomovinaBrowser.app"
```

Treba samo Xcode Command Line Tools (`xcode-select --install`). Nema dependencyja,
nema package managera.

## Konfiguracija

Sve što se mijenja je na vrhu [`DomovinaBrowser.swift`](DomovinaBrowser.swift):

```swift
let MAX_TABS = 7
let HOME = "https://www.google.com"
```

## Ograničenja (namjerno)

- Bez Chrome extensiona — `WKWebView` ih ne podržava.
- Bez bookmarka, historyja, sync-a, postavki. To su "kerefeke" koje ovaj browser nema.

## Licenca

MIT — vidi [LICENSE](LICENSE).

---

<div align="center">
Dio <strong>DOMOVINA</strong> projekata · 🇭🇷
</div>
