extends RefCounted
## Deterministic two-stage skill timeline. One pulse per threshold, not per
## rendered frame or particle. Distances are world units, speeds units/second.
const ID: String = "eclipse_dance"
const FIRST: float = 1.18
const FOLLOW: float = 0.74
const FOLLOW_COST: float = 12.0
const FIRST_HITS: Array[float] = [0.20,0.43,0.67,0.91]
const FOLLOW_HITS: Array[float] = [0.14,0.34]

static func duration(stage: int) -> float:
	return FIRST if stage == 1 else FOLLOW

static func timings(stage: int) -> Array[float]:
	return FIRST_HITS if stage == 1 else FOLLOW_HITS

static func can_chain(elapsed: float) -> bool:
	return elapsed >= 0.38 and elapsed <= 1.10

static func motion(stage: int, elapsed: float) -> float:
	if stage == 1:
		return 245.0*sin(clampf((elapsed-0.06)/0.94,0.0,1.0)*PI)
	if elapsed < 0.30:
		return 100.0*sin(clampf(elapsed/0.30,0.0,1.0)*PI)
	return -310.0*sin(clampf((elapsed-0.30)/0.43,0.0,1.0)*PI)

static func spin(stage: int, elapsed: float) -> float:
	var progress: float = clampf(elapsed/duration(stage),0.0,1.0)
	return TAU*(2.0 if stage == 1 else -1.0)*progress

static func hit_multiplier(stage: int, index: int) -> float:
	if stage == 1:
		return 0.27 if index < 3 else 0.36
	return 0.24 if index == 0 else 0.34

# Presentation turns follow the same physics timeline as the damage gates.
# Four genuinely authored heavy clips, not a mirrored body or a new atlas.
const FACES: Array[String] = ["right","front","left","back"]

static func facing_at(heading: Vector2, stage: int, elapsed: float) -> String:
	return FACES[posmod(roundi((heading.angle()+spin(stage,elapsed))/(PI*0.5)),4)]

static func frame_at(stage: int, elapsed: float, count: int) -> int:
	if count <= 1:
		return 0
	var turns: float = 2.0 if stage == 1 else 1.0
	var phase: float = clampf(elapsed/duration(stage),0.0,1.0)*turns
	return clampi(int(floor(fposmod(phase,1.0)*float(count))),0,count-1)

static func blade_axis(heading: Vector2, stage: int, elapsed: float) -> Vector2:
	# Absolute angle prevents the underlying cardinal guide from adding a
	# second discontinuous rotation whenever the illustrated body turns.
	return heading.normalized().rotated(spin(stage,elapsed)-PI*0.25)

static func chain_remaining(elapsed: float) -> float:
	return clampf((1.10-elapsed)/0.72,0.0,1.0) if can_chain(elapsed) else 0.0
