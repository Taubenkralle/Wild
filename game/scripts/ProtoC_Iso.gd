extends Node2D

# =============================================================================
#  PROTO C — Isometrisch (Project-Zomboid-Stil)
#  Grid-Bewegung | Isometrische Projektion | Tiefensortierung
# =============================================================================

# Isometrische Kachelmaße
const ISO_BREITE := 96    # Pixel — Breite eines Iso-Diamonds
const ISO_HOEHE  := 48    # Pixel — Höhe eines Iso-Diamonds (2:1 Ratio)

const KARTE_BREITE := 16
const KARTE_HOEHE  := 12

const GRAS    := 0
const WASSER  := 1
const WEG     := 2
const BAUM    := 3
const BODEN   := 4    # Steinboden / Innenboden

const KARTE := [
	[3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3],
	[3,0,0,0,0,3,0,0,0,0,0,0,0,0,0,3],
	[3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3],
	[3,0,0,4,4,4,4,0,0,1,1,1,0,0,0,3],
	[3,0,0,4,4,4,4,0,1,1,1,1,1,0,0,3],
	[3,0,0,4,4,4,4,0,0,1,1,1,0,0,0,3],
	[3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3],
	[3,0,0,0,2,0,0,0,0,0,0,0,3,0,0,3],
	[3,0,3,0,2,0,0,0,0,0,0,0,0,0,0,3],
	[3,0,0,0,2,0,0,0,3,0,0,0,0,0,0,3],
	[3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3],
	[3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3],
]

# Bäume als separate Objekte mit Y-Sort
const BAUM_POSITIONEN: Array[Vector2i] = []  # wird in _ready gefüllt

# Spieler
var spieler_kachel   := Vector2i(7, 6)
var spieler_richtung := Vector2i(0, 1)
var bewegungs_timer  := 0.0
const SCHRITT_DELAY  := 0.16

# Tiere
var tiere: Array = [
	{"kachel": Vector2i(11, 4), "typ": "Reh",  "richtung": Vector2i(0,1), "timer": 0.5},
	{"kachel": Vector2i(6,  9), "typ": "Hase", "richtung": Vector2i(1,0), "timer": 1.2},
]

var zeit := 0.0
var kamera: Camera2D


func _ready() -> void:
	kamera = Camera2D.new()
	kamera.position = _kachel_zu_iso(spieler_kachel)
	add_child(kamera)

	var hud := CanvasLayer.new()
	add_child(hud)
	var label := Label.new()
	label.text = "Proto C — Isometrisch (Zomboid-Stil)  |  Pfeiltasten bewegen"
	label.position = Vector2(16, 12)
	label.add_theme_font_size_override("font_size", 15)
	label.modulate = Color(1, 1, 1, 0.80)
	hud.add_child(label)


func _process(delta: float) -> void:
	zeit += delta
	_verarbeite_eingabe(delta)
	_aktualisiere_tiere(delta)
	kamera.position = kamera.position.lerp(_kachel_zu_iso(spieler_kachel), 0.14)
	queue_redraw()


func _verarbeite_eingabe(delta: float) -> void:
	bewegungs_timer = maxf(0.0, bewegungs_timer - delta)
	if bewegungs_timer > 0.0:
		return

	var richtung := Vector2i.ZERO
	if Input.is_action_pressed("ui_right"):  richtung = Vector2i(1, 0)
	elif Input.is_action_pressed("ui_left"): richtung = Vector2i(-1, 0)
	elif Input.is_action_pressed("ui_down"): richtung = Vector2i(0, 1)
	elif Input.is_action_pressed("ui_up"):   richtung = Vector2i(0, -1)

	if richtung == Vector2i.ZERO:
		return

	spieler_richtung = richtung
	var neue := spieler_kachel + richtung
	if _ist_begehbar(neue):
		spieler_kachel = neue
		bewegungs_timer = SCHRITT_DELAY


