extends Node2D

# Kachelgröße in Pixel
const KACHELGROESSE := 48

# Terrain-Typen
const GRAS   := 0
const WASSER := 1
const WEG    := 2
const BAUM   := 3

# Karte: 20 Spalten x 15 Zeilen
# Rand komplett Bäume, Weg von Süd nach Nord, Teich rechts, Haus links
const KARTE := [
	[3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3],
	[3,0,0,0,0,3,0,0,0,0,0,0,0,0,0,3,0,0,0,3],
	[3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3],
	[3,0,0,0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,3],
	[3,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,0,0,0,3],
	[3,0,0,0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,3],
	[3,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,3],
	[3,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,3,0,0,3],
	[3,0,0,3,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,3],
	[3,0,0,0,0,0,0,0,2,0,0,0,3,0,0,0,0,0,0,3],
	[3,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,3],
	[3,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,3,0,0,3],
	[3,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3],
	[3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3],
	[3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3],
]

# Haus: Startposition (oben-links) + Größe in Kacheln
const HAUS_POS    := Vector2i(3, 2)
const HAUS_BREITE := 4   # Kacheln
const HAUS_HOEHE  := 3   # Kacheln

# Spieler-Zustand
var spieler_kachel   := Vector2i(8, 7)
var spieler_richtung := Vector2i(0, 1)
var bewegungs_timer  := 0.0
const SCHRITT_DELAY  := 0.14

# Animationszeit
var zeit := 0.0

var kamera: Camera2D


func _ready() -> void:
	kamera = Camera2D.new()
	kamera.position = _kachel_mitte(spieler_kachel)
	add_child(kamera)

	# HUD als CanvasLayer — immer in Bildschirmkoordinaten
	var hud := CanvasLayer.new()
	add_child(hud)
	var hinweis := Label.new()
	hinweis.text = "Pfeiltasten bewegen  |  Wild — Prototyp"
	hinweis.position = Vector2(16, 12)
	hinweis.add_theme_font_size_override("font_size", 15)
	hinweis.modulate = Color(1, 1, 1, 0.75)
	hud.add_child(hinweis)


func _process(delta: float) -> void:
	zeit += delta
	_verarbeite_eingabe(delta)
	# Kamera folgt dem Spieler mit sanftem Lerp
	kamera.position = kamera.position.lerp(_kachel_mitte(spieler_kachel), 0.14)
	queue_redraw()


func _verarbeite_eingabe(delta: float) -> void:
	bewegungs_timer = maxf(0.0, bewegungs_timer - delta)
	if bewegungs_timer > 0.0:
		return

	var richtung := Vector2i.ZERO
	if Input.is_action_pressed("ui_right"):
		richtung = Vector2i(1, 0)
	elif Input.is_action_pressed("ui_left"):
		richtung = Vector2i(-1, 0)
	elif Input.is_action_pressed("ui_down"):
		richtung = Vector2i(0, 1)
	elif Input.is_action_pressed("ui_up"):
		richtung = Vector2i(0, -1)

	if richtung == Vector2i.ZERO:
		return

	spieler_richtung = richtung
	var neue := spieler_kachel + richtung
	if _ist_begehbar(neue):
		spieler_kachel = neue
		bewegungs_timer = SCHRITT_DELAY


func _ist_begehbar(k: Vector2i) -> bool:
	if k.x < 0 or k.x >= 20 or k.y < 0 or k.y >= 15:
		return false
	var typ: int = KARTE[k.y][k.x]
	if typ == BAUM or typ == WASSER:
		return false
	# Haus blockiert
	if k.x >= HAUS_POS.x and k.x < HAUS_POS.x + HAUS_BREITE:
		if k.y >= HAUS_POS.y and k.y < HAUS_POS.y + HAUS_HOEHE:
			return false
	return true


func _kachel_mitte(k: Vector2i) -> Vector2:
	var g := float(KACHELGROESSE)
	return Vector2(k.x * g + g * 0.5, k.y * g + g * 0.5)


