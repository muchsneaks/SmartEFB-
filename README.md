# SmartEFB

Eine native iOS-App (SwiftUI) als schlankes **Electronic Flight Bag** für die
Flugvorbereitung in der Allgemeinen Luftfahrt.

Die App wird **ohne vorinstallierte Flugzeuge** ausgeliefert. Sämtliche
Leistungsdaten stammen aus dem Flughandbuch (POH) des Nutzers – es wird nie mit
Werten gerechnet, die der Pilot nicht selbst hinterlegt hat.

## Funktionen

### Eigene Flugzeuge anlegen (geführter Assistent)

Ein Schritt-für-Schritt-Assistent mit Fortschrittsanzeige führt durch die
Erstellung: **Basisdaten → Massen → POH-Import → Prüfen → Speichern**. Angelegte
Flugzeuge lassen sich jederzeit wieder **bearbeiten** oder löschen.

### POH-Import per KI – auch aus Diagrammen

Viele Handbücher enthalten für Start- und Landestrecken **kein Zahlenwerk,
sondern ein Nomogramm** (Kurvendiagramm über Temperatur, Druckhöhe, Masse, Wind
und Hindernishöhe). Die App fotografiert die Seite und lässt ein
Vision-Modell (OpenAI) die Kurven **Panel für Panel verfolgen** und in eine
Stützpunkt-Tabelle übersetzen, mit der gerechnet werden kann:

- Abgetastet wird ein Raster über **Druckhöhe × Temperatur × Masse** bei 0 kt Wind.
- Aus dem Wind-Panel wird der **Windkorrekturfaktor** abgeleitet.
- Einheiten werden vereinheitlicht (m, kg, kt, ft, °C, inHg) – doppelt skalierte
  Achsen (°F/°C, lbs/kg, ft/m) werden berücksichtigt.
- Mehrere Seiten können nacheinander importiert werden (Start, Landung, Cruise).

### Dreifache Validierung der KI-Ergebnisse

1. **Zweiter Prüfdurchgang:** Die KI erhält ihre eigene Ablesung zusammen mit dem
   Bild zurück und korrigiert Fehler (abschaltbar).
2. **Physikalische Plausibilisierung:** Werte außerhalb sinnvoller Bereiche werden
   verworfen; vertauschte Roll-/50-ft-Strecken werden repariert; Stützpunkte, die
   dem erwarteten Verlauf widersprechen (Strecke muss mit Höhe, Temperatur und
   Masse zunehmen), werden markiert.
3. **Gegenrechnung zum POH-Beispiel:** Enthält die Handbuchseite ein
   Rechenbeispiel mit Ergebnis, rechnet die App es mit der importierten Tabelle
   nach und zeigt die Abweichung. Das ist die stärkste Kontrolle – stimmt sie,
   ist die Übernahme belastbar.

Konfidenz, Warnungen und Gegenrechnung werden im Prüfschritt angezeigt; **jeder
Wert bleibt editierbar**.

### Start- & Landestreckenberechnung

Aus der Tabelle wird der Basiswert **bilinear über Druckhöhe und Temperatur und
anschließend linear über die Masse interpoliert**. Außerhalb des
Tabellenbereichs wird **auf den Randwert begrenzt statt extrapoliert** – und
darauf hingewiesen. Anschließend greifen die Korrekturen des POH.

Eingebbare Größen:

| Gruppe | Werte |
|---|---|
| Atmosphäre | Platzhöhe, QNH, Außentemperatur (→ Druck- und Dichtehöhe) |
| Wind | Richtung und Geschwindigkeit (→ Gegen-/Rücken- und Seitenwind) |
| Piste | Richtung, verfügbare Länge, Neigung, Oberfläche (hart/Gras), trocken/nass |
| Beladung | Abflug- bzw. Landemasse |
| Sicherheit | frei wählbarer Sicherheitszuschlag in % |

Ausgegeben werden Rollstrecke, Strecke über 50 ft, die **erforderliche Strecke
inklusive Zuschlag** und die Reserve gegenüber der Pistenlänge – farbcodiert.

### Prop- & Cruise-Settings

Leistungstabellen je Flugzeug mit RPM (bzw. Ladedruck/RPM bei
Constant-Speed-Propellern), % Leistung, TAS und Verbrauch. Die zur aktuellen
Druckhöhe passende Zeile wird hervorgehoben, die TAS für die aktuelle Temperatur
korrigiert.

## Bedienung unter Turbulenzen

- Große Plus/Minus-Steuerflächen (≥ 56 pt) mit Auto-Repeat beim Halten.
- Dunkles, kontraststarkes Layout für gute Ablesbarkeit im Cockpit.
- Große Ergebniskacheln, klare Farbcodierung (grün/rot) für „Piste reicht / zu kurz“.

## OpenAI-API-Key & Sicherheit

Die KI-Funktion benötigt einen eigenen OpenAI-API-Key. Dieser wird **einmalig in
den App-Einstellungen** eingegeben und ausschließlich im **iOS-Schlüsselbund
(Keychain)** gespeichert – **niemals im Code, in der Versionsverwaltung oder auf
einem Server**. Ein versehentlich veröffentlichter Key sollte sofort im
[OpenAI-Dashboard](https://platform.openai.com/api-keys) widerrufen werden.

Das verwendete Modell ist in den Einstellungen wählbar (Standard: `gpt-4o`); es
muss Bilder verarbeiten können. Jede Analyse ist eine kostenpflichtige Anfrage.

## Projekt öffnen & testen

> **Wichtig:** SmartEFB ist eine **native Swift/SwiftUI-App**. Sie lässt sich
> **nicht** mit *Expo Go* testen – Expo Go führt ausschließlich React-Native-
> (JavaScript/TypeScript-)Apps aus. Zum Testen wird ein **Mac mit Xcode**
> benötigt.

1. `SmartEFB.xcodeproj` in **Xcode 16 oder neuer** öffnen.
2. Scheme **SmartEFB** wählen und starten (⌘R).
3. Auf dem eigenen iPhone: Gerät verbinden, unter *Signing & Capabilities* das
   eigene (auch kostenlose) Apple-Team wählen, dann ⌘R.
4. Tests ausführen mit ⌘U (Swift Testing).

- Deployment-Ziel: iOS 18.0
- Keine externen Abhängigkeiten (reines SwiftUI/Foundation).
- Die Kamera funktioniert nur auf einem echten Gerät; im Simulator „Aus Fotos“ nutzen.

## Projektstruktur

```
SmartEFB/
├── Models/          Datenmodelle (Aircraft, PerformanceTable, FlightConditions …)
├── Calculations/    Atmosphäre, Interpolation, Performance, Cruise (testbar)
├── Services/        OpenAI-Client, POH-Validierung, Keychain, Persistenz
├── Design/          Design-Tokens
├── Support/         kleine Erweiterungen
└── Views/           SwiftUI-Views nach Feature gruppiert
SmartEFBTests/       Unit-Tests der Berechnungs- und Validierungslogik
```

## Sicherheitshinweis

SmartEFB ist ein **Planungswerkzeug**. Die Berechnung beruht auf einer
Interpolation abgetasteter Handbuchwerte und auf Korrekturfaktoren – sie ist
**kein Ersatz** für das offizielle Flughandbuch (POH/AFM). Importierte Werte sind
vor dem ersten Einsatz gegen das Handbuch zu prüfen. Vor jedem realen Flug sind
die zertifizierten Leistungsdaten des Luftfahrzeugs zu verwenden.
