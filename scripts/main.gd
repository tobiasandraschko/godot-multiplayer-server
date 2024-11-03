extends Node

var peer = ENetMultiplayerPeer.new()
var players = {}

func _ready():
	print("Server starting...")
	var error = peer.create_server(9999, 32)
	if error != OK:
		print("Failed to start server: ", error)
		return
		
	multiplayer.multiplayer_peer = peer
	print("Server started on port 9999")
	
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _on_peer_connected(id: int) -> void:
	print("Client ", id, " connected")
	
	# Spawn the new player and inform all clients
	var spawn_pos = Vector3(randf_range(-5, 5), 2, randf_range(-5, 5))
	players[id] = spawn_pos
	
	# Spawn existing players for the new client
	for player_id in players:
		if player_id != id:  # Don't spawn the new player twice
			spawn_player.rpc_id(id, player_id, players[player_id])
	
	# Spawn the new player for everyone (including the new client)
	spawn_player.rpc(id, spawn_pos)

func _on_peer_disconnected(id: int) -> void:
	print("Client ", id, " disconnected")
	if players.has(id):
		players.erase(id)
		despawn_player.rpc(id)

@rpc("authority", "call_local", "reliable")
func spawn_player(id: int, pos: Vector3):
	print("Spawning player: ", id)
	if $World/Players.has_node(str(id)):
		print("Player ", id, " already exists")
		return
		
	var player_scene = preload("res://scenes/player.tscn").instantiate()
	player_scene.name = str(id)
	player_scene.position = pos
	player_scene.set_multiplayer_authority(id)
	$World/Players.add_child(player_scene)
	print("Successfully spawned player ", id, " at position ", pos)

@rpc("authority", "call_local", "reliable")
func despawn_player(id: int):
	if $World/Players.has_node(str(id)):
		$World/Players.get_node(str(id)).queue_free()
		print("Despawned player ", id)
