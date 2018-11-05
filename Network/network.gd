extends Node
class_name NetworkClass


#var player_info = {}
var my_info = {'name': "my_name"}
signal player_connected(id)
signal player_disconnected(id)
signal server_disconnected()
signal register_player(id, player_info)


func _ready():
    Global.Network = self
    multiplayer.connect("connection_failed", self, "_connection_failed")
    multiplayer.connect("connected_to_server", self, "_connected")
    multiplayer.connect("network_peer_disconnected", self, "_player_disconnected")
    multiplayer.connect("network_peer_connected", self, "_player_connected")
    multiplayer.connect("server_disconnected", self, "_server_disconnected")

func _exit_tree():
    Global.Network = null
    multiplayer.disconnect("connection_failed", self, "_connection_failed")
    multiplayer.disconnect("connected_to_server", self, "_connected")
    multiplayer.disconnect("network_peer_disconnected", self, "_player_disconnected")
    multiplayer.disconnect("network_peer_connected", self, "_player_connected")
    multiplayer.disconnect("server_disconnected", self, "_server_disconnected")

func _connection_failed():
    Global._log("Could not connect to server")
    multiplayer.set_network_peer(null)


func _server_disconnected():
    Global._log("Server closed connection")
    multiplayer.set_network_peer(null)
    emit_signal("server_disconnected")


func _connected():
    Global._log("connected to server")
    var selfPeerID = multiplayer.get_network_unique_id()
    rpc("_rpc_player_connected", selfPeerID)
    rpc("_rpc_register_player", selfPeerID, my_info)
#    _rpc_register_player(selfPeerID, my_info)

func _close_network():
    multiplayer.set_network_peer(null)


func _player_disconnected(id):
    Global._log("Peer disconnected from server: %s" %id)
    rpc("_rpc_player_disconnected", id)


func _player_connected(id):
    Global._log("Peer connected to server: %s" %id)


func start_server(port):
    print("starting server at port: %s" % port)
    var peer = null
    var error = null
    if Global.USE_ENET:
        peer = NetworkedMultiplayerENet.new()
        error = peer.create_server(port)
    else:
        peer = WebSocketServer.new()
        error = peer.listen(port, PoolStringArray(), true)
    multiplayer.set_network_peer(peer)
    
    if error != OK:
        print("Problem starting server: %s" % error)

func start_client(host, port, start_local=false):
    print("starting client and connecting to: %s:%s" % [host, port])
    var peer = null
    if Global.USE_ENET:
        peer = NetworkedMultiplayerENet.new()
        peer.create_client(host, port)
    else:
        peer = WebSocketClient.new()
        peer.connect_to_url("ws://%s:%s/" % [host, port], PoolStringArray(), true)
    multiplayer.set_network_peer(peer)


func _on_LobbyUI_join_server(ip, port):
    start_client(ip, Global.SERVER_PORT) 


func _on_LobbyUI_host_server(port):
    start_server(Global.SERVER_PORT)
    _rpc_player_connected(1)
    _rpc_register_player(1, my_info)


func _on_LobbyUI_local_player(_player_info):
    my_info.name = _player_info.name

sync func _rpc_player_connected(id):
    emit_signal("player_connected", id)

sync func _rpc_register_player(id, my_info):
    emit_signal("register_player", id, my_info)

sync func _rpc_player_disconnected(id):
    emit_signal("player_disconnected", id)

func _on_LobbyUI_leave_server():
    multiplayer.set_network_peer(null)


func _on_LobbyUI_start_game(all_players):
    var selfPeerID = get_tree().get_network_unique_id()
    var players_node = $Players
    var start_position = [Vector2(50,50), Vector2(400, 50), Vector2(50, 400), Vector2(400, 400)]
 
    # Load my player
    for player in all_players:
        print("loading player")
        var player_scene = preload("res://Player/Player.tscn").instance()
        player_scene.set_name(str(player.id))
        player_scene.position = start_position.pop_front()
        player_scene.set_network_master(player.id)
        players_node.add_child(player_scene)
    
    

