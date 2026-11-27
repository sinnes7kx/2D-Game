extends RefCounted
## Independent persisted visual setting. OFF returns to the previous room look.
const PERF = preload("res://scripts/performance_profiles_v230.gd")
const CONFIG: String = "user://ghost_girl_atmosphere_v278.cfg"
const NAMES: Array[String] = ["OFF","SUBTLE","CINEMATIC"]
static var preset: int = 2
static var revision: int = 0
static var loaded: bool = false

static func ensure_loaded() -> void:
	if loaded:
		return
	loaded=true
	var config: ConfigFile = ConfigFile.new()
	if config.load(CONFIG)==OK:
		preset=clampi(int(config.get_value("graphics","atmosphere",2)),0,2)

static func cycle() -> String:
	ensure_loaded()
	preset=(preset+1)%NAMES.size()
	revision+=1
	var config: ConfigFile = ConfigFile.new()
	config.set_value("graphics","atmosphere",preset)
	config.save(CONFIG)
	return NAMES[preset]

static func strength() -> float:
	ensure_loaded()
	return [0.0,0.55,1.0][preset]

static func light_budget() -> int:
	ensure_loaded()
	if preset==0:
		return 0
	match PERF.profile:
		PERF.Profile.LOW: return 3
		PERF.Profile.HIGH: return 8
		_: return 6

static func foreground_fog() -> bool:
	return strength()>0.0 and PERF.profile!=PERF.Profile.LOW