func _aktualisiere_tiere(delta: float) -> void:
	for tier: Dictionary in tiere:
		tier["timer"] = float(tier["timer"]) - delta
		if float(tier["timer"]) > 0.0:
			continue
		tier["timer"] = randf_range(1.5, 3.0)
		var optionen := [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
		optionen.shuffle()
		for r: Vector2i in optionen:
			var neue: Vector2i = tier["kachel"] + r
			if _ist_begehbar(neue) and neue != spieler_kachel:
				tier["kachel"] = neue
				tier["richtung"] = r
				break


func _ist_begehbar(k: Vector2i) -> bool:
	if k.x < 0 or k.x >= KARTE_BREITE or k.y < 0 or k.y >= KARTE_HOEHE:
		return false
	var typ: int = KARTE[k.y][k.x]
	return typ != BAUM and typ != WASSER


# =============================================================================
#  Isometrische Koordinaten-Transformation
# =============================================================================

func _kachel_zu_iso(k: Vector2i) -> Vector2:
	# Standard-Isometrie: Kachel (x,y) → Bildschirm
	var hb := float(ISO_BREITE) * 0.5
	var hh := float(ISO_HOEHE) * 0.5
	return Vector2(
		float(k.x - k.y) * hb,
		float(k.x + k.y) * hh
	)


func _kachel_zu_iso_f(k: Vector2) -> Vector2:
	var hb := float(ISO_BREITE) * 0.5
	var hh := float(ISO_HOEHE) * 0.5
	return Vector2((k.x - k.y) * hb, (k.x + k.y) * hh)


# Diamond-Eckpunkte einer Kachel
func _iso_diamond(k: Vector2i) -> PackedVector2Array:
	var mitte := _kachel_zu_iso(k)
	var hb := float(ISO_BREITE) * 0.5
	var hh := float(ISO_HOEHE) * 0.5
	return PackedVector2Array([
		Vector2(mitte.x,      mitte.y - hh),   # oben
		Vector2(mitte.x + hb, mitte.y),         # rechts
		Vector2(mitte.x,      mitte.y + hh),   # unten
		Vector2(mitte.x - hb, mitte.y),         # links
	])


# =============================================================================
#  ZEICHNEN
# =============================================================================

func _draw() -> void:
	# Isometrisch muss in der richtigen Reihenfolge gezeichnet werden:
	# Kacheln von oben-links nach unten-rechts (Painter's Algorithm)
	_zeichne_alle_kacheln()
	_zeichne_objekte_sortiert()


func _zeichne_alle_kacheln() -> void:
	# Painter's Algorithm: x+y aufsteigend
	for diag in range(KARTE_BREITE + KARTE_HOEHE - 1):
		for x in KARTE_BREITE:
			var y := diag - x
			if y < 0 or y >= KARTE_HOEHE:
				continue
			_zeichne_iso_kachel(Vector2i(x, y))


func _zeichne_iso_kachel(k: Vector2i) -> void:
	var typ: int = KARTE[k.y][k.x]
	var diamond := _iso_diamond(k)
	var mitte := _kachel_zu_iso(k)
	var hb := float(ISO_BREITE) * 0.5
	var hh := float(ISO_HOEHE) * 0.5

	# Variation per Kachel
	var v := sin(float(k.x * 17 + k.y * 11)) * 0.025

	match typ:
		GRAS, BAUM:
			# Deckfläche (Draufsicht)
			draw_colored_polygon(diamond, Color(0.26+v, 0.63+v, 0.19))
			# Linke Seite (Westfläche, dunkler)
			draw_colored_polygon(PackedVector2Array([
				diamond[3], diamond[2],
				Vector2(mitte.x - hb, mitte.y + hh * 0.6),
				Vector2(mitte.x, mitte.y + hh * 1.6),
			]), Color(0.18+v, 0.45+v, 0.13))
			# Rechte Seite (Ostfläche, mittel)
			draw_colored_polygon(PackedVector2Array([
				diamond[1], diamond[2],
				Vector2(mitte.x, mitte.y + hh * 1.6),
				Vector2(mitte.x + hb, mitte.y + hh * 0.6),
			]), Color(0.22+v, 0.52+v, 0.15))

		WASSER:
			# Wasser etwas tiefer — keine Seitenflächen
			var wasser_diamond := PackedVector2Array([
				Vector2(mitte.x,      mitte.y - hh * 0.7),
				Vector2(mitte.x + hb*0.95, mitte.y * 0.0 + mitte.y + hh*0.0 - hh*0.0 + hh*0.0),
				Vector2(mitte.x,      mitte.y + hh * 0.7),
				Vector2(mitte.x - hb*0.95, mitte.y),
			])
			# Einfacher: normaler Diamond in blau
			draw_colored_polygon(diamond, Color(0.14, 0.36, 0.82))
			# Wellenlinie
			var welle_y := mitte.y + sin(mitte.x * 0.08 + zeit * 1.8) * 3.0
			draw_line(
				Vector2(mitte.x - hb*0.5, welle_y - hh*0.1),
				Vector2(mitte.x + hb*0.5, welle_y + hh*0.1),
				Color(0.38, 0.62, 0.96, 0.60), 1.5
			)

		WEG:
			draw_colored_polygon(diamond, Color(0.65, 0.54, 0.37))
			# Leicht aufgehellte Mitte
			var inner := PackedVector2Array([
				Vector2(mitte.x,         mitte.y - hh*0.55),
				Vector2(mitte.x + hb*0.5, mitte.y),
				Vector2(mitte.x,         mitte.y + hh*0.55),
				Vector2(mitte.x - hb*0.5, mitte.y),
			])
			draw_colored_polygon(inner, Color(0.70, 0.59, 0.42))

		BODEN:
			# Steinboden — helle Platten
			draw_colored_polygon(diamond, Color(0.70, 0.68, 0.65))
			# Plattenfuge
			draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]),
						  Color(0.55, 0.53, 0.50, 0.60), 1.0)
			# Linke und rechte Seite (gibt Tiefengefühl — Block-Look wie Zomboid)
			var tiefe := hh * 0.5
			draw_colored_polygon(PackedVector2Array([
				diamond[3], diamond[2],
				Vector2(mitte.x - hb, mitte.y + tiefe),
				Vector2(mitte.x, mitte.y + hh + tiefe),
			]), Color(0.50, 0.48, 0.46))
			draw_colored_polygon(PackedVector2Array([
				diamond[1], diamond[2],
				Vector2(mitte.x, mitte.y + hh + tiefe),
				Vector2(mitte.x + hb, mitte.y + tiefe),
			]), Color(0.58, 0.56, 0.54))

	# Umriss (sehr dezent)
	draw_polyline(
		PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]),
		Color(0.0, 0.0, 0.0, 0.12), 1.0
	)


