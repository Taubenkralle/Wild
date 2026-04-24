extends Node2D

# =============================================================================
#  PROTO A — Pokemon-Stil
#  Grid-Bewegung | Tiere auf der Karte | Annähern → Begegnungsscreen
# =============================================================================

const KACHELGROESSE := 48

const GRAS   := 0
const WASSER := 1
const WEG    := 2
const BAUM   := 3

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

const HAUS_POS    := Vector2i(3, 2)
const HAUS_BREITE := 4
const HAUS_HOEHE  := 3

# Tiere auf der Karte
var tiere: Array = [
	{"kachel": Vector2i(14, 4), "typ": "Reh",   "richtung": Vector2i(0, 1), "timer": 0.0},
	{"kachel": Vector2i(5,  10), "typ": "Hase",  "richtung": Vector2i(1, 0), "timer": 1.2},
	{"kachel": Vector2i(11, 8),  "typ": "Fuchs", "richtung": Vector2i(-1,0), "timer": 0.6},
]

# Spieler
var spieler_kachel   := Vector2i(8, 7)
var spieler_richtung := Vector2i(0, 1)
var bewegungs_timer  := 0.0
const SCHRITT_DELAY  := 0.14

# Begegnungs-System
var begegnung_aktiv     := false
var begegnung_tier_name := ""
var begegnung_ergebnis  := ""  # Feedback nach Wahl

var zeit := 0.0
var kamera: Camera2D
var hinweis_label: Label


func _ready() -> void:
	kamera = Camera2D.new()
	kamera.position = _kachel_mitte(spieler_kachel)
	add_child(kamera)

	var hud := CanvasLayer.new()
	add_child(hud)
	hinweis_label = Label.new()
	hinweis_label.position = Vector2(16, 12)
	hinweis_label.add_theme_font_size_override("font_size", 15)
	hinweis_label.modulate = Color(1, 1, 1, 0.8)
	hud.add_child(hinweis_label)


func _process(delta: float) -> void:
	zeit += delta

	if begegnung_aktiv:
		_begegnung_eingabe()
	else:
		_verarbeite_eingabe(delta)
		_aktualisiere_tiere(delta)
		kamera.position = kamera.position.lerp(_kachel_mitte(spieler_kachel), 0.14)

	_aktualisiere_hinweis()
	queue_redraw()


# --- Eingabe ---

func _verarbeite_eingabe(delta: float) -> void:
	bewegungs_timer = maxf(0.0, bewegungs_timer - delta)

	# Tier in der Nähe und Aktionstaste?
	if Input.is_action_just_pressed("ui_accept"):
		var nahe := _tier_in_reichweite()
		if not nahe.is_empty():
			begegnung_aktiv = true
			begegnung_tier_name = nahe["typ"]
			begegnung_ergebnis = ""
			return

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
	if _ist_begehbar(neue) and _kein_tier_auf(neue):
		spieler_kachel = neue
		bewegungs_timer = SCHRITT_DELAY


func _begegnung_eingabe() -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		begegnung_aktiv = false
		return
	if Input.is_key_just_pressed(KEY_1):
		begegnung_ergebnis = "Du schleichst dich langsam an..."
	elif Input.is_key_just_pressed(KEY_2):
		begegnung_ergebnis = "Du legst Köder aus und wartest..."
	elif Input.is_key_just_pressed(KEY_3):
		begegnung_ergebnis = "Du beobachtest aus der Ferne..."


# --- Tier-KI ---

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
			if _ist_begehbar(neue) and _kein_tier_auf(neue) and neue != spieler_kachel:
				tier["kachel"] = neue
				tier["richtung"] = r
				break


func _tier_in_reichweite() -> Dictionary:
	for tier: Dictionary in tiere:
		var abstand: Vector2i = spieler_kachel - tier["kachel"]
		if abs(abstand.x) + abs(abstand.y) == 1:
			return tier
	return {}


# --- Hilfsfunktionen ---

func _ist_begehbar(k: Vector2i) -> bool:
	if k.x < 0 or k.x >= 20 or k.y < 0 or k.y >= 15:
		return false
	var typ: int = KARTE[k.y][k.x]
	if typ == BAUM or typ == WASSER:
		return false
	if k.x >= HAUS_POS.x and k.x < HAUS_POS.x + HAUS_BREITE:
		if k.y >= HAUS_POS.y and k.y < HAUS_POS.y + HAUS_HOEHE:
			return false
	return true


func _kein_tier_auf(k: Vector2i) -> bool:
	for tier: Dictionary in tiere:
		if tier["kachel"] == k:
			return false
	return true


func _kachel_mitte(k: Vector2i) -> Vector2:
	var g := float(KACHELGROESSE)
	return Vector2(k.x * g + g * 0.5, k.y * g + g * 0.5)


