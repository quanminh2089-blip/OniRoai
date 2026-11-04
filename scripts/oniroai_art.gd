extends RefCounted

static var cache: Dictionary = {}
const PARTS = {
	"joy_base": ["controls", Rect2(27, 27, 374, 380)], 
	"joy_thumb": ["controls", Rect2(462, 54, 326, 332)], 
	"fire_base": ["controls", Rect2(849, 26, 375, 382)], 
	"fire_thumb": ["controls", Rect2(31, 446, 363, 369)], 
	"crouch": ["controls", Rect2(443, 444, 363, 370)], 
	"jump": ["controls", Rect2(853, 444, 364, 370)], 
	"aim": ["controls", Rect2(26, 851, 371, 378)], 
	"run": ["controls", Rect2(440, 852, 369, 377)], 
	"pause": ["controls", Rect2(896, 897, 282, 289)], 
	"score": ["frames", Rect2(30, 80, 1194, 194)], 
	"ammo": ["frames", Rect2(75, 389, 1105, 351)], 
	"mp5": ["frames", Rect2(83, 799, 1087, 447)], 
	"rail": ["frames", Rect2(116, 109, 270, 4)], 
	"flash_0": ["fx", Rect2(202, 195, 238, 255)], 
	"flash_1": ["fx", Rect2(815, 199, 259, 248)], 
	"smoke_0": ["fx", Rect2(224, 735, 210, 395)], 
	"smoke_1": ["fx", Rect2(775, 731, 355, 410)]}
static func sprite(id: String) -> Texture2D:
	if cache.has(id): return cache[id]
	if not PARTS.has(id):
		cache[id] = load("res://assets/oniroai/" + id + ".png")
	else:
		var part = PARTS[id]
		var texture = AtlasTexture.new()
		texture.atlas = load("res://assets/oniroai/" + part[0] + ".png")
		texture.region = part[1]
		texture.filter_clip = true
		cache[id] = texture
	return cache[id]
