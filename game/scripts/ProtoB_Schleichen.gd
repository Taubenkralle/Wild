extends Node2D

# =============================================================================
#  PROTO B — Schleich-Stil
#  Freie Bewegung | Tier mit Sichtfeld | Detection-States
# =============================================================================

const KACHELGROESSE := 48
const KARTE_BREITE  := 20
const KARTE_HOEHE   := 15

const GRAS   := 0
const WASSER := 1
const BAUM   := 3

const KARTE := [
	[3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3],
	[3,0,0,0,0,3,0,0,0,0,0,0,0,0,0,3,0,0,0,3],
	[3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3],
	[3,0,0,0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,3],
	[3,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,0,0,0,3],
	[3,0,0,0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,3],
	[3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3],
	[3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,0,0,3],
	[3,0,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3],
	[3,0,0,0,0,0,0,0,0,0,0,0,3,0,0,0,0,0,0,3],
	[3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3],
	[3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,0,0,3],
	[3,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3],
	[3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3],
	[3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3],
]

# Spieler — freie Bewegung in Pixel
const SPIELER_GESCHWINDIGKEIT_NORMAL := 140.0
const SPIELER_GESCHWINDIGKEIT_SCHLEICH := 55.0

var spieler_pos   := Vector2(10, 8) * float(KACHELGROESSE)
var spieler_vel   := Vector2.ZERO
var schleicht     := false

# Reh: Zustand, Position, Blickrichtung
enum TierZustand { GRAST, AUFMERKSAM, FLIEHT, GEFANGEN }

var tier_pos      := Vector2(14, 5) * float(KACHELGROESSE)
var tier_zustand  := TierZustand.GRAST
var tier_blick    := Vector2(1, 0)
var tier_timer    := 0.0     # Für Zustandsübergänge und Wandern
var tier_wander_vel := Vector2.ZERO

# Sichtfeld-Parameter
const SICHT_REICHWEITE   := 220.0    # Pixel
const SICHT_WINKEL       := 0.85     # Radians (ca. 49° jede Seite = 98° gesamt)
const SCHLEICH_FAKTOR    := 0.5      # Sichtbereich halbiert beim Schleichen

var gefangen_timer := 0.0
var erfolg         := false

var zeit   := 0.0
var kamera: Camera2D
var hud_label: Label


func _ready() -> void:
	kamera = Camera2D.new()
	kamera.position = spieler_pos
	add_child(kamera)

	var hud := CanvasLayer.new()
	add_child(hud)
	hud_label = Label.new()
	hud_label.position = Vector2(16, 12)
	hud_label.add_theme_font_size_override("font_size", 15)
	hud_label.modulate = Color(1, 1, 1, 0.85)
	hud.add_child(hud_label)


func _process(delta: float) -> void:
	zeit += delta
	_verarbeite_eingabe(delta)
	_bewege_spieler(delta)
	_aktualisiere_tier(delta)
	kamera.position = kamera.position.lerp(spieler_pos, 0.12)
	_aktualisiere_hud()
	queue_redraw()


func _verarbeite_eingabe(delta: float) -> void:
	schleicht = Input.is_action_pressed("ui_select") or Input.is_key_pressed(KEY_SHIFT)

	var richtung := Vector2.ZERO
	if Input.is_action_pressed("ui_right"): richtung.x += 1
	if Input.is_action_pressed("ui_left"):  richtung.x -= 1
	if Input.is_action_pressed("ui_down"):  richtung.y += 1
	if Input.is_action_pressed("ui_up"):    richtung.y -= 1

	if richtung.length() > 0.0:
		richtung = richtung.normalized()

	var geschwindigkeit := SPIELER_GESCHWINDIGKEIT_SCHLEICH if schleicht else SPIELER_GESCHWINDIGKEIT_NORMAL
	spieler_vel = richtung * geschwindigkeit


