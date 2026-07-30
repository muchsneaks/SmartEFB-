# Studio Sera — Agentur-Website

Statische Website für **Studio Sera**, eine Creator-Management-Agentur
(Kooperationsanfragen, Verträge/Recht, Steuern & Buchhaltung).
Gestaltung angelehnt an die Bildsprache von tesla.com: vollflächige Panels mit
Scroll-Snap, zentrierte Headline oben, Pill-Buttons unten, minimaler Fixed-Header
mit Slide-in-Menü, viel Weißraum.

Kein Build-Schritt, keine Abhängigkeiten – reines HTML, CSS und Vanilla-JS.

## Seiten

| Datei              | Inhalt |
| ------------------ | ------ |
| `index.html`       | Startseite: sechs vollflächige Panels (Hero, Talents, Kooperationen, Recht, Steuern, Für Marken) plus Kennzahlen, Leistungsüberblick und Abschluss-CTA |
| `talents.html`     | Roster mit Fionaxhlr, Talent-Detail (Formate, Passung, Buchungsablauf), Creator-Bewerbung |
| `leistungen.html`  | Die drei Bereiche im Detail, fünfstufiger Kooperationsablauf, FAQ-Akkordeon |
| `kontakt.html`     | Anfrageformular mit Validierung, vorbelegbar per URL-Parameter |
| `impressum.html`   | Anbieterkennzeichnung (Platzhalter, siehe unten) |
| `datenschutz.html` | Datenschutzerklärung (Platzhalter, siehe unten) |

## Lokal ansehen

```bash
cd studio-sera
python3 -m http.server 8000
# http://localhost:8000
```

Deployen lässt sich der Ordner unverändert auf GitHub Pages, Netlify, Vercel
oder jeden Webspace – es genügt, den Inhalt hochzuladen.

## Vor dem Livegang anpassen

1. **Impressum und Datenschutz** enthalten Platzhalter in eckigen Klammern.
   Beide Seiten mit echten Daten füllen und rechtlich prüfen lassen.
2. **E-Mail-Adresse**: `hallo@studiosera.de` steht in allen Seiten sowie in
   `data-contact-form` (`kontakt.html`). Suchen und ersetzen.
3. **Formular-Backend**: Das Formular validiert im Browser und öffnet dann eine
   fertig ausgefüllte E-Mail (`mailto:`). Für einen echten Endpunkt genügt es,
   in `assets/js/site.js` den `mailto:`-Block durch einen `fetch()`-Aufruf zu
   ersetzen (z. B. Formspree, eigener Server).
4. **Reichweiten und Kennzahlen** auf `talents.html` und der Startseite sind
   bewusst qualitativ gehalten. Wenn echte Zahlen genannt werden sollen, in den
   `.stat-value`-Blöcken eintragen.

## Bilder einsetzen

Die Panel-Hintergründe sind aktuell Farbverläufe mit Grain-Overlay – dadurch
lädt die Seite ohne externe Assets. Für echte Fotos in `assets/css/style.css`
beim jeweiligen Panel das Bild als oberste Ebene ergänzen:

```css
.panel--hero {
  background-image:
    linear-gradient(180deg, rgba(0,0,0,.45) 0%, rgba(0,0,0,.15) 45%, rgba(0,0,0,.55) 100%),
    url("../img/hero.jpg");
}
```

Der Verlauf davor hält den Text lesbar. Dasselbe gilt für die Talent-Kacheln
(`.talent--sera-1` usw.), die ein Hochformat im Verhältnis 3:4 erwarten.

## Technische Details

- Panels nutzen `scroll-snap-type: y proximity` (nur auf der Startseite, `<body class="snap">`).
- Der Header wechselt die Schriftfarbe abhängig vom Panel darunter
  (`data-header-tone` + IntersectionObserver) und bekommt beim Scrollen einen
  Blur-Hintergrund.
- Reveal-Animationen laufen über `data-reveal`, gestaffelt per `--delay`.
- `prefers-reduced-motion` schaltet Animationen und Scroll-Snap ab.
- Menü mit Fokus-Falle, `Escape`-Schließen und `aria-expanded`.
- Die Schrift (Montserrat, Variable Font, SIL OFL 1.1) liegt unter `assets/fonts/`
  und wird lokal ausgeliefert – keine Verbindung zu Google Fonts, kein CDN.
  Die Seite lädt damit vollständig ohne externe Requests.

## Hinweis zu Recht und Steuern

Rechtsberatung (RDG) und Hilfeleistung in Steuersachen (StBerG) sind in
Deutschland lizenzierten Berufsträger:innen vorbehalten. Die Texte formulieren
diese Leistungen daher als **Organisation, Aufbereitung und Koordination mit
Partnerkanzleien**; auf `leistungen.html` und im Footer steht ein entsprechender
Hinweis. Wenn stattdessen mit eigener Beratung geworben werden soll, ist vorher
die Zulässigkeit zu klären.