# =============================================================================
#  ZEICHNEN
# =============================================================================

func _draw() -> void:
	_zeichne_boden()
	_zeichne_wasser_effekte()
	_zeichne_haus()
	_zeichne_baeume()
	_zeichne_spieler()


# --- Bodenschicht -----------------------------------------------------------

func _zeichne_boden() -> void:
	var g := float(KACHELGROESSE)
	for y in 15:
		for x in 20:
			var typ: int = KARTE[y][x]
			var px := float(x) * g
			var py := float(y) * g
			var rect := Rect2(px, py, g, g)

			match typ:
				GRAS, BAUM:
					# Leichte Farbvariation pro Kachel — deterministisch
					var v := sin(float(x * 17 + y * 11)) * 0.025
					draw_rect(rect, Color(0.26 + v, 0.63 + v, 0.19))
					# Gelegentlich dunklerer Fleck
					if (x * 5 + y * 9) % 7 == 0:
						draw_rect(
							Rect2(px + g * 0.15, py + g * 0.15, g * 0.70, g * 0.70),
							Color(0.22, 0.57, 0.16)
						)
				WASSER:
					draw_rect(rect, Color(0.14, 0.36, 0.82))
				WEG:
					draw_rect(rect, Color(0.65, 0.54, 0.37))
					# Wegstruktur: leichte Innenaufhellung
					draw_rect(
						Rect2(px + 3.0, py + 3.0, g - 6.0, g - 6.0),
						Color(0.70, 0.59, 0.42)
					)


# --- Wasser-Effekte ---------------------------------------------------------

func _zeichne_wasser_effekte() -> void:
	var g := float(KACHELGROESSE)
	for y in 15:
		for x in 20:
			if KARTE[y][x] != WASSER:
				continue
			var px := float(x) * g
			var py := float(y) * g

			# Drei animierte Wellenlinien
			for i in 3:
				var basis_y := py + g * (0.28 + float(i) * 0.22)
				var punkte := PackedVector2Array()
				for s in 9:
					var wx := px + (float(s) / 8.0) * g
					var phasen_offset := float(x) * 0.8 + float(i) * 1.2
					var wy := basis_y + sin(wx * 0.13 + zeit * 1.8 + phasen_offset) * 2.5
					punkte.append(Vector2(wx, wy))
				for s in range(punkte.size() - 1):
					draw_line(punkte[s], punkte[s + 1], Color(0.38, 0.62, 0.96, 0.55), 1.3)

			# Glitzerpunkt
			var glitzer_alpha := 0.3 + sin(zeit * 2.5 + float(x + y)) * 0.25
			draw_circle(
				Vector2(px + g * 0.28, py + g * 0.22),
				2.2,
				Color(0.85, 0.94, 1.0, glitzer_alpha)
			)


# --- Haus -------------------------------------------------------------------

