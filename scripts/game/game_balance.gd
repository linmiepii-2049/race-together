extends Resource

@export_group("Scroll")
@export var base_scroll_speed: float = 220.0
@export var scroll_speed_max: float = 520.0
@export var scroll_ramp_per_score: float = 0.35

@export_group("Player lateral")
@export var lateral_accel: float = 2940.0
@export var lateral_friction: float = 19.5
@export var max_lateral_speed: float = 1140.0
@export var high_speed_steer_factor: float = 0.42

@export_group("Handbrake drift")
@export var handbrake_lateral_impulse: float = 360.0
@export var handbrake_duration_sec: float = 0.45
@export var handbrake_friction_mult: float = 0.35

@export_group("Shields & invuln")
@export var shield_max: int = 3
## 護盾拾取可堆疊上限（高於 shield_max 仍可吃到加成）
@export var shield_pickup_cap: int = 6
@export var invulnerable_after_hit_sec: float = 1.1
@export var invulnerable_pickup_sec: float = 7.0

@export_group("Spawning")
@export var spawn_interval_start: float = 1.35
@export var spawn_interval_min: float = 0.38
@export var spawn_interval_per_score: float = 0.008
@export var weight_static: float = 1.0
@export var weight_drone: float = 0.85
@export var weight_laser: float = 0.65
@export var spawn_margin_x: float = 80.0
@export var spawn_y: float = -80.0
@export var despawn_y: float = 780.0

@export_group("Drone")
@export var drone_lateral_speed: float = 220.0
@export var drone_amplitude: float = 220.0

@export_group("Laser gate")
@export var laser_on_sec: float = 0.55
@export var laser_off_sec: float = 0.75

@export_group("Playfield")
@export var player_anchor_y: float = 560.0
@export var half_lane_width: float = 420.0
