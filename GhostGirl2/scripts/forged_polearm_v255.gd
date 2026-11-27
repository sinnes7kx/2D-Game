extends RefCounted
## Physical wood, leather and forged fittings. No effect intensity or RNG
## changes; all geometry uses the caller's existing authored endpoints.
const ART = preload("res://scripts/modular_weapon_art_v178.gd")

static func draw_haft(canvas: Node2D, foot: Vector2, grip: Vector2, head: Vector2, width: float, p: Dictionary) -> void:
	if foot.distance_squared_to(head) < 16.0:
		return
	var axis: Vector2 = (head-foot).normalized()
	var n: Vector2 = axis.orthogonal()
	var wood: Color = Color(p["grip"]).lerp(Color("655044"),0.38)
	var steel: Color = Color(p["metal"]).lerp(Color("777980"),0.35)
	var shadow: Color = steel.darkened(0.58)
	canvas.draw_line(foot,head,Color("221c22"),width+1.6,true)
	canvas.draw_line(foot,head,wood,width,true)
	canvas.draw_line(foot-n*width*0.27,head-n*width*0.27,wood.lightened(0.30),0.72,true)
	canvas.draw_line(foot+n*width*0.28,head+n*width*0.28,wood.darkened(0.42),0.85,true)
	# Broken longitudinal grain, fixed to the shaft rather than animated.
	for i in range(6):
		var u: float = 0.08 + float(i)*0.14
		var lateral: Vector2 = n*width*(0.14 if i%2==0 else -0.12)
		canvas.draw_line(foot.lerp(head,u)+lateral,foot.lerp(head,minf(u+0.085,0.94))+lateral,wood.darkened(0.19),0.45,true)
	ART.draw_grip(canvas,grip-axis*9.0,grip+axis*9.0,width+0.65,p)
	for at in [foot+axis*3.0,head-axis*8.0,head-axis*2.0]:
		canvas.draw_line(at-n*width*0.66,at+n*width*0.66,shadow,3.0,true)
		canvas.draw_line(at-n*width*0.54-axis*0.75,at+n*width*0.54-axis*0.75,steel.lightened(0.22),0.8,true)
	canvas.draw_line(head-axis*10.0,head,shadow,width+2.0,true)
	canvas.draw_line(head-axis*9.0-n*width*0.45,head-n*width*0.45,steel,0.85,true)
	for u in [0.25,0.70]:
		var at: Vector2 = (head-axis*10.0).lerp(head,u)
		canvas.draw_circle(at,0.95,shadow.darkened(0.25))
		canvas.draw_circle(at-axis*0.22-n*0.22,0.45,steel.lightened(0.30))

static func draw_fork(canvas: Node2D, head: Vector2, fork: Vector2, axis: Vector2, p: Dictionary) -> void:
	var steel: Color = p["metal"]
	var shade: Color = p["shade"]
	canvas.draw_line(head,fork,shade.darkened(0.25),3.7,true)
	canvas.draw_line(head,fork,steel.lerp(shade,0.3),2.3,true)
	canvas.draw_line(head-axis*0.65,fork-axis*0.65,Color(p["edge"]).lerp(steel,0.45),0.65,true)