func _bewege_spieler(delta: float) -> void:
	var neue_pos := spieler_pos + spieler_vel * delta

	# Einfache Terrain-Kollision: prüfe welche Kachel der Spieler betritt
	var kachel := Vector2i(int(neue_pos.x / float(KACHELGROESSE)), int(neue_pos.y / float(KACHELGROESSE)))
	if _kachel_begehbar(kachel):
		spieler_pos = neue_pos
	else:
		# Versuche nur X-Achse
		var pos_x := Vector2(neue_pos.x, spieler_pos.y)
		var k_x := Vector2i(int(pos_x.x / float(KACHELGROESSE)), int(pos_x.y / float(KACHELGROESSE)))
		if _kachel_begehbar(k_x):
			spieler_pos = pos_x
		else:
			var pos_y := Vector2(spieler_pos.x, neue_pos.y)
			var k_y := Vector2i(int(pos_y.x / float(KACHELGROESSE)), int(pos_y.y / float(KACHELGROESSE)))
			if _kachel_begehbar(k_y):
				spieler_pos = pos_y


func _kachel_begehbar(k: Vector2i) -> bool:
	if k.x < 0 or k.x >= KARTE_BREITE or k.y < 0 or k.y >= KARTE_HOEHE:
		return false
	var typ: int = KARTE[k.y][k.x]
	return typ != BAUM and typ != WASSER


func _aktualisiere_tier(delta: float) -> void:
	if tier_zustand == TierZustand.GEFANGEN:
		return

	var entfernung := spieler_pos.distance_to(tier_pos)
	var reichweite := SICHT_REICHWEITE * (SCHLEICH_FAKTOR if schleicht else 1.0)

	match tier_zustand:
		TierZustand.GRAST:
			# Wandern
			tier_timer -= delta
			if tier_timer <= 0.0:
				tier_timer = randf_range(1.5, 3.0)
				if randf() > 0.4:
					var winkel := randf() * TAU
					tier_wander_vel = Vector2(cos(winkel), sin(winkel)) * 30.0
					tier_blick = tier_wander_vel.normalized()
				else:
					tier_wander_vel = Vector2.ZERO

			tier_pos += tier_wander_vel * delta
			tier_pos.x = clampf(tier_pos.x, float(KACHELGROESSE), float((KARTE_BREITE-2) * KACHELGROESSE))
			tier_pos.y = clampf(tier_pos.y, float(KACHELGROESSE), float((KARTE_HOEHE-2)  * KACHELGROESSE))

			# Spieler gefangen? (von hinten / außerhalb Sichtfeld angenähert)
			if entfernung < float(KACHELGROESSE) * 0.8 and not _im_sichtfeld(reichweite):
				tier_zustand = TierZustand.GEFANGEN
				return

			# Spieler entdeckt?
			if _im_sichtfeld(reichweite):
				tier_zustand = TierZustand.AUFMERKSAM
				tier_timer = 1.2
				tier_wander_vel = Vector2.ZERO

		TierZustand.AUFMERKSAM:
			# Dreht sich zum Spieler
			tier_blick = (spieler_pos - tier_pos).normalized()
			tier_timer -= delta
			if not _im_sichtfeld(reichweite):
				tier_zustand = TierZustand.GRAST
				tier_timer = 2.0
			elif tier_timer <= 0.0:
				tier_zustand = TierZustand.FLIEHT

		TierZustand.FLIEHT:
			# Flieht vom Spieler weg
			var flucht_richtung := (tier_pos - spieler_pos).normalized()
			tier_blick = flucht_richtung
			tier_pos += flucht_richtung * 180.0 * delta
			tier_pos.x = clampf(tier_pos.x, float(KACHELGROESSE), float((KARTE_BREITE-2)*KACHELGROESSE))
			tier_pos.y = clampf(tier_pos.y, float(KACHELGROESSE), float((KARTE_HOEHE-2)*KACHELGROESSE))
			# Beruhigt sich nach genug Abstand
			if entfernung > SICHT_REICHWEITE * 2.2:
				tier_zustand = TierZustand.GRAST
				tier_timer = 4.0
				tier_wander_vel = Vector2.ZERO


func _im_sichtfeld(reichweite: float) -> bool:
	var zum_spieler := spieler_pos - tier_pos
	if zum_spieler.length() > reichweite:
		return false
	if tier_blick.length() < 0.01:
		return false
	var winkel := tier_blick.angle_to(zum_spieler)
	return abs(winkel) <= SICHT_WINKEL


func _aktualisiere_hud() -> void:
	var zustand_text := match_zustand_text()
	var modus := " [Shift]  Schleichen" if not schleicht else " [Shift]  Schleichen (aktiv)"
	hud_label.text = "Proto B — Schleichen  |  Pfeiltasten bewegen  |" + modus + "  |  Reh: " + zustand_text


