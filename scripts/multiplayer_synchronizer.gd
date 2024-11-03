extends MultiplayerSynchronizer

func _ready():
	set_multiplayer_authority(str(get_parent().name).to_int())
	
	if not replication_config:
		replication_config = SceneReplicationConfig.new()
		
		replication_config.add_property(".:position")
		replication_config.add_property(".:rotation")
		replication_config.add_property("CameraMount:rotation")  # Single colon for node properties
