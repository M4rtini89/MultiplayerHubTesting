extends Control

onready var player_list : ItemList = $"HBoxContainer/GamePlayers/playerList"
onready var input_username = $"HBoxContainer/Buttons/HBoxContainer2/Input_username"

onready var join_button = $HBoxContainer/Buttons/joinButton
onready var host_button = $HBoxContainer/Buttons/hostButton
onready var disconnect_button = $HBoxContainer/Buttons/disconnectButton
onready var start_button = $HBoxContainer/Buttons/startGameButton

onready var hub_games = $HBoxContainer/HubGames

signal host_server(port)
signal join_server(ip, port)
signal leave_server()
signal local_player(player_info)
signal start_game(players)


class Connected_players:
    var players = []
    
    func add(id, name="..connecting.."):
        players.append({'id': id, 'name': name})
        players.sort_custom(self, "sortFunc")


    func remove(id):
        for i in range(players.size()):
            if players[i].id == id:
                players.remove(i)
                return OK
        return FAILED


    func update(id, name):
        for i in range(players.size()):
            if players[i].id == id:
                players[i].name = name
                players.sort_custom(self, "sortFunc")
                return OK
        return FAILED


    func get(i):
        return players[i]


    func size():
        return players.size()

    func getId(id):
        for i in range(players.size()):
            if players[i].id == id:
                return players[i]
        return -1
    
    
    func has(id):
        for i in range(players.size()):
            if players[i].id == id:
                return true
        return false


    func sortFunc(a,b):
        return a.name < b.name
 
var connected_players = Connected_players.new()      


func _on_hostButton_pressed():
    #send_local_player_info()
    emit_signal("host_server", Global.SERVER_PORT)
    hub_games.crate_game_host(input_username.text, Global.SERVER_PORT)
    host_button.disabled = true
    join_button.disabled = true
    disconnect_button.disabled = false
    start_button.disabled = false


func _on_joinButton_pressed():
    #send_local_player_info()
    emit_signal("join_server", "127.0.0.1", Global.SERVER_PORT)
    host_button.disabled = true
    join_button.disabled = true
    disconnect_button.disabled = false

func _on_disconnectButton_pressed():
    connected_players.players.clear()
    update_view()
    host_button.disabled = false
    join_button.disabled = false
    disconnect_button.disabled = true
    start_button.disabled = true
    emit_signal("leave_server")


func send_local_player_info(name):
    emit_signal("local_player", {'name': name})


func _on_player_connected(id):
    print("lobby: player connected %s" %id)
    if not multiplayer.is_network_server() or id == 1:
        return
#    connected_players[id] = {'name': '..connecting..'}
    print("Sending info to new player")
    for i in connected_players.size():
        var this_player = connected_players.get(i)
        rpc_id(id, "_update_player", this_player.id, this_player)


func _on_player_disconnected(id):
    print("lobby: player disconnected")
    rpc("_remove_player", id)


func _on_register_player(id, player_info):
    print("lobby: player register")
    rpc("_update_player", id, player_info)


sync func _update_player(id, player_info):
    var hasId = connected_players.has(id)
    if not hasId:
        connected_players.add(id, player_info.name)
    else:
        print(connected_players.players)
        connected_players.update(id, player_info.name)

    update_view()


func update_view():
    player_list.clear()
    for i in range(connected_players.size()):
        player_list.add_item(connected_players.get(i).name)

sync func _remove_player(id):
    var res = connected_players.remove(id)
    if res == OK:
        print("removed player from connected_players")
    update_view()
    


func _on_startGameButton_pressed():
    rpc("start_game")


sync func start_game():
    self.visible = false
    emit_signal("start_game", connected_players.players)



func _on_ItemList_item_activated(index):
    var game = hub_games.game_list[index]
    hub_games.port_open.do_port_forward(game.port)
    emit_signal("join_server", game.ip, game.port)
    print(game)
#    
    