func _zeichne_objekte_sortiert() -> void:
	# Alle Objekte (Bäume, Tiere, Spieler) nach Y-Kachel sortiert zeichnen
	# Einfache Sortierung: Objekte mit kleinerem (x+y) werden zuerst gezeichnet
	var objekte: Array = []

	# Bäume
	for y in KARTE_HOEHE:
		for x in KARTE_BREITE:
			if KARTE[y][x] == BAUM:
				objekte.append({"sort": x + y, "typ": "baum", "kachel": Vector2i(x, y)})

	# Tiere
	for tier: Dictionary in tiere:
		var k: Vector2i = tier["kachel"]
		objekte.append({"sort": k.x + k.y, "typ": "tier", "data": tier})

	# Spieler
	objekte.append({"sort": spieler_kachel.x + spieler_kachel.y, "typ": "spieler"})

	# Sortieren
	objekte.sort_custom(func(a, b): return int(a["sort"]) < int(b["sort"]))

	for obj: Dictionary in objekte:
		match str(obj["typ"]):
			"baum":    _zeichne_iso_baum(obj["kachel"])
			"tier":    _zeichne_iso_tier(obj["data"])
			"spieler": _zeichne_iso_spieler()


func _zeichne_iso_baum(k: Vector2i) -> void:
	var mitte := _kachel_zu_iso(k)
	var hb := float(ISO_BREITE) * 0.5
	var hh := float(ISO_HOEHE) * 0.5

	# Stamm — isometrischer Block
	var stamm_breite := hb * 0.22
	var stamm_hoehe  := hh * 2.2
	# Stamm als kleiner Block: Vorderseite, linke Seite, Oberseite
	var sx := mitte.x
	var sy := mitte.y + hh * 0.2

	draw_colored_polygon(PackedVector2Array([   # Vorderseite rechts
		Vector2(sx, sy - hh*0.15),
		Vector2(sx + stamm_breite, sy - hh*0.08),
		Vector2(sx + stamm_breite, sy + stamm_hoehe*0.7),
		Vector2(sx, sy + stamm_hoehe*0.7 - hh*0.08),
	]), Color(0.52, 0.33, 0.15))
	draw_colored_polygon(PackedVector2Array([   # Vorderseite links
		Vector2(sx - stamm_breite, sy - hh*0.08),
		Vector2(sx, sy - hh*0.15),
		Vector2(sx, sy + stamm_hoehe*0.7 - hh*0.08),
		Vector2(sx - stamm_breite, sy + stamm_hoehe*0.7),
	]), Color(0.40, 0.24, 0.10))

	# Krone — mehrere überlagerte Circles geben organischen Look
	var kx := mitte.x
	var ky := mitte.y - hh * 1.4
	draw_circle(Vector2(kx, ky + hh*0.2), hb*0.55, Color(0.16, 0.44, 0.11))
	draw_circle(Vector2(kx - hb*0.22, ky), hb*0.42, Color(0.20, 0.52, 0.14))
	draw_circle(Vector2(kx + hb*0.20, ky - hh*0.1), hb*0.38, Color(0.18, 0.48, 0.12))
	draw_circle(Vector2(kx, ky - hh*0.2), hb*0.32, Color(0.22, 0.56, 0.15))
	# Highlight
	draw_circle(Vector2(kx - hb*0.12, ky - hh*0.3), hb*0.14, Color(0.32, 0.68, 0.22, 0.55))


