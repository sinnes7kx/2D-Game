extends SceneTree
const PERF = preload("res://scripts/performance_profiles_v230.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _count(hz: float, render_hz: int) -> int:
	var accumulated: float = 0.0
	var updates: int = 0
	for i in range(render_hz * 4):
		accumulated += 1.0 / float(render_hz)
		if PERF.due(accumulated, hz):
			updates += 1
			accumulated = PERF.remainder(accumulated, hz)
	return updates

func _verify() -> void:
	for profile in [PERF.Profile.HIGH, PERF.Profile.BALANCED, PERF.Profile.LOW]:
		PERF.profile = profile
		var ambient: float = PERF.ambient_hz()
		var rain: float = PERF.rain_hz()
		for render_hz in [60, 120, 144]:
			var expected_ambient: float = float(render_hz * 4) if ambient <= 0.0 else ambient * 4.0
			var expected_rain: float = float(render_hz * 4) if rain <= 0.0 else rain * 4.0
			if absf(float(_count(ambient, render_hz)) - expected_ambient) > 1.0 or absf(float(_count(rain, render_hz)) - expected_rain) > 1.0:
				_fail("Cadence drifted from target")
				return
		if not is_equal_approx(PERF.rain_density(), 0.60 if profile == PERF.Profile.LOW else 1.0):
			_fail("Unexpected rain density")
			return
	PERF.profile = PERF.Profile.BALANCED
	var before: int = PERF.revision
	PERF.cycle()
	if PERF.profile != PERF.Profile.LOW or PERF.revision != before + 1:
		_fail("Profile cycle did not invalidate decorations")
		return
	PERF.cycle()
	PERF.cycle()
	if PERF.profile != PERF.Profile.BALANCED:
		_fail("Profile cycle failed to restore balanced")
		return
	print("v2.30 PASS: visual-only profiles and cadence budgets at 60/120/144 Hz")
	quit(0)

func _fail(reason: String) -> void:
	push_error(reason)
	quit(1)
