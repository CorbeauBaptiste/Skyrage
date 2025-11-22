class_name ActiveItemPanel
extends PanelContainer

## Panel affichant un item actif avec sa description et un timer visuel.
##
## Le contour du panel agit comme une progress bar qui se vide
## au fur et à mesure que la durée de l'item diminue.

signal timer_finished(panel: ActiveItemPanel)

# ========================================
# CONFIGURATION
# ========================================

const BORDER_WIDTH: int = 4
const BORDER_MARGIN: int = -4 # Entre la bordure animée et le texte
const PANEL_MIN_WIDTH: int = 200
const PANEL_MIN_HEIGHT: int = 60

const COLOR_BONUS: Color = Color(0.2, 0.8, 0.2, 1.0)  # Vert
const COLOR_MALUS: Color = Color(0.8, 0.2, 0.2, 1.0)  # Rouge
const COLOR_BACKGROUND: Color = Color(0.1, 0.1, 0.1, 0.9)
const COLOR_BORDER_EMPTY: Color = Color(0.3, 0.3, 0.3, 0.8)

# ========================================
# REFERENCES UI
# ========================================

var name_label: Label
var description_label: Label
var timer_label: Label
var border_progress: Control  # Control custom pour dessiner la bordure animée

# ========================================
# STATES
# ========================================

var item: Item
var total_duration: float
var remaining_time: float
var is_active: bool = false
var border_color: Color

# ========================================
# INITIALISATION
# ========================================

func _ready() -> void:
	custom_minimum_size = Vector2(PANEL_MIN_WIDTH, PANEL_MIN_HEIGHT)
	_setup_style()
	_setup_layout()


func _setup_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_BACKGROUND
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	add_theme_stylebox_override("panel", style)


func _setup_layout() -> void:
	# Container principal vertical
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	add_child(vbox)

	# Nom de l'item (en haut)
	name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(name_label)

	# Description (au milieu)
	description_label = Label.new()
	description_label.add_theme_font_size_override("font_size", 11)
	description_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(description_label)

	# Timer (en bas a droite)
	timer_label = Label.new()
	timer_label.add_theme_font_size_override("font_size", 12)
	timer_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(timer_label)

	# Control pour la bordure animée
	border_progress = Control.new()
	border_progress.set_anchors_preset(Control.PRESET_FULL_RECT)
	border_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border_progress.draw.connect(_draw_border)
	add_child(border_progress)

# ========================================
# ITEM CONFIGURATION
# ========================================

func setup(p_item: Item, duration: float) -> void:
	item = p_item
	total_duration = duration
	remaining_time = duration
	is_active = true

	# Couleur selon le type
	border_color = COLOR_BONUS if item.type == Item.ItemType.BONUS else COLOR_MALUS

	# Mise a jour des labels
	name_label.text = item.name
	name_label.modulate = border_color
	description_label.text = item.effect_description
	_update_timer_display()

	border_progress.queue_redraw()

# ========================================
# UPDATE
# ========================================

func _process(delta: float) -> void:
	if not is_active:
		return

	remaining_time -= delta

	if remaining_time <= 0:
		remaining_time = 0
		is_active = false
		timer_finished.emit(self)

	_update_timer_display()
	border_progress.queue_redraw()


func _update_timer_display() -> void:
	var seconds := int(remaining_time)
	var decimals := int((remaining_time - seconds) * 10)
	timer_label.text = "%d.%ds" % [seconds, decimals]

# ========================================
# DRAW OF ANIMATED BORDER
# ========================================

func _draw_border() -> void:
	if total_duration <= 0:
		return

	var rect := border_progress.get_rect()
	var progress := remaining_time / total_duration

	# Dessine la bordure "vide" (grise)
	_draw_border_rect(rect, COLOR_BORDER_EMPTY)

	# Puis la bordure "pleine" qui diminue au fil du temps
	_draw_progress_border(rect, border_color, progress)


func _draw_border_rect(rect: Rect2, color: Color) -> void:
	# Bordure complete avec offset pour la marge
	var margin: float = BORDER_MARGIN
	var width: float = rect.size.x
	var height: float = rect.size.y
	var points := PackedVector2Array([
		Vector2(margin, margin),
		Vector2(width - margin, margin),
		Vector2(width - margin, height - margin),
		Vector2(margin, height - margin),
		Vector2(margin, margin)
	])

	for i in range(points.size() - 1):
		border_progress.draw_line(points[i], points[i + 1], color, BORDER_WIDTH)


func _draw_progress_border(rect: Rect2, color: Color, progress: float) -> void:
	# Offset pour la marge
	var margin: float = BORDER_MARGIN
	var width: float = rect.size.x
	var height: float = rect.size.y

	# Calcul du périmètre total (avec marge)
	var inner_w: float = width - margin * 2
	var inner_h: float = height - margin * 2
	var perimeter: float = 2 * (inner_w + inner_h)
	var draw_length: float = perimeter * progress

	if draw_length <= 0:
		return

	# Points de la bordure dans l'ordre (sens horaire depuis le haut-gauche) avec offset
	var segments: Array = [
		{"start": Vector2(margin, margin), "end": Vector2(width - margin, margin), "length": inner_w},
		{"start": Vector2(width - margin, margin), "end": Vector2(width - margin, height - margin), "length": inner_h},
		{"start": Vector2(width - margin, height - margin), "end": Vector2(margin, height - margin), "length": inner_w},
		{"start": Vector2(margin, height - margin), "end": Vector2(margin, margin), "length": inner_h}
	]

	var remaining_length: float = draw_length

	for seg in segments:
		if remaining_length <= 0:
			break

		var seg_length: float = seg.length

		if remaining_length >= seg_length:
			# Dessine le segment complet
			border_progress.draw_line(seg.start, seg.end, color, BORDER_WIDTH)
			remaining_length -= seg_length
		else:
			# Dessine une partie du segment
			var t: float = remaining_length / seg_length
			var partial_end: Vector2 = seg.start.lerp(seg.end, t)
			border_progress.draw_line(seg.start, partial_end, color, BORDER_WIDTH)
			remaining_length = 0
