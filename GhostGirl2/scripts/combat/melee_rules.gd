extends RefCounted
## Pure base melee tuning. The player owns action state, equipment modifiers,
## contact, damage application and feedback. Keep art geometry independent.
## Vector4: reach, base power (before item damage), minimum forward dot, poise.
static func base_profile(style: String, heavy: bool, armed: bool, combo: int) -> Vector4:
	var reach: float = (174.0 if heavy else 144.0) if armed else (128.0 if heavy else 106.0)
	var power: float = 34.0 if heavy else [16.0, 19.0, 24.0][combo]
	var attack_arc: float = 0.12 if heavy else 0.32
	var poise_bonus: float = 1.0
	match style:
		"scythe":
			reach = 216.0 if heavy else 184.0
			power *= 1.06 if heavy else 0.95
			attack_arc = -0.05 if heavy else 0.12
			poise_bonus = 1.12
		"halberd":
			reach = 242.0 if heavy else 206.0
			power *= 1.28 if heavy else 1.08
			attack_arc = 0.34 if heavy else 0.48
			poise_bonus = 1.35
		"dagger":
			reach = 143.0 if heavy else 112.0
			power *= 0.90 if heavy else 0.77
			# Dagger strikes have a narrow forward hit cone, not a sweep.
			attack_arc = 0.08 if heavy else 0.10
			poise_bonus = 0.70
		"dual_dagger":
			reach = 153.0 if heavy else 122.0
			power *= 0.96 if heavy else 0.80
			attack_arc = 0.14 if heavy else 0.15
			poise_bonus = 0.73
		"dual_sword":
			reach = 199.0 if heavy else 165.0
			power *= 1.18 if heavy else 0.97
			attack_arc = 0.08 if heavy else 0.12
			poise_bonus = 0.96
		"spear":
			reach = 252.0 if heavy else 213.0
			power *= 1.18 if heavy else 0.96
			attack_arc = 0.64 if heavy else 0.71
			poise_bonus = 1.12
		"rapier":
			reach = 214.0 if heavy else 176.0
			power *= 1.10 if heavy else 0.94
			attack_arc = 0.86 if heavy else 0.91
			poise_bonus = 0.85
		"axe":
			reach = 208.0 if heavy else 172.0
			power *= 1.37 if heavy else 1.09
			attack_arc = -0.02 if heavy else 0.15
			poise_bonus = 1.52
		"maul":
			# Slow and committed, with a broad impact and exceptional stagger.
			reach = 211.0 if heavy else 173.0
			power *= 1.45 if heavy else 1.13
			attack_arc = 0.04 if heavy else 0.23
			poise_bonus = 1.65
		"twinblade":
			# Each committed heavy spin has two separately timed physical cuts.
			reach = 206.0 if heavy else 168.0
			power *= 1.05 if heavy else 0.87
			attack_arc = -0.10 if heavy else 0.01
			poise_bonus = 0.85
	return Vector4(reach,power,attack_arc,poise_bonus)

# Shared normalized frontal contact geometry for timed guards and weapon
# techniques. Individual callers keep their own range and minimum distance.
static func frontal_contact(offset: Vector2, axis: Vector2, min_distance_squared: float, max_distance: float, min_dot: float) -> bool:
	if offset.length_squared()<=min_distance_squared or axis.is_zero_approx():
		return false
	if max_distance>=0.0 and offset.length_squared()>max_distance*max_distance:
		return false
	return axis.normalized().dot(offset.normalized())>=min_dot
