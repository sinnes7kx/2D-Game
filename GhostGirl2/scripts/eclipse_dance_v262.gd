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
