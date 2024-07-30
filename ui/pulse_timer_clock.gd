@tool
extends Control
class_name PulseTimerClock

@export var timer := 0.0
@export var pulses: Array[float] = []
@export var max_time := 20.0


@export var delay := 3.0:
	set(value):
		delay = value
		queue_redraw()


@export var duration := 5.0:
	set(value):
		duration = value
		queue_redraw()


func _draw() -> void:
	var center := size / 2.0
	var start_angle := delay / max_time * TAU
	var end_angle := (delay + duration) / max_time * TAU
	var point_count := 100
	var filled := false
	var line_width := 10.0
	var radius := minf(size.x, size.y) / 2.0 - line_width / 2.0
	var top := center + Vector2(0.0, -radius)
	var antialiased := true
	_draw_arc_filled(
		center, radius, start_angle, end_angle, point_count, Color("738cf6")
	)
	draw_circle(center, radius, Color("ffffff"), filled, line_width, antialiased)
	draw_line(center, top, Color("ffffff"), line_width, antialiased)
	for pulse in pulses:
		var t := (delay - (pulse - timer)) / max_time
		var pulse_center := center + 0.6 * radius * Vector2.from_angle(t * TAU - 0.25 * TAU)
		var pulse_width := -1.0
		var pulse_radius := line_width
		var pulse_filled := true
		draw_circle(
			pulse_center,
			pulse_radius,
			Color("ffffff"),
			pulse_filled,
			pulse_width,
			antialiased,
		)


func _draw_arc_filled(
	center: Vector2,
	radius: float, 
	start_angle: float, 
	end_angle: float, 
	point_count: int,
	color: Color,
):
	var points_arc := PackedVector2Array()
	points_arc.push_back(center)
	var colors = PackedColorArray([color])
	for i in range(point_count + 1):
		var angle_point := (
			end_angle + i * (start_angle - end_angle) / point_count - TAU / 4.0
		)
		points_arc.push_back(
			center + Vector2(cos(angle_point), sin(angle_point)) * radius
		)
	draw_polygon(points_arc, colors)
