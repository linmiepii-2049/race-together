extends RefCounted

## 不透明像素 alpha 門檻（低於此當透明）
const OPAQUE_THRESHOLD := 0.12
## 邊界各內縮像素（貼圖空間），減少邊緣誤觸
const BOUNDS_SHRINK_PX := 5
## 粗採樣步長，再於範圍內細掃
const COARSE_STEP := 4

static var _opaque_bounds_cache: Dictionary = {}


## 依貼圖「不透明區域」緊密 AABB 同步矩形碰撞與 CollisionShape2D 位移（Sprite2D 須 centered、等比例 scale）。
func sync_rect_shape_to_sprite(collision_shape: CollisionShape2D, sprite: Sprite2D) -> void:
	if collision_shape == null or sprite == null or sprite.texture == null:
		return
	if not (collision_shape.shape is RectangleShape2D):
		return
	var tex: Texture2D = sprite.texture
	var img: Image = tex.get_image()
	if img == null:
		_sync_full_texture_rect(collision_shape, sprite)
		return
	var tw: int = img.get_width()
	var th: int = img.get_height()
	if tw < 1 or th < 1:
		_sync_full_texture_rect(collision_shape, sprite)
		return
	var cache_key: String = tex.resource_path if tex.resource_path else str(tex.get_rid())
	cache_key += "|%d|%d" % [tw, th]
	var sub_px: Rect2i
	if _opaque_bounds_cache.has(cache_key):
		sub_px = _opaque_bounds_cache[cache_key]
	else:
		if img.detect_alpha() == Image.ALPHA_NONE:
			sub_px = Rect2i(0, 0, tw, th)
		else:
			sub_px = _compute_opaque_bounds_rect(img)
			if sub_px.size.x < 4 or sub_px.size.y < 4:
				sub_px = Rect2i(0, 0, tw, th)
		_opaque_bounds_cache[cache_key] = sub_px
	_apply_subrect_to_collision(collision_shape, sprite, sub_px, tw, th)


func _sync_full_texture_rect(collision_shape: CollisionShape2D, sprite: Sprite2D) -> void:
	collision_shape.position = Vector2.ZERO
	var rect := collision_shape.shape as RectangleShape2D
	var ext: Vector2 = sprite.texture.get_size() * sprite.scale.abs()
	rect.size = Vector2(absf(ext.x), absf(ext.y))


func _compute_opaque_bounds_rect(img: Image) -> Rect2i:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var min_x: int = w
	var min_y: int = h
	var max_x: int = -1
	var max_y: int = -1
	for y in range(0, h, COARSE_STEP):
		for x in range(0, w, COARSE_STEP):
			if img.get_pixel(x, y).a > OPAQUE_THRESHOLD:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	if max_x < 0:
		return Rect2i(0, 0, w, h)
	min_x = clampi(min_x - COARSE_STEP, 0, w - 1)
	min_y = clampi(min_y - COARSE_STEP, 0, h - 1)
	max_x = clampi(max_x + COARSE_STEP, 0, w - 1)
	max_y = clampi(max_y + COARSE_STEP, 0, h - 1)
	var min_x2: int = w
	var min_y2: int = h
	var max_x2: int = -1
	var max_y2: int = -1
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			if img.get_pixel(x, y).a > OPAQUE_THRESHOLD:
				min_x2 = mini(min_x2, x)
				min_y2 = mini(min_y2, y)
				max_x2 = maxi(max_x2, x)
				max_y2 = maxi(max_y2, y)
	if max_x2 < 0:
		return Rect2i(0, 0, w, h)
	min_x2 += BOUNDS_SHRINK_PX
	min_y2 += BOUNDS_SHRINK_PX
	max_x2 -= BOUNDS_SHRINK_PX
	max_y2 -= BOUNDS_SHRINK_PX
	if min_x2 > max_x2 or min_y2 > max_y2:
		return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
	return Rect2i(min_x2, min_y2, max_x2 - min_x2 + 1, max_y2 - min_y2 + 1)


func _apply_subrect_to_collision(
	collision_shape: CollisionShape2D, sprite: Sprite2D, sub_px: Rect2i, tw: int, th: int
) -> void:
	var sx: float = absf(sprite.scale.x)
	var sy: float = absf(sprite.scale.y)
	var s: float = sx
	if absf(sx - sy) > 0.0001:
		s = minf(sx, sy)
	var wpx: int = sub_px.size.x
	var hpx: int = sub_px.size.y
	var min_x: int = sub_px.position.x
	var min_y: int = sub_px.position.y
	var center_tex := Vector2(float(min_x) + float(wpx) * 0.5, float(min_y) + float(hpx) * 0.5)
	var full_center := Vector2(float(tw) * 0.5, float(th) * 0.5)
	collision_shape.position = (center_tex - full_center) * s
	var rect := collision_shape.shape as RectangleShape2D
	rect.size = Vector2(float(wpx) * s, float(hpx) * s)


## 直接用專案裡的圖：先走匯入；失敗則 Image.load；再失敗則依檔案魔術數用 JPEG/PNG/WebP 解緩衝區（副檔名可維持 .png）。
func load_texture(path: String) -> Texture2D:
	var tex: Texture2D = ResourceLoader.load(path, "Texture2D", ResourceLoader.CACHE_MODE_REUSE) as Texture2D
	if tex != null:
		return tex
	var img := Image.new()
	if img.load(path) == OK:
		return ImageTexture.create_from_image(img)
	var fa := FileAccess.open(path, FileAccess.READ)
	if fa == null:
		push_warning("SpriteTextureUtil: cannot open %s" % path)
		return null
	var buf: PackedByteArray = fa.get_buffer(fa.get_length())
	fa.close()
	if buf.size() < 12:
		push_warning("SpriteTextureUtil: file too small %s" % path)
		return null
	# JPEG
	if buf[0] == 0xFF and buf[1] == 0xD8:
		if img.load_jpg_from_buffer(buf) == OK:
			return ImageTexture.create_from_image(img)
	# PNG
	if buf[0] == 0x89 and buf[1] == 0x50 and buf[2] == 0x4E and buf[3] == 0x47:
		if img.load_png_from_buffer(buf) == OK:
			return ImageTexture.create_from_image(img)
	# WebP (RIFF + WEBP)
	if (
		buf[0] == 0x52
		and buf[1] == 0x49
		and buf[2] == 0x46
		and buf[3] == 0x46
		and buf[8] == 0x57
		and buf[9] == 0x45
		and buf[10] == 0x42
		and buf[11] == 0x50
	):
		if img.load_webp_from_buffer(buf) == OK:
			return ImageTexture.create_from_image(img)
	push_warning("SpriteTextureUtil: cannot decode %s" % path)
	return null
