extends RefCounted
const PLAYER := preload("res://scripts/world/player.gd")
const CODEC := preload("res://scripts/network/snapshot_codec.gd")
const REPLICA := preload("res://scripts/network/world_replica.gd")
class Fixture extends Node:
	var collective_paused := false
	var started := false
	var run_finished := false

func run(tree: SceneTree) -> void:
	var session: Node = tree.root.get_node("NetworkSession")
	var old_game: Node = session.game
	var fixture := Fixture.new()
	var arena := Node2D.new()
	tree.root.add_child(arena)
	arena.add_child(fixture)
	var server := PLAYER.new()
	var client := PLAYER.new()
	for actor in [server, client]:
		actor.configure("warrior", {})
		arena.add_child(actor)
		actor.set_physics_process(false)
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 12
		shape.shape = circle
		actor.add_child(shape)
	server.net_peer_id = 2
	var wall := StaticBody2D.new()
	wall.position = Vector2(55, 0)
	wall.collision_layer = 4
	var wall_shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(12, 100)
	wall_shape.shape = box
	wall.add_child(wall_shape)
	arena.add_child(wall)
	for frame in 3:
		await tree.physics_frame
	session.hosting = true
	session.running = true
	session.run_id = "motion-test"
	session.game = fixture
	session.players = {2: {}}
	session.input_buffers.clear()
	session.acknowledged_inputs.clear()
	session.received_input_sequences.clear()
	var commands: Array = []
	for sequence in range(1, 121):
		var direction := Vector2.RIGHT if sequence <= 30 else (Vector2(1, -1).normalized() if sequence <= 60 else Vector2.LEFT)
		client.simulate_network_step(direction, session.INPUT_STEP)
		commands.append([sequence, direction, sequence])
		# Intentionally lose every third input transmission; redundancy carries it later.
		if sequence % 3 != 0:
			session._receive_inputs(2, "motion-test", commands.slice(maxi(0, commands.size() - 8)), session.choice_epoch)
			session.simulate_remote_player(server)
	# Last redundant packet catches the remaining command; duplicates must not move twice.
	session._receive_inputs(2, "motion-test", commands.slice(-8), session.choice_epoch)
	session.simulate_remote_player(server)
	assert(server.position.distance_to(client.position) < 0.05, "Authoritative and predicted trajectories match, including wall sliding and lost transmissions")
	assert(int(session.acknowledged_inputs[2]) == 120)
	var before: Vector2 = server.position
	session._receive_inputs(2, "motion-test", commands.slice(-8), session.choice_epoch)
	session.simulate_remote_player(server)
	assert(server.position.is_equal_approx(before), "Already acknowledged commands cannot move again")
	fixture.collective_paused = true
	session._receive_inputs(2, "motion-test", [[121, Vector2.RIGHT, 121]], session.choice_epoch)
	session.simulate_remote_player(server)
	assert(server.position.is_equal_approx(before) and int(session.acknowledged_inputs[2]) == 121, "Paused input is acknowledged without moving")
	fixture.collective_paused = false
	server.is_dead = true
	session._receive_inputs(2, "motion-test", [[122, Vector2.RIGHT, 122]], session.choice_epoch)
	session.simulate_remote_player(server)
	assert(server.position.is_equal_approx(before) and int(session.acknowledged_inputs[2]) == 122, "Downed players do not accumulate movement for revival")
	var packet := {"rows": [REPLICA._row(client, "P", "P2")], "time": 12.5}
	var encoded := CODEC.encode(packet, REPLICA.FIELDS)
	var decoded := CODEC.decode(encoded, REPLICA.FIELDS)
	assert(decoded == packet, "Compact wire format preserves every field and type")
	var replica := REPLICA.new()
	replica.world = fixture
	replica.remove_entities(["old"], 5)
	replica.apply_slice({"rows": [{"id": "old", "type": "E"}]}, 4)
	assert(replica.visuals.is_empty(), "Late world packets cannot resurrect removed enemies")
	replica.free()
	session.running = false
	session.hosting = false
	session.game = old_game
	session.players.clear()
	session.input_buffers.clear()
	session.acknowledged_inputs.clear()
	session.acknowledged_stamps.clear()
	session.received_input_sequences.clear()
	arena.queue_free()
	await tree.process_frame
	print("PASS: deterministic client/server movement, wall sliding, redundant lost-input recovery, processed acknowledgements, pause/death barriers and compact snapshot fidelity")
