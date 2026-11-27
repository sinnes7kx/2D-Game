extends RefCounted
## Cached original raster relief plates. Nine-slice bevels retain their
## thickness at different window sizes. No per-frame texture generation.
static var textures: Dictionary = {}

static func relief(bg: Color,metal: Color,deep: bool=false) -> Texture2D:
	var key: String = bg.to_html()+":"+metal.to_html()+":"+str(deep)
	if textures.has(key):
		return textures[key]
	var img: Image = Image.create(128,96,false,Image.FORMAT_RGBA8)
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed=274927
	noise.frequency=0.48
	for y in range(96):
		for x in range(128):
			var edge: int = mini(mini(x,127-x),mini(y,95-y))
			var grain: float = noise.get_noise_2d(float(x),float(y))*0.055
			var light: float = (0.50-float(y)/95.0)*0.105
			var weave: float = sin(float(x)*1.57)*sin(float(y)*1.57)*0.012
			var c: Color = bg.lightened(maxf(0.0,light+grain+weave)) if light+grain+weave>=0.0 else bg.darkened(-light-grain-weave)
			var lit: bool = x<128-x and x<=y or y<=x and y<96-y
			if edge==0: c=Color("09070c")
			elif edge==1: c=metal.darkened(0.54)
			elif edge==2: c=metal.lightened(0.35 if lit else 0.04)
			elif edge<=4: c=metal.darkened(0.17 if lit else 0.47)
			elif edge==5: c=metal.lightened(0.14)
			elif edge<=7: c=Color("100b12")
			elif edge==8: c=metal.darkened(0.56)
			elif edge==9: c=bg.darkened(0.31)
			elif edge==10: c=bg.lightened(0.075)
			elif deep and edge<15: c=c.darkened(float(15-edge)*0.045)
			img.set_pixel(x,y,c)
	var texture: ImageTexture = ImageTexture.create_from_image(img)
	textures[key]=texture
	return texture

static func plate(bg: Color,edge: Color,pad: int=7,deep: bool=false) -> StyleBoxTexture:
	var style: StyleBoxTexture = StyleBoxTexture.new()
	style.texture=relief(bg,edge,deep)
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
		style.set_texture_margin(side,11.0)
		style.set_content_margin(side,float(pad))
	return style
