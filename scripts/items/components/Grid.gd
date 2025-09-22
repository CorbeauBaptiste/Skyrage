class_name Grid
extends Node2D

var nombre_case_x: int
var nombre_case_y: int
var screen_size: Vector2
var grid_color: Color = Color.BLUE

func setup(cases_x: int, cases_y: int, screen: Vector2):
	nombre_case_x = cases_x
	nombre_case_y = cases_y
	screen_size = screen

func _draw():
	draw_grid()

func draw_grid():
	var case_width = screen_size.x / nombre_case_x
	var case_height = screen_size.y / nombre_case_y
	
	for x in nombre_case_x:
		for y in nombre_case_y:
			var rect = Rect2(
				Vector2(x * case_width, y * case_height),
				Vector2(case_width, case_height)
			)
			draw_rect(rect, grid_color, false)
