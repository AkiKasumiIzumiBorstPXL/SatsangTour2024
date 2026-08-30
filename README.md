## Team

Aantal studenten: 1

Student 1: Aki Kasumi Izumi Borst

## Titel app

Satsang Tour 2024

## Programmeertaal

Swift / SwiftUI (iOS 17+, iPadOS 17+, macOS 14+)

## Link naar filmpje

[iPhone screen recording](https://share.icloud.com/photos/0a1iiMsLWgP9dJvDTMua8J0vw)

## Github link en branch

### Link

[Github link](https://github.com/AkiKasumiIzumiBorstPXL/SatsangTour2024)

### Branch

Branch: **main**

## Korte beschrijving

Satsang Tour 2024 is een devotionele muziekapplicatie gericht op de Art of Living gemeenschap. De app biedt een collectie van bhajans (devotionele liederen), opgeslagen in MEI/XML-formaat, rendert deze via Verovio tot visuele bladmuziek (SVG), en toont de spirituele betekenis van elk lied. Gebruikers kunnen door bhajans bladeren, bladmuziek bekijken en betekenissen raadplegen.

## Minimale eisen

Alle minimale eisen zijn vervuld. Hieronder per eis een gedetailleerde toelichting.

## Schermen

## Aantal schermen

Het aantal schermen in de app bedraagt **3**

### Lijst van schermen

1. **Sidebar (Master)** — `NavigationMenuView`: lijst van bhajans met deity-badge, titel, vertaalde titel en taal-tags. Bevat een `List` (equivalent van RecyclerView) met recycleerbare `MenuRow` items.
2. **Detail (Muziek)** — `BhajanDetailView`: Verovio SVG-rendering van bladmuziek in een `WKWebView`.
3. **Detail (Betekenis)** — `MeaningPanelView`: Spirituele betekenis per bhajan met regel-voor-regel uitleg (Devanagari, transliteratie, vertaling, commentaar).

Elk scherm bevat niet-triviale UI-elementen: labels, knoppen (toolbar toggle), afbeeldingen (SF Symbols, deity circle badges), segmented picker, scrollbare lijsten, en WebKit-weergave.

## Fragments (SwiftUI equivalent)

In SwiftUI komen **Views** overeen met Android Fragments. De app gebruikt volgende niet-triviale, zelfgeschreven Views die als Fragments fungeren:

- **`NavigationMenuView`** — Zelfgeschreven sidebar-view met eigen header, lijst, swipe-hint en empty-state. Niet auto-generated.
- **`BhajanDetailView`** — Zelfgeschreven detail-view met WebKit-integratie, loading-states en error-handling.
- **`MeaningPanelView`** — Zelfgeschreven panel met gestructureerde betekenisweergave, loading-indicator en close-button.
- **`MenuRow`** — Zelfgeschreven recycleerbaar lijstitem met deity-badge, titel, subtitel en tags.
- **`TagView`** — Herbruikbare tag-component.

Deze Views worden correct ingezet binnen een `NavigationSplitView` die de master-detail structuur beheert. Op compact width (iPhone portrait) worden ze via `preferredCompactColumn` gepusht en gepopt. Op regular width (iPad/macOS) worden ze side-by-side getoond.

## Lokale opslag / Shared Preferences

Lokale opslag wordt op twee niveaus aangepakt:

1. **`@AppStorage("lastBhajanId")`** (equivalent van SharedPreferences) — De laatst geselecteerde bhajan wordt persistent opgeslagen. Bij heropenen van de app wordt automatisch de juiste bhajan geladen en getoond in het detail-paneel.
2. **Bundled JSON fallback** — De `meanings/` map met individuele JSON-bestanden per bhajan wordt in de app-bundle meegeleverd als folder reference (blauwe map in Xcode). Indien de GitHub-web service niet bereikbaar is, worden de betekenissen lokaal geladen via `Bundle.main.url(forResource:withExtension:subdirectory:)`.
3. **Bundled MEI/XML bestanden** — Alle bladmuziekbestanden (`.xml`, `.mei`) worden in de app-bundle opgeslagen en uitgelezen via `Bundle.main.urls(forResourcesWithExtension:subdirectory:)`.

## Web service / API

De app haalt bhajan-betekenissen op van een GitHub-hosted JSON API:

- **Base URL:** `https://raw.githubusercontent.com/AkiKasumiIzumiBorstPXL/SatsangTour2024/main/SatsangTour2024/meanings`
- **Formaat:** Individuele JSON-bestanden per bhajan (bijv. `swagatam-krsna.json`)
- **Endpoint:** `GET /{bhajanKey}.json`
- **Timeout:** 15 seconden
- **Actor-based:** `MeaningService` is geïmplementeerd als een Swift `actor` voor thread-safe toegang.
- **Fallback:** Als de fetch faalt of er geen netwerkverbinding is, worden lokaal meegeleverde JSON-bestanden uit de app-bundle geladen (`MeaningService.loadFallbackMeaning()`).

De betekenissen bevatten per bhajan: een samenvatting, culturele context, en regel-voor-regel uitleg met originele tekst (Devanagari), transliteratie (IAST), vertaling (Nederlands) en commentaar.

## Asynchrone verwerking en threading

De app maakt uitgebreid gebruik van Swift Concurrency:

- **`async/await`** — Alle netwerkaanroepen (`URLSession.shared.data(for:)`) en parsing-operaties verlopen asynchroon.
- **`Task`** — Bij selectie van een bhajan wordt een `Task` gestart om parallel SVG-rendering en meaning-fetch uit te voeren.
- **`async let`** — In `BhajanStore.selectBhajan()` worden de SVG-rendering en meaning-fetch parallel uitgevoerd met `async let svgTask` en `async let meaningTask`.
- **`actor`** — `MeaningService` is een Swift `actor` wat thread-safety garandeert voor netwerkoperaties.
- **`@MainActor`** — `BhajanStore` is geannoteerd met `@MainActor` zodat alle UI-updates op de main thread plaatsvinden.
- **`CheckedContinuation`** — `MEIParser` gebruikt `withCheckedThrowingContinuation` om de delegate-based `XMLParser` te integreren met async/await.
- **`@Observable`** — De store gebruikt het moderne `@Observable` macro (Swift 5.9+) voor reactive UI-updates.

## Master-detail navigatie en RecyclerView

De app gebruikt `NavigationSplitView` voor master-detail navigatie:

- **Master (Sidebar):** `NavigationMenuView` bevat een `List(store.bhajans)` — dit is het SwiftUI-equivalent van een `RecyclerView`. Elke rij is een recycleerbaar `MenuRow` view met eigen layout (deity circle, titel, subtitel, tags). De list is `.plain` styled.
- **Detail:** `BhajanDetailView` toont de geselecteerde bhajan.
- **Navigatie:** Bij tap op een bhajan in de lijst wordt `onSelect(bhajan)` aangeroepen, wat de detail view laadt. Op compact width wordt `preferredCompactColumn = .detail` ingesteld zodat de sidebar verdwijnt en de detail view verschijnt. De ingebouwde back-knop (≡) brengt de gebruiker terug naar de sidebar.
- **Master → Detail → Terug:** Volledig ondersteund op beide orientaties.

## Ondersteuning landscape en portrait

De app ondersteunt zowel landscape als portrait mode via een adaptieve layout:

- **Regular width** (iPad landscape/portrait, macOS): `NavigationSplitView` met sidebar + detail kolom side-by-side. De betekenis wordt getoond als trailing overlay (380px breed) naast de bladmuziek via een `.overlay(alignment: .trailing)`.
- **Compact width** (iPhone portrait): `NavigationSplitView` collapsed automatisch naar een push/pop navigatie. De sidebar is full-screen, bij selectie verschijnt de detail view. Een `Picker` met `.segmented` style wisselt tussen muziek en betekenis binnen het detail-paneel.
- **`@Environment(\.horizontalSizeClass)`** wordt gebruikt om adaptief te schakelen tussen de twee layout-modellen.
- **`preferredCompactColumn`** is een `@State` variabele die dynamisch wordt aangepast: bij selectie van een bhajan wordt `.detail` ingesteld (sidebar verdwijnt), bij terug-navigeren wordt `.content` ingesteld (sidebar verschijnt).

## Event handling en navigatie

- **`onTapGesture`** op `MenuRow` items triggert bhajan-selectie.
- **Toolbar button** (book/music icoon) wisselt tussen muziek en betekenis in het detail-paneel.
- **`onClose`** callback op `MeaningPanelView` sluit het betekenis-paneel.
- **`@AppStorage`** persisteert de laatste selectie bij elke tap.
- **Segmented picker** op compact width voor directe wissel tussen muziek en betekenis.

## Resources

De app gebruikt volgende resources:

- **JSON-bestanden:** `meanings/*.json` (5 individuele bestanden, één per bhajan) — bevatten betekenissen met Devanagari, IAST-transliteratie, Nederlandse vertaling en commentaar.
- **XML-bestanden:** `*.xml` MEI-bestanden (5 stuks) — bevatten bladmuziek in Music Encoding Initiative formaat met syllabus-text voor lyrics.
- **SF Symbols:** `music.note.list`, `music.note`, `text.book.closed`, `arrow.left`, `arrow.triangle.2.circlepath`, etc.
- **Verovio JavaScript bundle:** Gecompileerde WebAssembly toolkit in de app-bundle voor SVG-rendering.
- **String Catalogs:** Voor lokalisatie (Nederlandse UI-teksten zoals "Swipe ← om te verbergen", "Geen bhajans gevonden").

## Extra's

### Extra 1: Verovio WebAssembly Integration via WebKit

De app integreert de Verovio C++ music engraving toolkit (gecompileerd naar WebAssembly/JavaScript) binnen een `WKWebView`. Dit is een technologie die niet in het lesmateriaal aan bod komt.

De `VerovioService` laadt de Verovio toolkit vanuit de app-bundle, stelt de resource-path in (`setResourcePath`), en rendert MEI-content naar HTML met ingebedde SVG-bladmuziek. Bij opstarten wordt de bundel automatisch gedetecteerd.

### Extra 2: MEI/XML Parser met XMLParserDelegate

De app implementeert een eigen `MEIParser` die MEI-bestanden (Music Encoding Initiative) parseert via `XMLParserDelegate`. Dit is een eigen parser die metadata extraheert: titel, vertaalde titel, componist en taal. De parser werkt asynchroon met `CheckedContinuation` voor integratie met Swift Concurrency. De interne state wordt bij elke parse-cyclus gereset om accumulatie tussen bestanden te voorkomen.

### Extra 3: Automatische Deity Detection

Een heuristic analyseert bhajan-titels en wijst automatisch de juiste deity toe (Kṛṣṇa, Rāma, Śiva, Guru, Nārāyaṇa, Govinda, Devī). De functie normaliseert titels via `.stripDiacritics` (ś→s, ā→a, ṃ→m) en matcht tegen patronen in Sanskriet, getranslitereerd en Devanagari schrift. De gedetecteerde deity wordt getoond als gekleurde cirkel-badge en tag in de sidebar.

## Extra informatie

### Bekende punten

- WebKit/WebContent sandbox-warnings verschijnen in de console bij het renderen van Verovio SVG. Dit zijn interne WebKit-procesmeldingen die geen invloed hebben op de functionaliteit. De SVG-rendering werkt correct.
- Core Data (`Persistence.swift`) is aanwezig als scaffold maar wordt momenteel niet actief gebruikt — alle data komt uit de MEI/XML bundle en de GitHub JSON-service.
- De app is ontworpen voor de Art of Living gemeenschap en bevat bhajans die typisch gezongen worden tijdens satsangs en meditatie-sessies van Sri Sri Ravi Shankar.
- De `meanings/` folder is gehost op GitHub voor online toegang en lokaal meegeleverd in de app-bundle voor offline gebruik.