func _zeichne_haus() -> void:
	var g  := float(KACHELGROESSE)
	var px := float(HAUS_POS.x) * g
	var py := float(HAUS_POS.y) * g
	var bw := float(HAUS_BREITE) * g   # Gesamtbreite in Pixel
	var bh := float(HAUS_HOEHE)  * g   # Gesamthöhe in Pixel

	# Schatten
	draw_rect(Rect2(px + 7.0, py + g + 7.0, bw, bh - g), Color(0.0, 0.0, 0.0, 0.20))

	# Wand (Hauptfläche, beginnt eine Kachel tiefer als die Dachkante)
	draw_rect(Rect2(px, py + g, bw, bh - g), Color(0.94, 0.88, 0.74))

	# Horizontale Mauerstruktur
	var streifen := 6
	for i in range(1, streifen):
		var ly := py + g + (bh - g) * float(i) / float(streifen)
		draw_line(Vector2(px, ly), Vector2(px + bw, ly), Color(0.80, 0.74, 0.60, 0.35), 1.0)

	# Dach (Dreieck, ragt etwas über die Wand hinaus)
	var dach_spitze := Vector2(px + bw * 0.5, py - g * 0.35)
	var dach_links  := Vector2(px - g * 0.22, py + g)
	var dach_rechts := Vector2(px + bw + g * 0.22, py + g)
	draw_colored_polygon(
		PackedVector2Array([dach_links, dach_spitze, dach_rechts]),
		Color(0.68, 0.26, 0.16)
	)
	# Dachkanten
	draw_line(dach_links, dach_spitze, Color(0.52, 0.18, 0.10), 2.5)
	draw_line(dach_spitze, dach_rechts, Color(0.52, 0.18, 0.10), 2.5)
	draw_line(dach_links, dach_rechts, Color(0.52, 0.18, 0.10), 1.5)

	# Tür (Mitte, unten)
	var tuer_breite := g * 0.40
	var tuer_hoehe  := g * 0.70
	var tuer_x := px + bw * 0.5 - tuer_breite * 0.5
	var tuer_y := py + bh - tuer_hoehe
	draw_rect(Rect2(tuer_x, tuer_y, tuer_breite, tuer_hoehe), Color(0.48, 0.30, 0.14))
	draw_rect(
		Rect2(tuer_x + 3.0, tuer_y + 3.0, tuer_breite - 6.0, tuer_hoehe - 3.0),
		Color(0.58, 0.38, 0.20)
	)
	# Türknauf
	draw_circle(Vector2(tuer_x + tuer_breite * 0.78, tuer_y + tuer_hoehe * 0.52),
				3.0, Color(0.90, 0.76, 0.22))

	# Zwei Fenster
	for seite in [-1.0, 1.0]:
		var fx := px + bw * 0.5 + seite * g * 0.80 - g * 0.20
		var fy := py + g * 1.25
		var fw := g * 0.40
		var fh := g * 0.32
		# Scheibe
		draw_rect(Rect2(fx, fy, fw, fh), Color(0.72, 0.88, 0.96))
		# Rahmen
		draw_rect(Rect2(fx, fy, fw, fh), Color(0.55, 0.72, 0.82), false, 2.5)
		# Kreuz
		draw_line(Vector2(fx + fw * 0.5, fy), Vector2(fx + fw * 0.5, fy + fh),
				  Color(0.55, 0.72, 0.82), 1.5)
		draw_line(Vector2(fx, fy + fh * 0.5), Vector2(fx + fw, fy + fh * 0.5),
				  Color(0.55, 0.72, 0.82), 1.5)


# --- Bäume ------------------------------------------------------------------

func _zeichne_baeume() -> void:
	var g := float(KACHELGROESSE)
	for y in 15:
		for x in 20:
			if KARTE[y][x] != BAUM:
				continue
			var px := float(x) * g
			var py := float(y) * g
			var mx := px + g * 0.5
			var my := py + g * 0.5

			# Bodenschatten (Oval)
			_zeichne_oval(
				Vector2(mx + 3.0, py + g * 0.87),
				g * 0.34, g * 0.11,
				Color(0.0, 0.0, 0.0, 0.24)
			)

			# Stamm
			var sw := g * 0.16
			var sh := g * 0.35
			draw_rect(
				Rect2(mx - sw * 0.5, py + g * 0.58, sw, sh),
				Color(0.46, 0.28, 0.12)
			)

			# Krone — drei überlappende Kreise für organischen Look
			var kr := g * 0.36
			draw_circle(Vector2(mx, py + g * 0.36), kr, Color(0.17, 0.46, 0.12))
			draw_circle(Vector2(mx - g * 0.14, py + g * 0.28), kr * 0.74, Color(0.21, 0.54, 0.15))
			draw_circle(Vector2(mx + g * 0.12, py + g * 0.26), kr * 0.68, Color(0.19, 0.50, 0.13))
			# Highlight
			draw_circle(
				Vector2(mx - g * 0.09, py + g * 0.20),
				kr * 0.28,
				Color(0.34, 0.70, 0.24, 0.55)
			)


