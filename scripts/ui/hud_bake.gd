class_name HudBake
extends Control
## "Assa" um desenho feito por código numa textura, uma vez só: um viewport transparente
## desenha o Callable e a imagem é guardada. Desenhar a textura depois custa 1 chamada,
## em vez de dezenas de círculos, arcos e textos com contorno a cada quadro.

var paint: Callable


func _draw() -> void:
	paint.call(self)


static func bake(host: Node, size_px: Vector2i, fn: Callable) -> ImageTexture:
	var painter := HudBake.new()
	painter.paint = fn
	return await bake_node(host, size_px, painter)


## Assa qualquer Control que se desenha sozinho (ex.: a camada fixa do HUD).
static func bake_node(host: Node, size_px: Vector2i, painter: Control) -> ImageTexture:
	var vp := SubViewport.new()
	vp.size = size_px
	vp.transparent_bg = true
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	painter.size = Vector2(size_px)
	vp.add_child(painter)
	host.add_child(vp)
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	vp.queue_free()
	return ImageTexture.create_from_image(img)
