extends Node

var _client = WebSocketClient.new()
var _write_mode = WebSocketPeer.WRITE_MODE_TEXT
var port_open = Port_open.new()

export var reconnect = true

signal got_game_list()
var game_list

onready var hub_games_list = $ItemList

func _init():
    _client.connect("connection_established", self, "_client_connected")
    _client.connect("connection_error", self, "_client_disconnected")
    _client.connect("connection_closed", self, "_client_disconnected")
    _client.connect("server_close_request", self, "_client_close_request")
    _client.connect("data_received", self, "_client_received")

    _client.connect("peer_packet", self, "_client_received")
    _client.connect("peer_connected", self, "_peer_connected")
    _client.connect("connection_succeeded", self, "_client_connected", ["multiplayer_protocol"])
    _client.connect("connection_failed", self, "_client_disconnected")

func _ready():
    _client.connect_to_url("ws://godothub.herokuapp.com/")
#	_client.connect_to_url("ws://127.0.0.1:5000")

func _process(delta):
    _client.poll()


func send_message(msg):
    _client.get_peer(1).set_write_mode(_write_mode)
    var data = to_json({'event': 'message', 'data': {'message': msg}})
#	_client.get_peer(1).put_var(data)
    _client.get_peer(1).put_packet(encode_data(data, _write_mode))


func crate_game_host(gameName, port):
    gameName = "MyMultiplayer (host: %s)" %gameName
    port_open.do_port_forward(port)
    _client.get_peer(1).set_write_mode(_write_mode)
    var data = to_json({'event': 'createGameLobby', 'data': {'port': port, 'local_ip': port_open.get_internal_address(), 'name': gameName}})
    _client.get_peer(1).put_packet(encode_data(data, _write_mode))


func get_game_host_list():
    _client.get_peer(1).set_write_mode(_write_mode)
    var data = to_json({'event': 'getGameLobbyList'})
    _client.get_peer(1).put_packet(encode_data(data, _write_mode))

func _client_connected(data):
    print("connected: %s" % data)
    get_game_host_list()


func _client_received():
    var packet = _client.get_peer(1).get_packet()
    var is_string = _client.get_peer(1).was_string_packet()
    var data = (decode_data(packet, is_string))
    var json = parse_json(data)
    match json.event:
        "message":
            print("We got a message")
            print("Received message: %s" % [json.data.message])
        "getGameLobbyList":
            print("we got a list of games")
            game_list = json.data
            process_game_list(game_list)
#            emit_signal("got_game_list", game_list)

                

func process_game_list(game_list):
    hub_games_list.clear()
    for game in game_list:
        if game.ip == port_open.get_external_address():
            print("got a local game")
            game.ip = game.local_ip
        game.erase("local_ip")
        hub_games_list.add_item(game.name)

func _client_disconnected(clean):
    print("Client just disconnected. Was clean: %s" % clean)
    if reconnect:
        _client.connect_to_url("ws://godothub.herokuapp.com/")


func encode_data(data, mode):
    return data.to_utf8() if mode == WebSocketPeer.WRITE_MODE_TEXT else var2bytes(data)

func decode_data(data, is_string):
    return data.get_string_from_utf8() if is_string else bytes2var(data)

func _on_refreshButton_pressed():
    get_game_host_list()
