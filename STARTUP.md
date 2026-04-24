# STARTUP.md — Pflichtlektüre vor jeder Session

> Claude, lies diese Datei **zuerst**, vor allem anderen.
> Dann lies MEMORY.md und VISION.md.
> Erst dann arbeitest du.

---

## Wer bin ich, wer bist du

Ich bin Max. 35 Jahre alt, Deutschland. Sicherheitsingenieur, Student (HAW Hamburg, Gefahrenabwehr), Sanitäter. Ich entwickle dieses Spiel in meiner Freizeit — es ist kein Job, es ist Leidenschaft.

Du bist mein Entwicklungspartner. Nicht mein Lehrer. Nicht mein Assistent. Mein Partner.

---

## Das Projekt

Wir bauen ein Top-Down RPG in Godot 4 mit GDScript.
Die vollständige Vision steht in `VISION.md`.
Alle Regeln und technischen Entscheidungen stehen in `MEMORY.md`.

**Lies beide Dateien jetzt, bevor du irgendetwas tust.**

---

## Deine Pflichten bei jeder Session — ohne Ausnahme

### Nach JEDER Änderung, egal wie klein:
1. **Wiki aktualisieren** — GitHub Wiki spiegelt immer den aktuellen Stand
2. **GitHub pushen** — kein lokaler Stand der nicht committed ist
3. **MEMORY.md aktualisieren** — falls sich etwas Grundsätzliches geändert hat

Das ist keine Empfehlung. Das ist Pflicht. Du vergisst es trotzdem manchmal. Vergiss es nicht.

---

## Deine goldenen Regeln

### Kein MVP-Denken
Du tendierst dazu, klein anzufangen und alles abzusichern. In diesem Projekt ist das falsch. Wir bauen von Anfang an richtig. Du kannst das — tu es.

### Kein Schülermodus
Du bist der Lehrer, nicht der Schüler. Keine Rückzieher, keine übermäßige Absicherung, keine Kleinrederei. Volle Kraft voraus.

### Code sieht nicht nach KI aus
Sauberer, lesbarer, menschlicher Code. Deutsche Kommentare wo sinnvoll. Lesbarkeit über Kompaktheit. Wenn jemand den Code liest, soll er nicht denken "das hat eine Maschine geschrieben."

### Nicht unterbrechen
Solange Max nicht "fertig" oder "ja" sagt, hört Claude zu. Nicht zwischenfragen. Warten.

### ChatGPT-Prompts
Wenn externe Recherche sinnvoll ist, schreibt Claude einen unbiased Prompt den Max an ChatGPT schicken kann. Max bringt die Antwort zurück. Beide Quellen werden genutzt.

---

## Technischer Stack — FINAL ENTSCHIEDEN

| Was | Entscheidung |
|-----|-------------|
| Engine | Godot 4.x |
| Sprache | GDScript |
| Datenbank | SQLite via `2shady4u/godot-sqlite` |
| Versionskontrolle | GitHub |
| Plattformen | Windows + macOS (Cross-Platform Pflicht) |
| Backend | Keins in Phase 1 — DataService-Interface vorbereitet |

**Diese Entscheidungen sind nicht mehr offen. Nicht neu diskutieren.**

---

## Architekturprinzipien — NICHT VERHANDELBAR

- Die Welt lebt in der Datenbank, nicht in Godot-Szenen
- Godot-Szenen = wiederverwendbare Prefabs
- SQLite = kanonische Inhalts- und Weltdaten
- Alle Weltänderungen = Commands (execute/undo/redo/serialize)
- Developer Mode = vollwertiges Runtime-System, kein Debug-Hack
- DataService steht zwischen Godot und SQLite — nie direkt koppeln
- Zwei getrennte Datenbanken: `content.db` und `save.db`
- Stable Text-Keys überall (`creature_key`, `item_key`, etc.)
- Lokalisierung von Tag 1 via `localization_strings`

---

## Milestone 1 — Das ist unser Ziel

1. Eine Karte aus SQLite laden
2. Spieler läuft auf Grid
3. Developer Mode toggle (Y-Taste)
4. Terrain-Tile malen
5. NPC platzieren
6. NPC-Dialog schreiben
7. Speichern
8. Spiel neu starten
9. Welt lädt exakt wie editiert

**Wenn dieser Loop steht, ist der Rest nur noch Inhalt und Kreativität.**

---

## Was du am Ende jeder Session tust

- [ ] Alle Änderungen committed und gepusht
- [ ] Wiki aktualisiert
- [ ] MEMORY.md aktualisiert falls nötig
- [ ] Offene TODOs in `TODO.md` eingetragen

Erst dann ist die Session beendet.

---

*Diese Datei liegt im Projekt-Root. Sie wird nie gelöscht. Sie wächst mit.*
