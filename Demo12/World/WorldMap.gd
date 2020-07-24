extends TileMap


export var maxRequestCount := 5 # max number of times to find path for brickerlayer

onready var _respawnTimer := $RespawnTimer as Timer
onready var _bricklayer : Node2D = $Bricklayer

var _navigation : Navigation2D = null
var _brokenTiles := []          # Should update in Server and Clients
var _requestTimes := 0
var _repaireTargetTile := Vector2(-1, -1)


func _ready() -> void:
	# Here the data should be synchronized in all peers!!!
	# Or you can just use in the Server, not the Master peer!
	_navigation = self.get_parent()
	for tile in self.get_used_cells():
		if self.get_cellv(tile) == GameConfig.GRASS_TILE_ID:
			_brokenTiles.append(tile)


func _on_Bricklayer_dead() -> void:
	_respawnTimer.start()


func _on_RespawnTimer_timeout() -> void:
	assert(self.is_network_master(), 'Bricklayer must respawn at Master Node!')
	
	_requestTimes = 0
	var tilePos := Vector2(-1, -1)
	for tile in _brokenTiles:
		var count := _getEmptyNeighbors(tile)
		if count >= 3:
			tilePos = tile
			break
	
	if tilePos == Vector2(-1, -1):
		_respawnTimer.start()
	else:
		_bricklayer.position = self.to_local(self.map_to_world(tilePos)) + self.cell_size / 2
		_bricklayer.respawn()


func _on_Bricklayer_brick_repaire_done() -> void:
	assert(_repaireTargetTile in _brokenTiles, 'Some wrong with repaired tiles!')
	
	self.rpc('_updateBrokenTilesData', _repaireTargetTile, false)
	self.rpc('_tileMapChangeTileAt', _repaireTargetTile, self.tile_set.find_tile_by_name('Brick'))
	_repaireTargetTile = Vector2(-1, -1)


remotesync func _updateBrokenTilesData(tile : Vector2, isAppend : bool = true) -> void:
	if isAppend:
		_brokenTiles.append(tile)
	else:
		_brokenTiles.erase(tile)


remotesync func _tileMapChangeTileAt(mapPos : Vector2, tileId : int) -> void:
	self.set_cellv(mapPos, tileId)


func _on_Bricklayer_request_new_path() -> void:
	if _navigation == null || _brokenTiles.empty():
		return
	
	var index := randi() % _brokenTiles.size()
	while _brokenTiles[index] == _repaireTargetTile:
		index = randi() % _brokenTiles.size()
	_repaireTargetTile = _brokenTiles[index]
	
	var from := _bricklayer.position
	var to := self.to_local(self.map_to_world(_repaireTargetTile)) + self.cell_size / 2
	var path := _navigation.get_simple_path(from, to, false)
	
	if path.empty():
		_on_Bricklayer_request_new_path()
		_requestTimes += 1
		if _requestTimes >= maxRequestCount:
			_bricklayer.rpc('bomb')
		return
	
	var pathArray := Array(path)
	pathArray.append(to)
	var count := _getEmptyNeighbors(_repaireTargetTile)
	match count:
		3, 4:
			_bricklayer.canSuccess = true
		1, 2:
			_bricklayer.canSuccess = randf() > 1.0 / count
		0:
			_bricklayer.canSuccess = false
	_bricklayer.path = pathArray
	
	_requestTimes = 0
	
#	$'Painter-Debug'.path = pathArray


func _getEmptyNeighbors(tile : Vector2) -> int:
	var neighbors := 0
	for dir in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
		var neighbor = tile + dir
		var id := self.get_cellv(neighbor)
		var name := self.tile_set.tile_get_name(id)
		if name == 'Grass':
			neighbors += 1
	return neighbors


func addBrokenTile(mapPos : Vector2) -> void:
	if ! mapPos in _brokenTiles:
		self.rpc('_updateBrokenTilesData', mapPos, true)


func removeBrokenTile(mapPos : Vector2) -> bool:
	if mapPos in _brokenTiles:
		self.rpc('_updateBrokenTilesData', mapPos, false)
		return true
	return false


func getRandomTile() -> Vector2:
	var brokenTilesCopy := _brokenTiles.slice(0, _brokenTiles.size() - 1)
	brokenTilesCopy.shuffle()
	
	var state := self.get_world_2d().direct_space_state
	var query := Physics2DShapeQueryParameters.new()
	var shape := RectangleShape2D.new()
	var maxResults := 9
	shape.extents = self.cell_size
	query.set_shape(shape)
	for tile in brokenTilesCopy:
		var pos := self.map_to_world(tile) + self.cell_size / 2
		query.transform = Transform2D(0.0, pos)
		var result := state.intersect_shape(query, maxResults)
		var isValid := true
		for collision in result:
			if collision.collider is KinematicBody2D:
				isValid = false
				break
		if isValid:
			return tile
	
	return Vector2(-1, -1)

