extends Node

# UNITE
# -------------------------------------------
const UNITS = {
	"paradis": {
		"archange": preload("res://scenes/entities/units/paradise/archange.tscn"),
		"ange": preload("res://scenes/entities/units/paradise/ange.tscn"),
		"seraphin": preload("res://scenes/entities/units/paradise/seraphin.tscn")
	},
	"enfer": {
		"diablotin": preload("res://scenes/entities/units/hell/diablotin.tscn"),
		"ange_dechu": preload("res://scenes/entities/units/hell/ange_dechu.tscn"),
		"demon": preload("res://scenes/entities/units/hell/demon.tscn")
	}
}

# NOMBRE UNITE A SPAWN
# -------------------------------------------
const SPAWN_COUNTS = {
	"archange": 3,
	"ange": 2,
	"seraphin": 1,
	"diablotin": 3,
	"ange_dechu": 2,
	"demon": 1
}

# PRIX UNITE
# -------------------------------------------
const UNIT_COSTS = {
	"archange": 	5.0, # 5.0
	"ange": 		10.0, # 10.0
	"seraphin": 	15.0, # 15.0 
	"diablotin": 	6.0, # 6.0
	"ange_dechu": 	11.0, # 11.0
	"demon": 		16.0, # 16.0
}

# CONFIGURATION DE L'OR
# -------------------------------------------
const GOLD_CONFIG = {
	"max_gold": 50.0,
	"regen_per_sec": 10.0,
	"overtime_multiplier": 2.0,
	"overtime_threshold": MATCH_DURATION - 60.0 # TEMPS GLOBAL - 1 MINIUTES
}

# DUREE DES PHASES
# -------------------------------------------
const PHASE_DURATION = 12.0

# DUREE DU MATCH
# -------------------------------------------
const MATCH_DURATION = 300.0  # 5 minutes
