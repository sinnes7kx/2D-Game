extends RefCounted
## Presentation only. Session setting; never affects simulation or item rolls.
enum Profile { HIGH, BALANCED, LOW }
static var profile: int = Profile.BALANCED
static var revision: int = 0

static func cycle() -> void:
	profile = (profile + 1) % 3
	revision += 1

static func label() -> String:
	match profile:
		Profile.HIGH: return "High"
		Profile.LOW: return "Low"
		_: return "Balanced"

static func ambient_hz() -> float:
	match profile:
		Profile.HIGH: return 0.0 # Every rendered frame.
		Profile.LOW: return 15.0
		_: return 30.0

static func rain_hz() -> float:
	match profile:
		Profile.HIGH: return 0.0
		Profile.LOW: return 30.0
		_: return 45.0

static func rain_density() -> float:
	return 0.60 if profile == Profile.LOW else 1.0

static func due(accumulated: float, hz: float) -> bool:
	return hz <= 0.0 or accumulated + 0.000001 >= 1.0 / hz

static func remainder(accumulated: float, hz: float) -> float:
	if hz <= 0.0:
		return 0.0
	var interval: float = 1.0 / hz
	var result: float = fposmod(accumulated, interval)
	return 0.0 if result >= interval - 0.000001 else result
