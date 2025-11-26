extends Node

## Autoload gérant le mode de jeu sélectionné.
##
## Stocke le type de partie (PvP, PvIA, IAvIA) et
## quelles équipes sont contrôlées par l'IA.

# ========================================
# ÉNUMÉRATIONS
# ========================================

## Types de modes de jeu disponibles.
enum Mode {
	PVP,      ## Joueur vs Joueur
	PV_IA,    ## Joueur vs IA
	IA_V_IA   ## IA vs IA
}

# ========================================
# ÉTAT
# ========================================

## Mode de jeu actuel.
var current_mode: Mode = Mode.PVP

## Indique si l'équipe Enfer est contrôlée par l'IA.
var enfer_is_ai: bool = false

## Indique si l'équipe Paradis est contrôlée par l'IA.
var paradis_is_ai: bool = false

# ========================================
# MÉTHODES
# ========================================

## Configure le mode PvP (aucune IA).
func set_pvp() -> void:
	current_mode = Mode.PVP
	enfer_is_ai = false
	paradis_is_ai = false
	print("[GameMode] Mode: Joueur vs Joueur")


## Configure le mode PvIA avec l'équipe IA spécifiée.
##
## @param ia_team: "enfer" ou "paradis" pour l'équipe contrôlée par l'IA
func set_pv_ia(ia_team: String) -> void:
	current_mode = Mode.PV_IA
	enfer_is_ai = (ia_team == "enfer")
	paradis_is_ai = (ia_team == "paradis")
	print("[GameMode] Mode: Joueur vs IA (IA: %s)" % ia_team)


## Configure le mode IAvIA (les deux équipes en IA).
func set_ia_v_ia() -> void:
	current_mode = Mode.IA_V_IA
	enfer_is_ai = true
	paradis_is_ai = true
	print("[GameMode] Mode: IA vs IA")


## Vérifie si une équipe est contrôlée par l'IA.
##
## @param team: "enfer" ou "paradis"
## @return: true si l'équipe est contrôlée par l'IA
func is_team_ai(team: String) -> bool:
	if team == "enfer":
		return enfer_is_ai
	elif team == "paradis":
		return paradis_is_ai
	return false


## Vérifie si une équipe est contrôlée par un joueur.
##
## @param team: "enfer" ou "paradis"
## @return: true si l'équipe est contrôlée par un joueur humain
func is_team_player(team: String) -> bool:
	return not is_team_ai(team)


## Réinitialise au mode par défaut (PvP).
func reset() -> void:
	set_pvp()
