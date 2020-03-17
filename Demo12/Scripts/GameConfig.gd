extends Node

######### Signales #########
signal text_enter(isEntering)
signal new_message(content)


######### Messages #########
enum MessageType {System, Information, Chat}

######### TILE MAP #########
const TILE_SIZE = 64
const TILE_SIZE_VECTOR = Vector2(64, 64)
const TILE_HALF_SIZE_VECTOR = Vector2(32, 32)

const WALL_TILE_ID := 0
const BRICK_TILE_ID := 1
const GRASS_TILE_ID := 2

enum ItemType {ActorEffect, BombEffect, OtherEffect}

######### BOMB SET #########
const EXPLOSION_START := 0
const EXPLOSION_CENTER := 1
const EXPLOSION_END := 2


######### ITEM SET #########
class ItemData:
	var name : String
	var icon : String
	var data : String
	var type : int

	func _init(name : String, icon : String, data : String, type : int = ItemType.ActorEffect):
		self.name = name
		self.icon = icon
		self.data = data
		self.type = type

var items = [
	ItemData.new('Empty', 'res://Items/Assets/Items_empty.png', '', ItemType.OtherEffect),
	ItemData.new('Become Invulnerable', 'res://Items/Assets/Items_becomeinvulnerable.png', 'res://Items/Pickups/BecomeInvulnerable.tscn', ItemType.ActorEffect),
	ItemData.new('Health Cure', 'res://Items/Assets/Items_healthcure.png', 'res://Items/Pickups/HealthCure.tscn', ItemType.ActorEffect),
	ItemData.new('Speed Up', 'res://Items/Assets/Items_speedup.png', 'res://Items/Pickups/SpeedUp.tscn', ItemType.ActorEffect),
	ItemData.new('Power Adder', 'res://Items/Assets/Items_poweradder.png', 'res://Items/Pickups/PowerAdder.tscn', ItemType.ActorEffect),
	ItemData.new('Bomb Timing Trigger', 'res://Items/Assets/Items_timingtriggerbomb.png', 'res://Items/Pickups/TimingTriggerBomb.tscn', ItemType.BombEffect),
	ItemData.new('Bomb Delayed', 'res://Items/Assets/Items_delayedtimebomb.png', 'res://Items/Pickups/DelayedTimeBomb.tscn', ItemType.BombEffect),
	ItemData.new('Bomb Power Enhanced', 'res://Items/Assets/Items_powerenhancedbomb.png', 'res://Items/Pickups/PowerEnhancedBomb.tscn', ItemType.BombEffect),
]

const Item : PackedScene = preload('res://Items/Item.tscn')


######### FUNCTIONS #########
func _ready() -> void:
	randomize()
	print('randi in ', self.get_script().resource_path)


func produceItem() -> ItemData:
	var index := 0
	var probability := randf()
	# 40% produce bomb items, 55% produce actor items, 5% produce empty
	if probability > 0.6:
		index = randi() % 3 + 5
	elif probability < 0.55:
		index = randi() % 4 + 1
	return items[index]


func backToMainScene() -> void:
	var scene = load('res://GUI/LobbyUI.tscn')
	self.get_tree().change_scene_to(scene)


func sendMessage(type : int, playerID : int, content : String) -> void:
	content = content.strip_edges()
	if content.empty():
		return
	
	var bbcode : String = '[color=red]Error, please check![/color]'
	match type:
		MessageType.System:
			var color := 'yellow'
			var playerName := 'You' if playerID == GameState.myId else 'PlayerID???'
			bbcode = '[color=%s]%s %s[/color]' % [color, playerName, content] if playerID > 0 else '[color=%s]%s[/color]' % [color, content]
		MessageType.Information:
			var playerName := 'You' if playerID == GameState.myId else 'PlayerID???'
			var playerColor := Color.white
			var color := 'lime' if playerID == GameState.myId else 'fuchsia'
			bbcode = '[img]res://GUI/Assets/MessageIcons.png[/img] [color=#%s]%s[/color] [color=%s]%s[/color]' % [playerColor, playerName, color, content]
		MessageType.Chat:
			assert(playerID > 0)
			var playerName := 'You' if playerID == GameState.myId else 'PlayerID???'
			var playerColor := Color.white
			bbcode = '[color=#%s]%s[/color]: %s' % [playerColor, playerName, content]
		_:
			pass

	self.emit_signal('new_message', bbcode)