func match_zustand_text() -> String:
	match tier_zustand:
		TierZustand.GRAST:      return "grast ruhig"
		TierZustand.AUFMERKSAM: return "aufmerksam!"
		TierZustand.FLIEHT:     return "flieht!"
		TierZustand.GEFANGEN:   return "gefangen!"
		_:                      return "?"


# =============================================================================
#  ZEICHNEN
# =============================================================================

func _draw() -> void:
	_zeichne_boden()
	_zeichne_sichtfeld()
	_zeichne_baeume()
	_zeichne_tier()
	_zeichne_spieler()
	_zeichne_status_indikator()


func _zeichne_boden() -> void:
	var g := float(KACHELGROESSE)
	for y in KARTE_HOEHE:
		for x in KARTE_BREITE:
			var typ: int = KARTE[y][x]
			var px := float(x) * g
			var py := float(y) * g
			var rect := Rect2(px, py, g, g)
			match typ:
				GRAS, BAUM:
					var v := sin(float(x*17 + y*11)) * 0.025
					draw_rect(rect, Color(0.26+v, 0.63+v, 0.19))
				WASSER:
					draw_rect(rect, Color(0.14, 0.36, 0.82))
					for i in 2:
						var by := py + g * (0.30 + float(i)*0.30)
						for s in 8:
							var wx := px + float(s)/7.0 * g
							var wy := by + sin(wx*0.13 + zeit*1.8 + float(x)*0.8)*2.5
							if s < 7:
								draw_line(Vector2(wx, wy),
									Vector2(px + float(s+1)/7.0*g, by + sin((px+float(s+1)/7.0*g)*0.13+zeit*1.8+float(x)*0.8)*2.5),
									Color(0.38, 0.62, 0.96, 0.55), 1.3)
				_:
					draw_rect(rect, Color(0.26, 0.63, 0.19))


func _zeichne_sichtfeld() -> void:
	if tier_zustand == TierZustand.GEFANGEN:
		return

	var reichweite := SICHT_REICHWEITE * (SCHLEICH_FAKTOR if schleicht else 1.0)
	var farbe: Color
	match tier_zustand:
		TierZustand.GRAST:      farbe = Color(1.0, 0.95, 0.20, 0.18)
		TierZustand.AUFMERKSAM: farbe = Color(1.0, 0.60, 0.10, 0.30)
		TierZustand.FLIEHT:     farbe = Color(0.95, 0.15, 0.15, 0.22)
		_:                      farbe = Color(0,0,0,0)

	if tier_blick.length() < 0.01:
		return

	var punkte := PackedVector2Array()
	punkte.append(tier_pos)
	var basis_winkel := tier_blick.angle()
	var schritte := 24
	for i in range(schritte + 1):
		var w := basis_winkel - SICHT_WINKEL + SICHT_WINKEL * 2.0 * float(i) / float(schritte)
		punkte.append(tier_pos + Vector2(cos(w), sin(w)) * reichweite)
	draw_colored_polygon(punkte, farbe)

	# Sichtfeld-Rand
	draw_line(punkte[0], punkte[1], Color(farbe.r, farbe.g, farbe.b, 0.40), 1.5)
	draw_line(punkte[0], punkte[punkte.size()-1], Color(farbe.r, farbe.g, farbe.b, 0.40), 1.5)


func _zeichne_baeume() -> void:
	var g := float(KACHELGROESSE)
	for y in KARTE_HOEHE:
		for x in KARTE_BREITE:
			if KARTE[y][x] != BAUM:
				continue
			var px := float(x)*g
			var py := float(y)*g
			var mx := px + g*0.5
			_zeichne_oval(Vector2(mx+3, py+g*0.87), g*0.34, g*0.11, Color(0,0,0,0.24))
			draw_rect(Rect2(mx-g*0.08, py+g*0.58, g*0.16, g*0.35), Color(0.46, 0.28, 0.12))
			draw_circle(Vector2(mx, py+g*0.36), g*0.36, Color(0.17, 0.46, 0.12))
			draw_circle(Vector2(mx-g*0.14, py+g*0.28), g*0.27, Color(0.21, 0.54, 0.15))
			draw_circle(Vector2(mx+g*0.12, py+g*0.26), g*0.24, Color(0.25, 0.60, 0.18))


