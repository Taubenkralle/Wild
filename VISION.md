# VISION.md — Das Spiel

> Alles was Max über das Spiel gesagt hat. Detailreich. Nichts ausgelassen.
> Diese Datei wächst mit jeder Session.

---

## Die Kernidee

Ein Rollenspiel das sich anfühlt wie **Pokémon Gelb auf dem Game Boy** — simpel, aber mit einem unwiderstehlichen Sog. Eine Welt die einen abholt und theoretisch ewig wachsen kann.

**Keine erfundenen Pokémon — echte Lebewesen dieser Erde.**

Die Mission: **Jedes Lebewesen auf diesem Planeten finden, fangen und in Sicherheit bringen** — bevor es ausstirbt. Kein Zoo, kein Käfig, sondern ein riesiges wissenschaftliches Refugium mit natürlichen Lebensräumen. Jedes Tier glücklich, jedes Tier gerettet.

Das Universum soll **nicht aufhören**. Es soll so gebaut sein, dass es Jahrhunderte weiterwachsen kann.

---

## Story-Kern (Stand Session 1)

**Was wir wissen:**
- Spieler hat einen wissenschaftlichen Hang — Neugier, Entdeckerdrang
- Es gibt einen Companion: Roboter oder wissenschaftlicher Partner (noch offen)
- Ziel: alle Lebewesen fangen, mit ihnen freunden (nicht bezwingen), ins Refugium bringen
- Das Fangen funktioniert nicht mit Gewalt — der Spieler muss herausfinden *wie* man ein Tier fängt
- Das Refugium ist kein Zoo sondern ein riesiger glücklicher Ort — wie Professor Eichs Labor, aber gigantisch

**Was noch offen ist:**
- Der emotionale Auslöser: Warum beginnt diese Mission? Was passiert am Anfang?
- Der Companion: Wer/was ist er genau? Woher kommt er?
- Der erste Antagonist oder die erste große Bedrohung
- Name des Spiels
- Name des Refugiums

---

## Genre & Perspektive

- **Top-Down RPG** — Vogelperspektive wie GTA 1/2, wie alte Pokémon-Spiele
- **Fog of War** — die Welt ist nicht sofort sichtbar, sie enthüllt sich beim Erkunden
- **Setting: Normal, schön, fantasiefördernd** — für Kinder geeignet aber tief genug für Erwachsene
- Postapokalyptisch wurde kurz erwogen aber verworfen — das war nur eine Laune
- Kein düsteres Setting, sondern Wunder, Natur, Wissenschaft, Abenteuer

---

## Spielstart — Die erste Szene

- Klassischer Einstieg: Spieler startet in einem **ersten Dorf**
- Läuft zu einer Figur wie **Professor Eich** — also ein Mentor/Einführungscharakter
- Dann beginnt die Reise
- Die erste spielbare Szene (erstes Dorf, erste Begegnung) soll in der ersten richtigen Arbeitsphase entstehen

---

## Dialoge & Story

- Dialoge funktionieren wie in Pokémon: **Klick — nächster Text — Klick** — klassisches Textbox-System
- Story wird von Max selbst geschrieben, Stück für Stück
- Das Spiel soll **inhaltlich wachsen während Max es spielt** — keine vorgefertigte Welt, sondern eine die entsteht

---

## Der Developer Mode — Das Herzstück

Das ist die zentrale Innovation dieses Projekts:

**Max entwickelt das Spiel, während er es spielt.**

- Während des Spielens kann Max mit einer Taste (Vorschlag: **Y-Taste**) in einen **Developer Mode** wechseln
- Im Developer Mode erscheint der Mauszeiger
- Max kann in der Welt direkt:
  - **Terrain erstellen** (Boden, Wasser, Berge, etc.)
  - **Charaktere platzieren** (NPCs, Gegner, Händler, etc.)
  - **Objekte platzieren** (Bäume, Häuser, Items, etc.)
  - **Dialoge schreiben**
  - **Gebiete benennen und verknüpfen**
- Der Developer Mode ist **unsichtbar für spätere User** — er ist nur für Max als Entwickler
- Aus dem Developer Mode heraus kann Max eine **To-Do-Liste** im Spiel schreiben
- Diese To-Do-Liste wird automatisch als **Markdown-Datei exportiert** — damit Claude beim nächsten echten Code-Sprint weiß was zu tun ist

**Das Ziel**: Max entwickelt sein Spiel in seiner Freizeit, während er entspannt — ohne dass es sich wie Arbeit anfühlt.

---

## Steuerung

- Klassische Spielsteuerung (WASD oder Pfeiltasten)
- **Tastenbelegung ist vollständig anpassbar** — Max will das selbst konfigurieren können
- Steuerungsschema wird im Wiki dokumentiert

---

## Spielmechaniken (Ideen bisher)

- **Tag-Nacht-Zyklus** — Dauer noch festzulegen, wird im Wiki dokumentiert
- **Fog of War** — Welt enthüllt sich beim Erkunden
- Kampfsystem: noch offen, aber Pokémon-artig ist die Referenz
- Kreaturen/Monster: eigene Schöpfungen, kein Pokémon-Klon — Max erfindet die Welt
- Datenbank im Hintergrund: alle Kreaturen, Orte, Items, NPCs — persistent und erweiterbar

---

## Grafik & Ästhetik

- **Kein Pygame** — zu altbacken, kein modernes Look & Feel
- Simpel, aber **wirklich gut aussehend** — Pokémon sieht trotz Simplizität klasse aus, das ist der Maßstab
- Pixel-Art-Ästhetik wahrscheinlich die richtige Richtung — noch nicht final
- Godot wurde als mögliche Engine von Max selbst genannt

---

## Technische Anforderungen

- Läuft lokal auf **Windows und Mac** (Cross-Platform Pflicht)
- **Datenbank im Hintergrund** (SQLite für Phase 1, später erweiterbar)
- Später: **andere Spieler sollen das Spiel spielen können** — Multiplayer/Online muss architektonisch mitgedacht werden
- **GitHub** für Versionskontrolle
- **GitHub Wiki** für Spieldokumentation
- **MEMORY.md** und andere Projektdateien für Claude's Gedächtnis

---

## Das Projekt-Ökosystem

Neben dem eigentlichen Spiel entsteht parallel:

1. **Das Spiel selbst** — spielbar, wachsend
2. **Developer Mode** — integriert ins Spiel
3. **GitHub Repository** — Code, versioniert
4. **GitHub Wiki** — Spielregeln, Mechaniken, Dokumentation
5. **MEMORY.md** — Claude's Gedächtnis, Projektregeln
6. **VISION.md** — diese Datei, wächst mit
7. **To-Do-Markdown-Dateien** — generiert aus dem Developer Mode im Spiel
8. **STARTUP.md** — Anstupsdatei für Claude Code bei jedem Start

---

## Zeitplan / Philosophie

- **Phase 1 (Fünfjahresplan)**: Ein vollständiges, spielbares, wachsendes Spiel
- **Phase 2 (20-25 Jahre)**: Das große Universum
- Tempo: Freizeit-Projekt, kein Stress, aber konsequent
- Entwicklung passiert **während des Spielens** — das ist der Kern

---

## Noch offene Fragen

- Finales Setting: Postapokalyptisch? Fantasy? Hybrid?
- Welche Engine/Framework: Godot? Anderes?
- Kampfsystem: rundenbasiert wie Pokémon? Echtzeit?
- Name des Spiels: noch offen
- Kreaturen: eigene Erfindungen — erste Konzepte kommen von Max

---

*Zuletzt aktualisiert: Erstes Brainstorming-Gespräch, Session 1*
