extends Node
## 音频导演（Autoload）：程序化音效 + 动态环境音。
## 所有声音由代码合成，不依赖外部素材，零版权风险。
##
## 三层：
## 1. UI / 击球 —— 短促合成音，按战术改变音色
## 2. 观众底噪 —— 2 秒循环噪声，随比赛强度调制
## 3. 关键分真空 —— 底噪压到近乎消失，只留心跳

var enabled: bool = true

var _ui: AudioStreamPlayer
var _hit: AudioStreamPlayer
var _amb: AudioStreamPlayer
var _heart: AudioStreamPlayer

var _amb_stream: AudioStreamWAV
var _amb_target: float = 0.0
var _amb_current: float = 0.0

func _ready() -> void:
	_ui = _player(-8.0)
	_hit = _player(-4.0)
	_amb = _player(-26.0)
	_heart = _player(-10.0)
	_amb_stream = _build_ambience()
	_amb.stream = _amb_stream
	_amb.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_amb.stream.loop_end = int(_amb_stream.get_length() * 22050.0)
	set_process(true)

func _player(db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.volume_db = db
	p.bus = "Master"
	add_child(p)
	return p

func _process(delta: float) -> void:
	if _amb_current != _amb_target:
		_amb_current = move_toward(_amb_current, _amb_target, delta * 1.6)
		_amb.volume_db = linear_to_db(maxf(0.001, _amb_current)) - 6.0
		if _amb_current <= 0.002 and _amb.playing:
			_amb.stop()
		elif _amb_current > 0.002 and not _amb.playing:
			_amb.play()

func play_sfx(id: String) -> void:
	if not enabled:
		return
	match id:
		"hit":
			_blip(760.0, 0.045, 0.32, "square")
		"hit_drive":
			_blip(920.0, 0.05, 0.38, "square")
		"hit_chop":
			_blip(280.0, 0.09, 0.28, "sine")
		"point":
			_blip(620.0, 0.09, 0.26, "sine")
		"ui":
			_blip(1180.0, 0.03, 0.16, "sine")
		"timeout":
			_blip(210.0, 0.34, 0.30, "sine")
		"win":
			_blip(523.0, 0.5, 0.30, "sine")
		"lose":
			_blip(196.0, 0.6, 0.26, "sine")
		"heart":
			_heartbeat()
		_:
			_blip(800.0, 0.04, 0.18, "sine")

## 环境音强度：0（真空）~ 1（满场）
func set_ambience(v: float) -> void:
	_amb_target = clampf(v, 0.0, 1.0)
	if _amb_target > 0.01 and not _amb.playing:
		_amb.play()

func ambience_off() -> void:
	_amb_target = 0.0

## 短音：正弦/方波 + 指数衰减包络
func _blip(freq: float, dur: float, amp: float, wave: String = "sine") -> void:
	var rate := 22050
	var frames := int(dur * float(rate))
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in range(frames):
		var t := float(i) / float(rate)
		var env: float = exp(-t / (dur * 0.30))
		var s := 0.0
		if wave == "square":
			s = 1.0 if sin(TAU * freq * t) >= 0.0 else -1.0
			s *= 0.55
		else:
			s = sin(TAU * freq * t)
		s *= env * amp
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32767.0))
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = rate
	st.stereo = false
	st.data = data
	_ui.stream = st
	_ui.play()

## 心跳：两下低频脉冲
func _heartbeat() -> void:
	var rate := 22050
	var dur := 0.55
	var frames := int(dur * float(rate))
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in range(frames):
		var t := float(i) / float(rate)
		var s := 0.0
		# 第一下
		if t < 0.16:
			s += sin(TAU * 58.0 * t) * exp(-t / 0.05) * 0.7
		# 第二下
		if t > 0.22 and t < 0.42:
			var t2 := t - 0.22
			s += sin(TAU * 52.0 * t2) * exp(-t2 / 0.06) * 0.55
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32767.0))
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = rate
	st.stereo = false
	st.data = data
	_heart.stream = st
	_heart.play()

## 观众底噪：带通白噪声 + 缓慢起伏，2 秒可循环
func _build_ambience() -> AudioStreamWAV:
	var rate := 22050
	var dur := 2.0
	var frames := int(dur * float(rate))
	var data := PackedByteArray()
	data.resize(frames * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261112
	var low := 0.0
	var mid := 0.0
	for i in range(frames):
		var t := float(i) / float(rate)
		var n := rng.randf_range(-1.0, 1.0)
		# 两级低通，模拟人声嘈杂的中低频
		low = lerpf(low, n, 0.045)
		mid = lerpf(mid, n, 0.16)
		var swell := 0.72 + 0.28 * sin(TAU * 0.37 * t) * sin(TAU * 0.13 * t + 1.2)
		var s := (low * 0.75 + mid * 0.25) * swell * 0.30
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32767.0))
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = rate
	st.stereo = false
	st.data = data
	return st