func _aktualisiere_hinweis() -> void:
	if begegnung_aktiv:
		hinweis_label.text = "Proto A — Pokemon-Stil  |  [1] Annähern  [2] Köder  [3] Beobachten  [Esc] Zurück"
	elif not _tier_in_reichweite().is_empty():
		hinweis_label.text = "Proto A  |  [Enter] Tier ansprechen"
	else:
		hinweis_label.text = "Proto A — Pokemon-Stil  |  Pfeiltasten bewegen  |  Tieren annähern"


# =============================================================================
#  ZEICHNEN
# =============================================================================

func _draw() -> void:
	_zeichne_boden()
	_zeichne_wasser()
	_zeichne_haus()
	_zeichne_baeume()
	_zeichne_tiere()
	_zeichne_spieler()
	_zeichne_naehe_indikator()
	if begegnung_aktiv:
		_zeichne_begegnung()


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
					var v := sin(float(x * 17 + y * 11)) * 0.025
					draw_rect(rect, Color(0.26 + v, 0.63 + v, 0.19))
					if (x * 5 + y * 9) % 7 == 0:
						draw_rect(Rect2(px + g*0.15, py + g*0.15, g*0.7, g*0.7), Color(0.22, 0.57, 0.16))
				WASSER:
					draw_rect(rect, Color(0.14, 0.36, 0.82))
				WEG:
					draw_rect(rect, Color(0.65, 0.54, 0.37))
					draw_rect(Rect2(px+3, py+3, g-6, g-6), Color(0.70, 0.59, 0.42))


func _zeichne_wasser() -> void:
	var g := float(KACHELGROESSE)
	for y in 15:
		for x in 20:
			if KARTE[y][x] != WASSER:
				continue
			var px := float(x) * g
			var py := float(y) * g
			for i in 3:
				var basis_y := py + g * (0.28 + float(i) * 0.22)
				var punkte := PackedVector2Array()
				for s in 9:
					var wx := px + (float(s) / 8.0) * g
					var wy := basis_y + sin(wx * 0.13 + zeit * 1.8 + float(x) * 0.8 + float(i) * 1.2) * 2.5
					punkte.append(Vector2(wx, wy))
				for s in range(punkte.size() - 1):
					draw_line(punkte[s], punkte[s+1], Color(0.38, 0.62, 0.96, 0.55), 1.3)


func _zeichne_haus() -> void:
	var g  := float(KACHELGROESSE)
	var px := float(HAUS_POS.x) * g
	var py := float(HAUS_POS.y) * g
	var bw := float(HAUS_BREITE) * g
	var bh := float(HAUS_HOEHE) * g
	draw_rect(Rect2(px+7, py+g+7, bw, bh-g), Color(0,0,0,0.20))
	draw_rect(Rect2(px, py+g, bw, bh-g), Color(0.94, 0.88, 0.74))
	for i in 6:
		var ly := py + g + (bh-g) * float(i) / 6.0
		draw_line(Vector2(px, ly), Vector2(px+bw, ly), Color(0.80, 0.74, 0.60, 0.35), 1.0)
	var dach := PackedVector2Array([
		Vector2(px - g*0.22, py+g),
		Vector2(px + bw*0.5, py - g*0.35),
		Vector2(px + bw + g*0.22, py+g),
	])
	draw_colored_polygon(dach, Color(0.68, 0.26, 0.16))
	draw_line(dach[0], dach[1], Color(0.52, 0.18, 0.10), 2.5)
	draw_line(dach[1], dach[2], Color(0.52, 0.18, 0.10), 2.5)
	var tw := g * 0.40
	var th := g * 0.70
	var tx := px + bw*0.5 - tw*0.5
	var ty := py + bh - th
	draw_rect(Rect2(tx, ty, tw, th), Color(0.48, 0.30, 0.14))
	for seite in [-1.0, 1.0]:
		var fx: float = px + bw*0.5 + float(seite)*g*0.80 - g*0.20
		var fy := py + g*1.25
		draw_rect(Rect2(fx, fy, g*0.40, g*0.32), Color(0.72, 0.88, 0.96))
		draw_rect(Rect2(fx, fy, g*0.40, g*0.32), Color(0.55, 0.72, 0.82), false, 2.5)


func _zeichne_baeume() -> void:
	var g := float(KACHELGROESSE)
	for y in 15:
		for x in 20:
			if KARTE[y][x] != BAUM:
				continue
			var px := float(x) * g
			var py := float(y) * g
			var mx := px + g*0.5
			_zeichne_oval(Vector2(mx+3, py+g*0.87), g*0.34, g*0.11, Color(0,0,0,0.24))
			draw_rect(Rect2(mx - g*0.08, py + g*0.58, g*0.16, g*0.35), Color(0.46, 0.28, 0.12))
			draw_circle(Vector2(mx, py+g*0.36), g*0.36, Color(0.17, 0.46, 0.12))
			draw_circle(Vector2(mx - g*0.14, py+g*0.28), g*0.27, Color(0.21, 0.54, 0.15))
			draw_circle(Vector2(mx + g*0.12, py+g*0.26), g*0.24, Color(0.25, 0.60, 0.18))
			draw_circle(Vector2(mx - g*0.09, py+g*0.20), g*0.10, Color(0.34, 0.70, 0.24, 0.55))


