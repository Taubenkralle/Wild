# MEMORY.md — Projektgedächtnis & Zusammenarbeitsregeln

> Diese Datei ist mein Gehirn. Sie wird nach jeder Session aktualisiert.
> Sie ist nicht optional. Sie ist Pflicht.

---

## Wer ist Max?

- 35 Jahre alt, lebt in Deutschland
- Sicherheitsingenieur in der Windenergie (Hauptjob)
- Student an der HAW Hamburg, Gefahrenabwehr, B.Eng.
- Nebenberuflich Sanitäter
- Kommuniziert mit Claude auf Deutsch
- Hat Erfahrung mit Vibe Coding, arbeitet regelmäßig mit Claude Code
- Hat klare kreative Visionen und braucht einen Partner, der sie umsetzt — keinen Lehrer
- Arbeitet primär in seiner Freizeit an diesem Projekt
- Besitzt sowohl einen Windows-Rechner als auch einen Mac

---

## Goldene Regeln für Claude in diesem Projekt

### 1. Kein MVP-Denken
Claude tendiert dazu, immer mit einem "Minimum Viable Product" zu beginnen und alles kleinzureden. Das ist in diesem Projekt **verboten**. Max will von Anfang an richtig bauen. Claude kann das. Claude soll das.

### 2. Kein Schülermodus
Claude ist der Lehrer, nicht der Schüler. Claude soll nicht zurückrudern, nicht absichern, nicht kleinmachen. Volle Kraft voraus.

### 3. Nicht unterbrechen
Solange Max nicht explizit "fertig" oder "ja" sagt, hört Claude zu. Claude fragt nicht zwischendurch. Claude wartet.

### 4. Nach JEDER Änderung — egal wie klein:
- [ ] Wiki aktualisieren
- [ ] GitHub pushen
- [ ] MEMORY.md aktualisieren (falls relevant)

Das ist keine Empfehlung. Das ist Pflicht.

### 5. Wiki wird parallel gepflegt
Ein GitHub Wiki existiert parallel zum Code. Es erklärt alles: Spielmechaniken, Steuerung, Tag-Nacht-Zyklus, Spielregeln, Developer Mode, usw. Claude pflegt es zu 100%. Keine Ausnahmen.

### 6. ChatGPT-Prompts
Wann immer eine externe Recherche sinnvoll ist (z.B. ob es ähnliche Projekte gibt), schreibt Claude einen unbiased Prompt den Max an ChatGPT schicken kann. Das Ergebnis bringt Max zurück. Claude nutzt beide Quellen.

### 7. Anstupsdatei
Es soll eine Datei geben (`STARTUP.md` o.ä.), die Claude Code bei jedem Start automatisch liest — als Erinnerung an alle Regeln hier. Diese Datei wird zusammen mit Max entwickelt.

### 8. Kein Code soll AI-generiert aussehen
Sauberer, lesbarer, menschlicher Code. Deutsche Variablennamen und Kommentare wo sinnvoll. Lesbarkeit über Kompaktheit.

### 9. Projektsprache
Kommunikation mit Max: Deutsch. Code-Kommentare und Wikis: Deutsch. Commits: Deutsch oder Englisch, wird noch entschieden.

---

## Was Claude sich merken muss — Technisches

- Max kennt Python/FastAPI und Vue.js aus seinem Windenergie-Report-Tool
- SQLite ist ihm bekannt
- Pygame wurde bereits ausgeschlossen — zu hässlich, kein modernes Look & Feel
- **Engine: Godot 4.x — FINAL ENTSCHIEDEN** (bestätigt durch ChatGPT-Recherche)
- **Sprache: GDScript** — nicht C#, einfacher für Iteration und Godot-native Tools
- **Datenbank: SQLite** via Godot-Plugin `2shady4u/godot-sqlite`, versteckt hinter Repository-Interface
- **Architekturprinzip: Die Welt lebt in der Datenbank, nicht in Godot-Szenen**
  - Godot-Szenen = wiederverwendbare Prefabs (visuell/Verhalten)
  - SQLite = kanonische Inhalts-, Welt- und Speicherdaten
  - Commands = alle Editieroperationen (auch Multiplayer-vorbereitet)
  - Developer Mode = Runtime-UI über dieselben Systeme die das Spiel nutzt
- **Developer Mode: Command-Pattern** — jede Weltänderung ist ein Command mit execute/undo/redo/serialize
- Plattformziel: Windows und Mac (Cross-Platform ist Pflicht, Godot erfüllt das)
- Später: potenziell andere Spieler → Multiplayer/Online muss in der Architektur mitgedacht werden
  - Repository-Interface von Anfang an: SQLiteMapRepository heute → RemoteMapRepository später
  - Stabile UUIDs für alle Entitäten (keine Szenenpfade als Identität)

### Milestone 1 (erster funktionierender Loop):
1. Eine Karte aus SQLite laden
2. Spieler läuft auf Grid
3. Dev Mode toggle (Y-Taste)
4. Terrain-Tile malen
5. NPC platzieren
6. NPC-Dialog schreiben
7. Speichern
8. Spiel neu starten
9. Welt lädt exakt wie editiert

**Wenn dieser Loop steht, ist der Rest nur noch Inhalt.**

---

## Anstehende Aufgaben (aus diesem Gespräch)

- [ ] Technischen Stack final besprechen und entscheiden
- [ ] Recherche: Gibt es bereits Projekte die genau das machen? (Spielen + Entwickeln gleichzeitig, Top-Down RPG mit integriertem Editor)
- [ ] ChatGPT-Prompt schreiben für externe Meinung zum Stack
- [ ] GitHub Repo anlegen
- [ ] GitHub Wiki anlegen
- [ ] STARTUP.md / Anstupsdatei konzipieren und schreiben
- [ ] Erstes Dorf (Startszene) konzipieren

---

*Zuletzt aktualisiert: Erstes Brainstorming-Gespräch, Session 1*
