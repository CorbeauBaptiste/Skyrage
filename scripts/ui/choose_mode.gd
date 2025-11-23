extends Control

## Script du menu de sélection du mode de jeu.
##
## Gère les 3 boutons de mode et la popup de sélection d'équipe IA.

# ========================================
# NODES
# ========================================

@onready var mode1_btn: Button = $VBoxContainer/mode1
@onready var mode2_btn: Button = $VBoxContainer/mode2
@onready var mode3_btn: Button = $VBoxContainer/mode3

# Popup pour le choix de l'équipe IA
var team_popup: Control = null

# ========================================
# INITIALISATION
# ========================================

func _ready() -> void:
	mode1_btn.pressed.connect(_on_mode1_pressed)
	mode2_btn.pressed.connect(_on_mode2_pressed)
	mode3_btn.pressed.connect(_on_mode3_pressed)


# ========================================
# MODE 1 : JOUEUR VS JOUEUR
# ========================================

func _on_mode1_pressed() -> void:
	GameMode.set_pvp()
	_start_game()


# ========================================
# MODE 2 : JOUEUR VS IA
# ========================================

func _on_mode2_pressed() -> void:
	_show_team_selection_popup()


## Affiche la popup pour choisir quelle équipe sera l'IA.
func _show_team_selection_popup() -> void:
	if team_popup:
		team_popup.queue_free()

	# Créer la popup
	team_popup = Control.new()
	team_popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(team_popup)

	# Fond sombre derrière la popup
	var overlay: ColorRect = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.05, 0.05, 0.1, 0.9)
	team_popup.add_child(overlay)

	# Container central
	var center_container: CenterContainer = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	team_popup.add_child(center_container)

	# Panel principal avec fond
	var panel: PanelContainer = PanelContainer.new()
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.15, 0.12, 0.2, 1.0)
	panel_style.border_color = Color(0.6, 0.5, 0.3, 1.0)
	panel_style.set_border_width_all(4)
	panel_style.set_corner_radius_all(16)
	panel_style.set_content_margin_all(40)
	panel.add_theme_stylebox_override("panel", panel_style)
	center_container.add_child(panel)

	# VBox pour le contenu
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 40)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	# Titre
	var title: Label = Label.new()
	title.text = "CHOISISSEZ L'ÉQUIPE DE L'IA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7, 1.0))
	vbox.add_child(title)

	# Container boutons équipes (centré)
	var btn_container: HBoxContainer = HBoxContainer.new()
	btn_container.add_theme_constant_override("separation", 60)
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_container)

	# Bouton Enfer
	var btn_enfer: Button = Button.new()
	btn_enfer.text = "ENFER"
	btn_enfer.custom_minimum_size = Vector2(220, 90)
	btn_enfer.add_theme_font_size_override("font_size", 30)
	var style_enfer: StyleBoxFlat = StyleBoxFlat.new()
	style_enfer.bg_color = Color(0.6, 0.15, 0.1, 1.0)
	style_enfer.border_color = Color(0.9, 0.3, 0.2, 1.0)
	style_enfer.set_border_width_all(3)
	style_enfer.set_corner_radius_all(10)
	btn_enfer.add_theme_stylebox_override("normal", style_enfer)
	var style_enfer_hover: StyleBoxFlat = style_enfer.duplicate()
	style_enfer_hover.bg_color = Color(0.75, 0.2, 0.15, 1.0)
	btn_enfer.add_theme_stylebox_override("hover", style_enfer_hover)
	var style_enfer_pressed: StyleBoxFlat = style_enfer.duplicate()
	style_enfer_pressed.bg_color = Color(0.5, 0.1, 0.08, 1.0)
	btn_enfer.add_theme_stylebox_override("pressed", style_enfer_pressed)
	btn_enfer.pressed.connect(_on_ia_team_selected.bind("enfer"))
	btn_container.add_child(btn_enfer)

	# Bouton Paradis
	var btn_paradis: Button = Button.new()
	btn_paradis.text = "PARADIS"
	btn_paradis.custom_minimum_size = Vector2(220, 90)
	btn_paradis.add_theme_font_size_override("font_size", 30)
	var style_paradis: StyleBoxFlat = StyleBoxFlat.new()
	style_paradis.bg_color = Color(0.9, 0.85, 0.7, 1.0)
	style_paradis.border_color = Color(1.0, 0.95, 0.8, 1.0)
	style_paradis.set_border_width_all(3)
	style_paradis.set_corner_radius_all(10)
	btn_paradis.add_theme_stylebox_override("normal", style_paradis)
	btn_paradis.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1, 1.0))
	var style_paradis_hover: StyleBoxFlat = style_paradis.duplicate()
	style_paradis_hover.bg_color = Color(1.0, 0.95, 0.85, 1.0)
	btn_paradis.add_theme_stylebox_override("hover", style_paradis_hover)
	btn_paradis.add_theme_color_override("font_hover_color", Color(0.1, 0.1, 0.1, 1.0))
	btn_paradis.add_theme_color_override("font_pressed_color", Color(0.1, 0.1, 0.1, 1.0))
	var style_paradis_pressed: StyleBoxFlat = style_paradis.duplicate()
	style_paradis_pressed.bg_color = Color(0.75, 0.7, 0.55, 1.0)
	btn_paradis.add_theme_stylebox_override("pressed", style_paradis_pressed)
	btn_paradis.pressed.connect(_on_ia_team_selected.bind("paradis"))
	btn_container.add_child(btn_paradis)

	# Container pour centrer le bouton Annuler
	var cancel_container: CenterContainer = CenterContainer.new()
	vbox.add_child(cancel_container)

	# Bouton Annuler
	var btn_cancel: Button = Button.new()
	btn_cancel.text = "ANNULER"
	btn_cancel.custom_minimum_size = Vector2(160, 50)
	btn_cancel.add_theme_font_size_override("font_size", 20)
	var style_cancel: StyleBoxFlat = StyleBoxFlat.new()
	style_cancel.bg_color = Color(0.3, 0.3, 0.35, 1.0)
	style_cancel.border_color = Color(0.5, 0.5, 0.55, 1.0)
	style_cancel.set_border_width_all(2)
	style_cancel.set_corner_radius_all(8)
	btn_cancel.add_theme_stylebox_override("normal", style_cancel)
	var style_cancel_hover: StyleBoxFlat = style_cancel.duplicate()
	style_cancel_hover.bg_color = Color(0.4, 0.4, 0.45, 1.0)
	btn_cancel.add_theme_stylebox_override("hover", style_cancel_hover)
	btn_cancel.pressed.connect(_close_popup)
	cancel_container.add_child(btn_cancel)


## Callback quand une équipe IA est sélectionnée.
func _on_ia_team_selected(team: String) -> void:
	GameMode.set_pv_ia(team)
	_close_popup()
	_start_game()


## Ferme la popup de sélection.
func _close_popup() -> void:
	if team_popup:
		team_popup.queue_free()
		team_popup = null


# ========================================
# MODE 3 : IA VS IA
# ========================================

func _on_mode3_pressed() -> void:
	GameMode.set_ia_v_ia()
	_start_game()


# ========================================
# UTILITAIRES
# ========================================

## Lance la partie.
func _start_game() -> void:
	get_tree().change_scene_to_file("res://scenes/main/world.tscn")