func _zeichne_tiere() -> void:
	var g := float(KACHELGROESSE)
	for tier: Dictionary in tiere:
		var k: Vector2i = tier["kachel"]
		var px := float(k.x) * g
		var py := float(k.y) * g
		var mx := px + g * 0.5
		var my := py + g * 0.5

		match str(tier["typ"]):
			"Reh":
				# Körper
				_zeichne_oval(Vector2(mx, my + g*0.05), g*0.28, g*0.18, Color(0.65, 0.42, 0.22))
				# Kopf
				draw_circle(Vector2(mx + g*0.22, my - g*0.05), g*0.12, Color(0.72, 0.50, 0.28))
				# Geweih
				var hx := mx + g*0.22
				var hy := my - g*0.15
				draw_line(Vector2(hx, hy), Vector2(hx - g*0.10, hy - g*0.18), Color(0.50, 0.30, 0.12), 2.0)
				draw_line(Vector2(hx, hy), Vector2(hx + g*0.10, hy - g*0.18), Color(0.50, 0.30, 0.12), 2.0)
				draw_line(Vector2(hx - g*0.05, hy - g*0.12), Vector2(hx - g*0.15, hy - g*0.22), Color(0.50, 0.30, 0.12), 1.5)
				draw_line(Vector2(hx + g*0.05, hy - g*0.12), Vector2(hx + g*0.15, hy - g*0.22), Color(0.50, 0.30, 0.12), 1.5)
				# Beine
				for bein_x in [-0.14, -0.05, 0.05, 0.14]:
					draw_line(
						Vector2(mx + float(bein_x)*g, my + g*0.20),
						Vector2(mx + float(bein_x)*g, my + g*0.40),
						Color(0.50, 0.32, 0.16), 2.5
					)
			"Hase":
				# Körper
				_zeichne_oval(Vector2(mx, my + g*0.08), g*0.20, g*0.16, Color(0.75, 0.72, 0.68))
				# Kopf
				draw_circle(Vector2(mx, my - g*0.05), g*0.13, Color(0.80, 0.77, 0.73))
				# Ohren
				draw_rect(Rect2(mx - g*0.10, my - g*0.32, g*0.07, g*0.22), Color(0.78, 0.75, 0.71))
				draw_rect(Rect2(mx + g*0.03, my - g*0.32, g*0.07, g*0.22), Color(0.78, 0.75, 0.71))
				draw_rect(Rect2(mx - g*0.08, my - g*0.30, g*0.03, g*0.18), Color(0.90, 0.60, 0.65))
				draw_rect(Rect2(mx + g*0.05, my - g*0.30, g*0.03, g*0.18), Color(0.90, 0.60, 0.65))
				# Schwanz
				draw_circle(Vector2(mx - g*0.18, my + g*0.10), g*0.06, Color(0.95, 0.95, 0.95))
			"Fuchs":
				# Körper
				_zeichne_oval(Vector2(mx, my + g*0.05), g*0.25, g*0.15, Color(0.85, 0.42, 0.14))
				# Kopf
				draw_circle(Vector2(mx + g*0.20, my - g*0.02), g*0.13, Color(0.88, 0.48, 0.18))
				# Schnauze (weißlich)
				_zeichne_oval(Vector2(mx + g*0.30, my + g*0.02), g*0.07, g*0.05, Color(0.95, 0.88, 0.80))
				# Ohren
				draw_colored_polygon(PackedVector2Array([
					Vector2(mx + g*0.14, my - g*0.10),
					Vector2(mx + g*0.20, my - g*0.28),
					Vector2(mx + g*0.28, my - g*0.10),
				]), Color(0.85, 0.40, 0.12))
				# Buschiger Schwanz
				_zeichne_oval(Vector2(mx - g*0.28, my + g*0.06), g*0.14, g*0.10, Color(0.90, 0.55, 0.20))
				draw_circle(Vector2(mx - g*0.32, my + g*0.04), g*0.07, Color(0.95, 0.92, 0.88))


