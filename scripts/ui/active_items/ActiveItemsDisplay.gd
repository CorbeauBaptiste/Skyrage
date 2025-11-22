class_name ActiveItemsDisplay
extends CanvasLayer

## Affiche les items actifs en haut à gauche de l'écran.
##
## Séparé en deux colonnes : Enfer (gauche) et Paradis (droite).
## Chaque item a une bordure animée qui montre le temps restant.

# ========================================
# CONFIGURATION
# ========================================

const DISPLAY_MARGIN: int = 20
const COLUMN_SPACING: int = 20
const ITEM_SPACING: int = 8
const COLUMN_WIDTH: int = 220

const HEADER_COLOR_ENFER: Color = Color(0.9, 0.3, 0.3)
const HEADER_COLOR_PARADIS: Color = Color(0.3, 0.7, 0.9)

# Durée d'affichage pour les items instantanés
const IMMEDIATE_DISPLAY_DURATION: float = 3.0

# ========================================
# REFERENCES UI
# ========================================

var main_container: HBoxContainer
var enfer_container: VBoxContainer
var paradis_container: VBoxContainer
var enfer_header: Label
var paradis_header: Label

# ========================================
# ITEMS TRACKING
# ========================================

var active_panels_enfer: Dictionary = {}
var active_panels_paradis: Dictionary = {}

# ========================================
# INITIALISATION
# ========================================

func _ready() -> void:
	layer = 50
	_setup_ui()


func _setup_ui() -> void:
	# Container principal en haut à gauche
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_TOP_LEFT)
	margin.add_theme_constant_override("margin_left", DISPLAY_MARGIN)
	margin.add_theme_constant_override("margin_top", DISPLAY_MARGIN)
	add_child(margin)

	# Container horizontal pour les deux colonnes
	main_container = HBoxContainer.new()
	main_container.add_theme_constant_override("separation", COLUMN_SPACING)
	margin.add_child(main_container)

	# Colonne Enfer
	enfer_container = _create_column("ENFER", HEADER_COLOR_ENFER)
	main_container.add_child(enfer_container)

	# Colonne Paradis
	paradis_container = _create_column("PARADIS", HEADER_COLOR_PARADIS)
	main_container.add_child(paradis_container)


func _create_column(title: String, color: Color) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = COLUMN_WIDTH
	column.add_theme_constant_override("separation", ITEM_SPACING)

	# Header de la colonne
	var header := Label.new()
	header.text = title
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", color)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.visible = false  # Visible quand il y a des items
	column.add_child(header)

	if title == "ENFER":
		enfer_header = header
	else:
		paradis_header = header

	return column

# ========================================
# PUBLIC API
# ========================================

## Ajoute un item actif à l'affichage.
## camp: "enfer" ou "paradis"
## item: L'item à afficher
## duration: Durée en secondes (0 pour les items sans durée, utilise IMMEDIATE_DISPLAY_DURATION)
func add_active_item(camp: String, item: Item, duration: float) -> void:
	# Pour les items instantanés, on utilise une durée d'affichage fixe
	var display_duration := duration
	if item.effect_type == Item.EffectType.IMMEDIATE or duration <= 0:
		display_duration = IMMEDIATE_DISPLAY_DURATION

	var is_enfer := camp == "enfer"
	var container := enfer_container if is_enfer else paradis_container
	var panels := active_panels_enfer if is_enfer else active_panels_paradis
	var header := enfer_header if is_enfer else paradis_header

	# Si l'item est déjà actif, refresh son timer
	if panels.has(item.name):
		var existing_panel: ActiveItemPanel = panels[item.name]
		existing_panel.setup(item, display_duration)
		return

	# Crée un nouveau panel
	var panel := ActiveItemPanel.new()
	panel.timer_finished.connect(_on_panel_timer_finished)
	container.add_child(panel)
	panel.setup(item, display_duration)

	panels[item.name] = panel

	# Affiche le header si c'est le premier item
	header.visible = true


## Retire un item de l'affichage.
func remove_active_item(camp: String, item_name: String) -> void:
	var is_enfer := camp == "enfer"
	var panels := active_panels_enfer if is_enfer else active_panels_paradis
	var header := enfer_header if is_enfer else paradis_header

	if panels.has(item_name):
		var panel: ActiveItemPanel = panels[item_name]
		panel.queue_free()
		panels.erase(item_name)

	# Cache le header si plus d'items
	if panels.is_empty():
		header.visible = false


## Vérifie si un item est actif.
func has_active_item(camp: String, item_name: String) -> bool:
	var panels := active_panels_enfer if camp == "enfer" else active_panels_paradis
	return panels.has(item_name)


## Retourne le temps restant d'un item actif.
func get_remaining_time(camp: String, item_name: String) -> float:
	var panels := active_panels_enfer if camp == "enfer" else active_panels_paradis
	if panels.has(item_name):
		var panel: ActiveItemPanel = panels[item_name]
		return panel.remaining_time
	return 0.0

# ========================================
# CALLBACKS
# ========================================

func _on_panel_timer_finished(panel: ActiveItemPanel) -> void:
	# Trouve le camp du panel
	var item_name := panel.item.name

	if active_panels_enfer.has(item_name):
		remove_active_item("enfer", item_name)
	elif active_panels_paradis.has(item_name):
		remove_active_item("paradis", item_name)