func _zeichne_tier() -> void:
	var g := float(KACHELGROESSE)
	var mx := tier_pos.x
	var my := tier_pos.y

	# Reh
	var bob := sin(zeit * 5.0) * 1.5 if tier_zustand == TierZustand.GRAST else 0.0
	_zeichne_oval(Vector2(mx+3, my+g*0.25), g*0.28, g*0.10, Color(0,0,0,0.22))
	_zeichne_oval(Vector2(mx, my+bob), g*0.28, g*0.18, Color(0.65, 0.42, 0.22))
	draw_circle(Vector2(mx + tier_blick.x*g*0.22, my + tier_blick.y*g*0.22 + bob), g*0.12, Color(0.72, 0.50, 0.28))
	var hx := mx + tier_blick.x*g*0.22
	var hy := my + tier_blick.y*g*0.22 + bob - g*0.10
	var links := tier_blick.rotated(0.5) * g*0.14
	var rechts := tier_blick.rotated(-0.5) * g*0.14
	draw_line(Vector2(hx, hy), Vector2(hx + links.x, hy + links.y - g*0.16), Color(0.50, 0.30, 0.12), 2.0)
	draw_line(Vector2(hx, hy), Vector2(hx + rechts.x, hy + rechts.y - g*0.16), Color(0.50, 0.30, 0.12), 2.0)


func _zeichne_spieler() -> void:
	var g  := float(KACHELGROESSE)
	var mx := spieler_pos.x
	var my := spieler_pos.y

	# Schleich-Ring
	if schleicht:
		draw_circle(Vector2(mx, my), g*0.55, Color(0.40, 0.80, 0.40, 0.18))
		draw_arc(Vector2(mx, my), g*0.55, 0, TAU, 36, Color(0.40, 0.90, 0.40, 0.50), 1.5)

	_zeichne_oval(Vector2(mx+2, my+g*0.40), g*0.26, g*0.09, Color(0,0,0,0.30))
	var bob := sin(zeit * 11.0) * (g*0.028) if spieler_vel.length() > 10.0 else 0.0
	draw_rect(Rect2(mx-g*0.20, my-g*0.12+bob, g*0.40, g*0.30), Color(0.26, 0.54, 0.92))
	draw_circle(Vector2(mx, my-g*0.24+bob), g*0.16, Color(0.96, 0.82, 0.67))
	draw_rect(Rect2(mx-g*0.16, my-g*0.38+bob, g*0.32, g*0.12), Color(0.28, 0.16, 0.06))


func _zeichne_status_indikator() -> void:
	var g := float(KACHELGROESSE)

	match tier_zustand:
		TierZustand.AUFMERKSAM:
			# Fragezeichen
			var puls := 1.0 + sin(zeit * 8.0) * 0.2
			draw_circle(Vector2(tier_pos.x, tier_pos.y - g*0.55), g*0.22*puls, Color(1.0, 0.85, 0.10, 0.40))
			draw_string(ThemeDB.fallback_font,
				Vector2(tier_pos.x - 6, tier_pos.y - g*0.48),
				"?", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1.0, 0.85, 0.10))
		TierZustand.FLIEHT:
			draw_string(ThemeDB.fallback_font,
				Vector2(tier_pos.x - 6, tier_pos.y - g*0.55),
				"!", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(0.95, 0.20, 0.20))
		TierZustand.GEFANGEN:
			var tl := kamera.position - Vector2(640, 360)
			draw_rect(Rect2(tl, Vector2(1280, 720)), Color(0, 0, 0, 0.60))
			var schrift := ThemeDB.fallback_font
			draw_string(schrift, tl + Vector2(390, 320), "Reh behutsam angenähert!",
						HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(0.70, 1.0, 0.70))
			draw_string(schrift, tl + Vector2(430, 370), "Das Reh vertraut dir.",
						HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.90, 0.90, 0.90))
			draw_string(schrift, tl + Vector2(480, 430), "[Esc]  Neu starten",
						HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.55, 0.55, 0.55))


func _zeichne_oval(mitte: Vector2, rx: float, ry: float, farbe: Color) -> void:
	var punkte := PackedVector2Array()
	for i in 16:
		var w := TAU * float(i) / 16.0
		punkte.append(Vector2(mitte.x + cos(w)*rx, mitte.y + sin(w)*ry))
	draw_colored_polygon(punkte, farbe)
