extends Particles2D

# 不同爆炸音效的音频流
export(AudioStream) var playerAudio = null
export(AudioStream) var rockAudio = null
export(AudioStream) var alienAudio = null

onready var _lifeTimer = $LifeTimer
onready var _audioPlayer = $AudioStreamPlayer

# 爆炸对象的类型：岩石、敌人、玩家
var type = 'rock' setget _setType

func _ready():
	match type:
		'rock':
			self.amount = 40
			_audioPlayer.stream = rockAudio
		'player':
			# 延长玩家爆炸特效的时长
			_lifeTimer.wait_time = 2.0
			_audioPlayer.stream = playerAudio
		'alien':
			self.amount = 50
			_audioPlayer.stream = alienAudio
			_audioPlayer.pitch_scale = 2.0
	_audioPlayer.play()

func _setType(value):
	type = value

func _on_LifeTimer_timeout():
	self.queue_free()