func _zeichne_spieler() -> void:
	var g  := float(KACHELGROESSE)
	var px := float(spieler_kachel.x) * g
	var py := float(spieler_kachel.y) * g
	var mx := px + g*0.5
	var bob := sin(zeit * 11.0) * (g * 0.028) if bewegungs_timer > 0.0 else 0.0
	_zeichne_oval(Vector2(mx+2, py+g*0.90), g*0.26, g*0.09, Color(0,0,0,0.30))
	var bein_swing := sin(zeit * 11.0) * (g * 0.055) if bewegungs_timer > 0.0 else 0.0
	draw_rect(Rect2(mx - g*0.16, py + g*0.64 + bob - bein_swing, g*0.10, g*0.20), Color(0.20, 0.32, 0.62))
	draw_rect(Rect2(mx + g*0.06, py + g*0.64 + bob + bein_swing, g*0.10, g*0.20), Color(0.20, 0.32, 0.62))
	draw_rect(Rect2(mx - g*0.20, py + g*0.36 + bob, g*0.40, g*0.30), Color(0.26, 0.54, 0.92))
	var kr := g * 0.16
	var ky := py + g*0.24 + bob
	draw_circle(Vector2(mx, ky), kr, Color(0.96, 0.82, 0.67))
	draw_rect(Rect2(mx - kr, ky - kr, kr*2.0, kr*0.65), Color(0.28, 0.16, 0.06))
	if spieler_richtung == Vector2i(0, 1):
		draw_circle(Vector2(mx - g*0.065, ky + g*0.02), 2.2, Color(0.12, 0.08, 0.04))
		draw_circle(Vector2(mx + g*0.065, ky + g*0.02), 2.2, Color(0.12, 0.08, 0.04))
	elif spieler_richtung != Vector2i(0, -1):
		draw_circle(Vector2(mx + float(spieler_richtung.x)*g*0.075, ky + g*0.01), 2.2, Color(0.12, 0.08, 0.04))


func _zeichne_naehe_indikator() -> void:
	if begegnung_aktiv:
		return
	var nahe := _tier_in_reichweite()
	if nahe.is_empty():
		return
	var k: Vector2i = nahe["kachel"]
	var g := float(KACHELGROESSE)
	var mx := float(k.x) * g + g*0.5
	var my := float(k.y) * g
	# Pulsierender Kreis
	var puls := 1.0 + sin(zeit * 6.0) * 0.15
	draw_circle(Vector2(mx, my - g*0.15), g*0.18 * puls, Color(1.0, 0.95, 0.20, 0.35))
	draw_string(ThemeDB.fallback_font, Vector2(mx - 5, my - g*0.12),
				"!", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1.0, 0.95, 0.10))


func _zeichne_begegnung() -> void:
	var g  := float(KACHELGROESSE)
	var tl := kamera.position - Vector2(640, 360)

	# Verdunkelung
	draw_rect(Rect2(tl, Vector2(1280, 720)), Color(0, 0, 0, 0.70))

	# Panel
	var pw := 520.0
	var ph := 280.0
	var px := tl.x + (1280 - pw) * 0.5
	var py := tl.y + (720 - ph) * 0.5
	draw_rect(Rect2(px, py, pw, ph), Color(0.08, 0.10, 0.16))
	draw_rect(Rect2(px, py, pw, ph), Color(0.35, 0.55, 0.85), false, 2.5)

	var schrift := ThemeDB.fallback_font
	draw_string(schrift, Vector2(px+24, py+40), "Ein " + begegnung_tier_name + " ist in der Nähe!",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1.0, 0.95, 0.70))

	if begegnung_ergebnis.is_empty():
		draw_string(schrift, Vector2(px+24, py+80), "Wie gehst du vor?",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.80, 0.80, 0.80))
		draw_string(schrift, Vector2(px+32, py+125), "[1]   Vorsichtig annähern",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.90, 0.95, 0.60))
		draw_string(schrift, Vector2(px+32, py+160), "[2]   Köder auswerfen",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.90, 0.95, 0.60))
		draw_string(schrift, Vector2(px+32, py+195), "[3]   Beobachten und warten",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.90, 0.95, 0.60))
		draw_string(schrift, Vector2(px+32, py+248), "[Esc]  Abbrechen",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.55, 0.55, 0.55))
	else:
		draw_string(schrift, Vector2(px+24, py+120), begegnung_ergebnis,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.70, 0.90, 0.70))
		draw_string(schrift, Vector2(px+24, py+200), "(Noch nicht implementiert — nur Feedback-Proto)",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.50, 0.50, 0.50))
		draw_string(schrift, Vector2(px+32, py+248), "[Esc]  Zurück",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.55, 0.55, 0.55))


func _zeichne_oval(mitte: Vector2, rx: float, ry: float, farbe: Color) -> void:
	var punkte := PackedVector2Array()
	for i in 16:
		var w := TAU * float(i) / 16.0
		punkte.append(Vector2(mitte.x + cos(w)*rx, mitte.y + sin(w)*ry))
	draw_colored_polygon(punkte, farbe)
