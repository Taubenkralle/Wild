extends Node2D

# Konfiguration — wird pro Prototype-Szene unterschiedlich gesetzt
@export var kachelgroesse: int = 32
@export var zeige_gitterlinien: bool = true
@export var proto_name: String = "Prototype"

# Terrain-Typen
const GRAS   = 0
const WASSER = 1
const SAND   = 2
const STEIN  = 3

# Farben pro Terrain-Typ
const FARBEN := {
	GRAS:   Color(0.25, 0.65, 0.20),
	WASSER: Color(0.18, 0.42, 0.88),
	SAND:   Color(0.88, 0.78, 0.48),
	STEIN:  Color(0.48, 0.48, 0.52),
}

# Hervorgehobene Farben für Kanten (leicht heller)
const FARBEN_HELL := {
	GRAS:   Color(0.35, 0.78, 0.28),
	WASSER: Color(0.25, 0.55, 0.95),
	SAND:   Color(0.95, 0.88, 0.60),
	STEIN:  Color(0.60, 0.60, 0.65),
}

# 20x15 Test-Karte (Zeilen x Spalten)
const KARTE := [
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
	[0,0,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
	[0,0,2,2,2,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0],
	[0,0,2,2,0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,3,3,3,3,3,0,0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,3,3,3,3,0,0,0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,3,3,3,0,0,0,0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
]

const KARTE_BREITE  := 20
const KARTE_HOEHE   := 15

# Spieler-Zustand
var spieler_kachel: Vector2i = Vector2i(5, 7)   # Startposition in Kachelkoordinaten
var spieler_richtung: Vector2i = Vector2i(0, 1) # Blickrichtung (Süden)
var bewegungs_timer: float = 0.0
const BEWEGUNGS_DELAY: float = 0.14             # Sekunden zwischen Schritten (Pokemon-Feeling)

# Kamera
var kamera: Camera2D


func _ready() -> void:
	kamera = Camera2D.new()
	kamera.position = _kachel_zu_pixel(spieler_kachel)
	add_child(kamera)
	queue_redraw()


func _process(delta: float) -> void:
	_verarbeite_eingabe(delta)
	# Kamera sanft zum Spieler folgen lassen
	var ziel := _kachel_zu_pixel(spieler_kachel)
	kamera.position = kamera.position.lerp(ziel, 0.12)


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
	var neue_kachel := spieler_kachel + richtung

	if _ist_begehbar(neue_kachel):
		spieler_kachel = neue_kachel
		bewegungs_timer = BEWEGUNGS_DELAY

	queue_redraw()


func _ist_begehbar(kachel: Vector2i) -> bool:
	if kachel.x < 0 or kachel.x >= KARTE_BREITE:
		return false
	if kachel.y < 0 or kachel.y >= KARTE_HOEHE:
		return false
	# Wasser ist nicht begehbar (noch kein Boot)
	return KARTE[kachel.y][kachel.x] != WASSER


func _kachel_zu_pixel(kachel: Vector2i) -> Vector2:
	return Vector2(
		kachel.x * kachelgroesse + kachelgroesse / 2.0,
		kachel.y * kachelgroesse + kachelgroesse / 2.0
	)


func _draw() -> void:
	_zeichne_karte()
	_zeichne_spieler()
	_zeichne_hud()


func _zeichne_karte() -> void:
	for y in KARTE_HOEHE:
		for x in KARTE_BREITE:
			var typ: int = KARTE[y][x]
			var farbe: Color = FARBEN[typ] as Color
			var pixel_x := x * kachelgroesse
			var pixel_y := y * kachelgroesse
			var kachel_rect := Rect2(pixel_x, pixel_y, kachelgroesse, kachelgroesse)

			# Grundfarbe
			draw_rect(kachel_rect, farbe)

			# Obere und linke Kante etwas heller (Lichtquelle oben-links)
			var hell: Color = FARBEN_HELL[typ] as Color
			draw_line(
				Vector2(pixel_x, pixel_y),
				Vector2(pixel_x + kachelgroesse, pixel_y),
				hell, 1.5
			)
			draw_line(
				Vector2(pixel_x, pixel_y),
				Vector2(pixel_x, pixel_y + kachelgroesse),
				hell, 1.5
			)

			# Gitterlinien (optional)
			if zeige_gitterlinien:
				draw_rect(kachel_rect, Color(0.0, 0.0, 0.0, 0.12), false, 1.0)


func _zeichne_spieler() -> void:
	var pixel := Vector2(
		spieler_kachel.x * kachelgroesse,
		spieler_kachel.y * kachelgroesse
	)
	var g := kachelgroesse
	var rand := int(g * 0.15)

	# Schatten
	draw_rect(
		Rect2(pixel.x + rand + 2, pixel.y + rand + 3, g - rand * 2, g - rand * 2),
		Color(0.0, 0.0, 0.0, 0.25)
	)

	# Spieler-Körper (hellblau)
	draw_rect(
		Rect2(pixel.x + rand, pixel.y + rand, g - rand * 2, g - rand * 2),
		Color(0.25, 0.60, 0.95)
	)

	# Highlight oben-links
	draw_rect(
		Rect2(pixel.x + rand, pixel.y + rand, (g - rand * 2) * 0.5, (g - rand * 2) * 0.4),
		Color(1.0, 1.0, 1.0, 0.25)
	)

	# Richtungsindikator — kleiner Strich in Blickrichtung
	var mitte := pixel + Vector2(g / 2.0, g / 2.0)
	var zeiger_ende := mitte + Vector2(spieler_richtung) * (g * 0.28)
	draw_line(mitte, zeiger_ende, Color.WHITE, 2.5)
	draw_circle(zeiger_ende, maxf(2.0, g * 0.07), Color.WHITE)


func _zeichne_hud() -> void:
	# Proto-Name oben links im Kamerabereich anzeigen
	# (im echten Spiel kommt hier ein CanvasLayer hin)
	var kamera_offset := kamera.position - Vector2(640, 360)
	draw_string(
		ThemeDB.fallback_font,
		kamera_offset + Vector2(16, 28),
		proto_name,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		18,
		Color.WHITE
	)
	draw_string(
		ThemeDB.fallback_font,
		kamera_offset + Vector2(16, 50),
		"Pfeiltasten = bewegen",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		13,
		Color(1, 1, 1, 0.6)
	)