# Hilfsfunktion: gefülltes Oval über PackedVector2Array
func _zeichne_oval(mitte: Vector2, rx: float, ry: float, farbe: Color) -> void:
	var punkte := PackedVector2Array()
	for i in 16:
		var w := TAU * float(i) / 16.0
		punkte.append(Vector2(mitte.x + cos(w) * rx, mitte.y + sin(w) * ry))
	draw_colored_polygon(punkte, farbe)


# --- Spieler ----------------------------------------------------------------

func _zeichne_spieler() -> void:
	var g  := float(KACHELGROESSE)
	var px := float(spieler_kachel.x) * g
	var py := float(spieler_kachel.y) * g
	var mx := px + g * 0.5
	var my := py + g * 0.5

	# Bob beim Laufen
	var bob := sin(zeit * 11.0) * (g * 0.028) if bewegungs_timer > 0.0 else 0.0

	# Bodenschatten
	_zeichne_oval(Vector2(mx + 2.0, py + g * 0.90), g * 0.26, g * 0.09, Color(0, 0, 0, 0.30))

	# Beine
	var bein_swing := sin(zeit * 11.0) * (g * 0.055) if bewegungs_timer > 0.0 else 0.0
	var bein_breite := g * 0.10
	var bein_hoehe  := g * 0.20
	draw_rect(
		Rect2(mx - g * 0.16, py + g * 0.64 + bob - bein_swing, bein_breite, bein_hoehe),
		Color(0.20, 0.32, 0.62)
	)
	draw_rect(
		Rect2(mx + g * 0.06, py + g * 0.64 + bob + bein_swing, bein_breite, bein_hoehe),
		Color(0.20, 0.32, 0.62)
	)

	# Körper
	var koerper_rect := Rect2(mx - g * 0.20, py + g * 0.36 + bob, g * 0.40, g * 0.30)
	draw_rect(koerper_rect, Color(0.26, 0.54, 0.92))
	# Highlight auf Körper
	draw_rect(
		Rect2(mx - g * 0.18, py + g * 0.38 + bob, g * 0.16, g * 0.09),
		Color(1.0, 1.0, 1.0, 0.22)
	)

	# Arme (kurze Striche seitlich)
	var arm_y := py + g * 0.42 + bob
	draw_line(
		Vector2(mx - g * 0.20, arm_y),
		Vector2(mx - g * 0.32, arm_y + g * 0.10),
		Color(0.26, 0.54, 0.92), 3.5
	)
	draw_line(
		Vector2(mx + g * 0.20, arm_y),
		Vector2(mx + g * 0.32, arm_y + g * 0.10),
		Color(0.26, 0.54, 0.92), 3.5
	)

	# Kopf
	var kopf_r := g * 0.16
	var kopf_y := py + g * 0.24 + bob
	draw_circle(Vector2(mx, kopf_y), kopf_r, Color(0.96, 0.82, 0.67))
	draw_circle(Vector2(mx - g * 0.05, kopf_y - g * 0.04), kopf_r * 0.38,
				Color(1.0, 0.93, 0.80, 0.45))

	# Haare / Mütze
	draw_rect(
		Rect2(mx - kopf_r, kopf_y - kopf_r, kopf_r * 2.0, kopf_r * 0.65),
		Color(0.28, 0.16, 0.06)
	)

	# Augen — richtungsabhängig
	if spieler_richtung == Vector2i(0, 1):
		draw_circle(Vector2(mx - g * 0.065, kopf_y + g * 0.02), 2.2, Color(0.12, 0.08, 0.04))
		draw_circle(Vector2(mx + g * 0.065, kopf_y + g * 0.02), 2.2, Color(0.12, 0.08, 0.04))
	elif spieler_richtung == Vector2i(0, -1):
		pass  # Rücken — kein Gesicht sichtbar
	else:
		var aug_x := mx + float(spieler_richtung.x) * g * 0.075
		draw_circle(Vector2(aug_x, kopf_y + g * 0.01), 2.2, Color(0.12, 0.08, 0.04))
