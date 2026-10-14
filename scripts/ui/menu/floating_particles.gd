extends Control
## Sistema de partículas melhorado com três tipos:
## Brasas (quentes, sobem), Faíscas (frias, derivam) e Poeira (muito sutil).

var _time := 0.0
var _embers: Array[Dictionary] = []
var _sparkles: Array[Dictionary] = []
var _dust: Array[Dictionary] = []

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	for i in 28:
		var sv := float(i) * 137.71
		_embers.append({
			"x": fposmod(sv * 2.71, 1.0),
			"y": fposmod(sv * 1.83, 1.0),
			"speed": 4.0 + float(i % 6) * 2.5,
			"phase": sv,
			"size": 1.0 + float(i % 3) * 0.5,
			"drift": 6.0 + float(i % 4) * 3.0
		})
	for i in 18:
		var sv := float(i) * 211.37
		_sparkles.append({
			"x": fposmod(sv * 1.93, 1.0),
			"y": fposmod(sv * 2.41, 1.0),
			"speed": 2.0 + float(i % 5) * 1.5,
			"phase": sv,
			"size": 0.6 + float(i % 3) * 0.3
		})
	for i in 12:
		var sv := float(i) * 89.53
		_dust.append({
			"x": fposmod(sv * 3.07, 1.0),
			"y": fposmod(sv * 1.19, 1.0),
			"speed": 1.0 + float(i % 4) * 0.8,
			"phase": sv,
			"size": 1.5 + float(i % 3) * 0.7
		})

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	_draw_embers()
	_draw_sparkles()
	_draw_dust()

# ── Brasas (quentes, formato diamante, sobem) ─────────────────
func _draw_embers() -> void:
	for e in _embers:
		var x := float(e.x) * size.x + sin(_time * 0.6 + float(e.phase)) * float(e.drift)
		var y := fposmod(float(e.y) - _time * float(e.speed) / maxf(300.0, size.y), 1.0) * size.y
		var pulse := 0.22 + 0.22 * (0.5 + 0.5 * sin(_time * 1.5 + float(e.phase)))
		var r := float(e.size)
		draw_circle(Vector2(x, y), r * 4.0, Color(0.92, 0.58, 0.25, pulse * 0.10))
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, y - r * 2.2), Vector2(x + r * 0.7, y),
			Vector2(x, y + r * 2.2), Vector2(x - r * 0.7, y)
		]), Color(0.98, 0.75, 0.40, pulse))

# ── Faíscas (frias, círculos, derivam) ─────────────────────────
func _draw_sparkles() -> void:
	for s in _sparkles:
		var x := fposmod(float(s.x) + _time * float(s.speed) * 0.003 + sin(_time * 0.4 + float(s.phase)) * 0.02, 1.0) * size.x
		var y := fposmod(float(s.y) - _time * float(s.speed) / maxf(500.0, size.y), 1.0) * size.y
		var pulse := 0.3 + 0.3 * sin(_time * 2.0 + float(s.phase))
		var r := float(s.size)
		draw_circle(Vector2(x, y), r * 2.0, Color(0.6, 0.8, 0.95, pulse * 0.12))
		draw_circle(Vector2(x, y), r, Color(0.75, 0.88, 1.0, pulse * 0.6))

# ── Poeira (muito sutil, flutuação lenta) ──────────────────────
func _draw_dust() -> void:
	for d in _dust:
		var x := fposmod(float(d.x) + sin(_time * 0.2 + float(d.phase)) * 0.03, 1.0) * size.x
		var y := fposmod(float(d.y) + cos(_time * 0.15 + float(d.phase)) * 0.02, 1.0) * size.y
		var pulse := 0.1 + 0.08 * sin(_time * 0.8 + float(d.phase))
		draw_circle(Vector2(x, y), float(d.size), Color(0.85, 0.82, 0.75, pulse))
