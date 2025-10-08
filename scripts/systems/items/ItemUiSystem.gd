class_name ItemUISystem
extends Node

const LABEL_FONT_SIZE: int = 20
const LABEL_OUTLINE_SIZE: int = 3
const LABEL_SHADOW_OFFSET: int = 2
const LABEL_ANIMATION_DURATION: float = 2.0
const LABEL_VERTICAL_OFFSET: float = 80.0
const LABEL_Z_INDEX: int = 100

func show_item_collected(item: Item, position: Vector2, parent: Node) -> void:
	"""
	Affiche un label quand un item est collecté
	Args:
		item: L'item qui a été collecté
		position: Position de spawn du label
		parent: Node parent où ajouter le label
	"""
	if item == null:
		push_error("ItemUISystem: L'item est null")
		return
	
	var label := _create_collection_label(item)
	parent.add_child(label)
	
	await parent.get_tree().process_frame
	
	# Calculer les positions de début et fin
	var label_size: Vector2 = _get_label_size(label)
	var viewport_size: Vector2 = parent.get_viewport().get_visible_rect().size
	var start_pos: Vector2 = _clamp_position(position + Vector2(-50, -30), label_size, viewport_size)
	var end_pos: Vector2 = _clamp_position(position + Vector2(-50, -LABEL_VERTICAL_OFFSET), label_size, viewport_size)
	
	label.position = start_pos
	
	_animate_label(label, end_pos, parent)


func _create_collection_label(item: Item) -> Label:
	"""
	Crée un label configuré pour afficher la collecte d'item
	Returns: Le label configuré
	"""
	var label := Label.new()
	
	# Texte et couleur
	label.text = item.name + " collecté!"
	label.modulate = _get_item_color(item)
	
	# Style du texte
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", LABEL_OUTLINE_SIZE)
	label.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	
	# Ombre
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("shadow_offset_x", LABEL_SHADOW_OFFSET)
	label.add_theme_constant_override("shadow_offset_y", LABEL_SHADOW_OFFSET)
	
	label.z_index = LABEL_Z_INDEX
	
	return label


func _get_label_size(label: Label) -> Vector2:
	"""
	Calcule la taille réelle du label en fonction de son texte
	Returns: Vector2 avec la taille du label
	"""
	var font := label.get_theme_default_font()
	var font_size := label.get_theme_font_size("font_size")
	
	return font.get_string_size(
		label.text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size
	)


func _animate_label(label: Label, end_position: Vector2, parent: Node) -> void:
	"""
	Anime le label (déplacement vers le haut + fade out)
	Args:
		label: Le label à animer
		end_position: Position finale du label
		parent: Node parent pour créer le tween
	"""
	var tween := parent.create_tween()
	
	# Animation parallèle : position + opacité
	tween.parallel().tween_property(
		label, 
		"position", 
		end_position, 
		LABEL_ANIMATION_DURATION
	)
	tween.parallel().tween_property(
		label, 
		"modulate:a", 
		0.0, 
		LABEL_ANIMATION_DURATION
	)
	
	# Supprimer le label à la fin de l'animation
	tween.tween_callback(label.queue_free)


func _get_item_color(item: Item) -> Color:
	"""
	Retourne la couleur du label en fonction du type d'item
	Args:
		item: L'item dont on veut la couleur
	Returns: Couleur correspondante (YELLOW pour bonus, RED pour malus)
	"""
	match item.type:
		Item.ItemType.BONUS:
			return Color.YELLOW
		Item.ItemType.MALUS:
			return Color.RED
		_:
			return Color.WHITE


func _clamp_position(pos: Vector2, label_size: Vector2, viewport_size: Vector2) -> Vector2:
	"""
	S'assure que le label reste dans les limites de l'écran
	Args:
		pos: Position souhaitée
		label_size: Taille du label
		viewport_size: Taille de l'écran
	Returns: Position contrainte
	"""
	return Vector2(
		clamp(pos.x, 0, viewport_size.x - label_size.x),
		clamp(pos.y, 0, viewport_size.y - label_size.y)
	)
