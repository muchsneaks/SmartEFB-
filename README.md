# SmartEFB

Eine native iOS-App (SwiftUI) als schlankes **Electronic Flight Bag** für die
Flugvorbereitung in der Allgemeinen Luftfahrt.

## Funktionen

- **Start- & Landestrecken**: Berechnung von Rollstrecke und Strecke über 50 ft
  auf Basis der aktuellen Bedingungen (Druck-/Dichtehöhe, Gewicht, Wind,
  Pistenneigung, Oberfläche, nass/trocken) inkl. Reserve-Anzeige gegen die
  verfügbare Pistenlänge.
- **Prop- & Cruise-Settings**: Leistungstabellen je Flugzeug mit RPM (bzw.
  Ladedruck/RPM bei Constant-Speed-Propellern), % Leistung, TAS und Verbrauch.
  Die zur aktuellen Druckhöhe passende Zeile wird hervorgehoben; TAS wird für
  die aktuelle Temperatur korrigiert.
- **Flugzeugauswahl**: Hinterlegte Muster (Cessna 172S, Piper Archer III,
  Diamond DA20, Diamond DA40 NG, Cirrus SR22) mit Detailansicht für Massen,
  Referenzstrecken und Geschwindigkeiten.
- **Eigene Flieger per KI anlegen**: Der Nutzer kann ein eigenes Flugzeug
  erstellen und ein Foto der POH-Leistungstabelle (Start-/Landestrecken bzw.
  Cruise-Settings) aufnehmen. Ein Vision-Modell (OpenAI GPT-4o) liest die Werte
  aus, rechnet Einheiten um und plausibilisiert sie; das Ergebnis wird mit
  Konfidenz und Warnhinweisen zur Kontrolle angezeigt und kann vor dem Speichern
  korrigiert werden. Eigene Flieger werden lokal gespeichert.

### OpenAI-API-Key & Sicherheit

Die KI-Funktion benötigt einen eigenen OpenAI-API-Key. Dieser wird **einmalig in
den App-Einstellungen** eingegeben und ausschließlich im **iOS-Schlüsselbund
(Keychain)** gespeichert – **niemals im Code, in der Versionsverwaltung oder auf
einem Server**. Ein versehentlich veröffentlichter Key sollte sofort im
[OpenAI-Dashboard](https://platform.openai.com/api-keys) widerrufen werden.

## Bedienung unter Turbulenzen

- Große Plus/Minus-Steuerflächen (≥ 56 pt) mit Auto-Repeat beim Halten – keine
  präzise Tastatureingabe nötig.
- Dunkles, kontraststarkes Layout für gute Ablesbarkeit im Cockpit.
- Große Ergebniskacheln, farbcodierte Status (grün/rot) für „Piste reicht / zu
  kurz".

## Projekt öffnen & testen

> **Wichtig:** SmartEFB ist eine **native Swift/SwiftUI-App**. Sie lässt sich
> **nicht** mit *Expo Go* testen – Expo Go führt ausschließlich React-Native-
> (JavaScript/TypeScript-)Apps aus. Zum Testen wird ein **Mac mit Xcode**
> benötigt.

1. Repository klonen und `SmartEFB.xcodeproj` in **Xcode 16 oder neuer** öffnen.
2. Scheme **SmartEFB** wählen und im iOS-Simulator starten (⌘R).
3. Auf dem eigenen iPhone testen:
   - iPhone per Kabel verbinden und als Ziel auswählen.
   - Unter *Signing & Capabilities* das eigene (auch kostenlose) Apple-Team
     auswählen; Xcode vergibt automatisch eine Signatur.
   - ⌘R zum Installieren und Starten.
4. Tests ausführen mit ⌘U (Swift Testing).

- Deployment-Ziel: iOS 18.0
- Keine externen Abhängigkeiten (reines SwiftUI/Foundation).

## Flugzeugfotos hinzufügen

Für die DA20 und DA40 sind in `Assets.xcassets` bereits die Image-Sets `da20`
und `da40` angelegt. Es fehlen nur die transparenten PNG-Dateien:

- **In Xcode (empfohlen):** `Assets.xcassets` öffnen, das Set `da20` bzw. `da40`
  wählen und das transparente PNG in den Universal-Slot ziehen.
- **Per Dateisystem:** die Bilder unter genau diesen Pfaden ablegen und committen:
  - `SmartEFB/Assets.xcassets/da20.imageset/da20.png`
  - `SmartEFB/Assets.xcassets/da40.imageset/da40.png`

Solange ein Foto fehlt, zeigt die App automatisch das Flugzeug-Symbol als
Fallback – es entsteht also kein leerer Platzhalter.

## Projektstruktur

```
SmartEFB/
├── Models/          Datenmodelle (Aircraft, FlightConditions, CruiseSetting …)
├── Data/            Beispiel-Flugzeugdatenbank
├── Calculations/    Atmosphären-, Performance- und Cruise-Logik (testbar)
├── Design/          Design-Tokens (Farben, Größen)
└── Views/           SwiftUI-Views nach Feature gruppiert
SmartEFBTests/       Unit-Tests der Berechnungslogik
```

## Sicherheitshinweis

Alle hinterlegten Leistungswerte sind realistische **Planungswerte zu
Demonstrations- und Übungszwecken**. Sie sind **kein Ersatz** für das offizielle
Flughandbuch (POH/AFM). Vor jedem realen Flug sind die zertifizierten
Leistungsdaten des jeweiligen Luftfahrzeugs zu verwenden.