func _zeichne_iso_tier(tier: Dictionary) -> void:
	var k: Vector2i = tier["kachel"]
	var mitte := _kachel_zu_iso(k)
	var hh := float(ISO_HOEHE) * 0.5
	var hb := float(ISO_BREITE) * 0.5

	match str(tier["typ"]):
		"Reh":
			var bob := sin(zeit * 5.0) * 1.5
			# Körper als isometrisches Oval
			_zeichne_oval(Vector2(mitte.x, mitte.y - hh*0.3 + bob), hb*0.35, hh*0.25, Color(0.65, 0.42, 0.22))
			# Beine
			for i in 4:
				var bx := mitte.x + (float(i % 2) - 0.5) * hb * 0.3
				draw_line(Vector2(bx, mitte.y - hh*0.1 + bob),
						  Vector2(bx, mitte.y + hh*0.3), Color(0.50, 0.30, 0.14), 2.5)
			# Kopf
			var kopf_richtung := Vector2(float(tier["richtung"].x), float(tier["richtung"].y))
			var kopf_iso := _kachel_zu_iso_f(kopf_richtung * 0.35)
			var kopf_pos := Vector2(mitte.x + kopf_iso.x, mitte.y - hh*0.4 + bob + kopf_iso.y)
			draw_circle(kopf_pos, hb*0.15, Color(0.72, 0.50, 0.28))
			# Geweih
			draw_line(kopf_pos, kopf_pos + Vector2(-hb*0.14, -hh*0.35), Color(0.50, 0.30, 0.12), 2.0)
			draw_line(kopf_pos, kopf_pos + Vector2(hb*0.14, -hh*0.35),  Color(0.50, 0.30, 0.12), 2.0)

		"Hase":
			_zeichne_oval(Vector2(mitte.x, mitte.y - hh*0.2), hb*0.22, hh*0.18, Color(0.78, 0.75, 0.71))
			draw_circle(Vector2(mitte.x, mitte.y - hh*0.45), hb*0.14, Color(0.82, 0.79, 0.75))
			# Ohren
			draw_rect(Rect2(mitte.x - hb*0.10, mitte.y - hh*0.75, hb*0.08, hh*0.28), Color(0.80, 0.77, 0.73))
			draw_rect(Rect2(mitte.x + hb*0.02, mitte.y - hh*0.75, hb*0.08, hh*0.28), Color(0.80, 0.77, 0.73))


func _zeichne_iso_spieler() -> void:
	var mitte := _kachel_zu_iso(spieler_kachel)
	var hh := float(ISO_HOEHE) * 0.5
	var hb := float(ISO_BREITE) * 0.5

	var bob := sin(zeit * 11.0) * (hh * 0.08) if bewegungs_timer > 0.0 else 0.0

	# Schatten
	_zeichne_oval(Vector2(mitte.x + 2, mitte.y + hh*0.15), hb*0.28, hh*0.10, Color(0,0,0,0.30))

	# Beine
	var bein_swing := sin(zeit * 11.0) * (hb*0.06) if bewegungs_timer > 0.0 else 0.0
	draw_rect(Rect2(mitte.x - hb*0.16, mitte.y - hh*0.1 + bob - bein_swing, hb*0.12, hh*0.40), Color(0.20, 0.32, 0.62))
	draw_rect(Rect2(mitte.x + hb*0.04, mitte.y - hh*0.1 + bob + bein_swing, hb*0.12, hh*0.40), Color(0.20, 0.32, 0.62))

	# Körper
	draw_colored_polygon(PackedVector2Array([
		Vector2(mitte.x - hb*0.22, mitte.y - hh*0.60 + bob),
		Vector2(mitte.x + hb*0.22, mitte.y - hh*0.60 + bob),
		Vector2(mitte.x + hb*0.22, mitte.y - hh*0.10 + bob),
		Vector2(mitte.x - hb*0.22, mitte.y - hh*0.10 + bob),
	]), Color(0.26, 0.54, 0.92))

	# Kopf
	var kopf_r := hb * 0.18
	draw_circle(Vector2(mitte.x, mitte.y - hh*0.85 + bob), kopf_r, Color(0.96, 0.82, 0.67))
	draw_rect(
		Rect2(mitte.x - kopf_r, mitte.y - hh*1.02 + bob, kopf_r*2.0, kopf_r*0.65),
		Color(0.28, 0.16, 0.06)
	)

	# Augen — Richtung sichtbar machen
	var r := spieler_richtung
	if r == Vector2i(1, 0) or r == Vector2i(0, 1):
		draw_circle(Vector2(mitte.x + hb*0.07, mitte.y - hh*0.82 + bob), 2.0, Color(0.12, 0.08, 0.04))


func _zeichne_oval(mitte: Vector2, rx: float, ry: float, farbe: Color) -> void:
	var punkte := PackedVector2Array()
	for i in 16:
		var w := TAU * float(i) / 16.0
		punkte.append(Vector2(mitte.x + cos(w)*rx, mitte.y + sin(w)*ry))
	draw_colored_polygon(punkte, farbe)
