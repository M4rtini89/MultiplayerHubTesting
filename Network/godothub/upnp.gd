extends Node
class_name Port_open

# Member variables
var upnp : UPNP = UPNP.new()
var listen_port
var external_address = null

signal port_opened()

func do_port_forward(_listen_port):
    
    upnp.discover() 
    var res = upnp.add_port_mapping(int(_listen_port))
    if res != UPNP.UPNP_RESULT_SUCCESS:
        print("could not open ports on gateway")
    else:
        print("port %s opened on gateway" % _listen_port)
        listen_port = _listen_port
        emit_signal("port_opened")

func get_external_address():
    if external_address == null:
        upnp.discover()
        external_address = upnp.query_external_address()
    return external_address


func get_internal_address():
    upnp.discover()
    var gateway : UPNPDevice = upnp.get_gateway()
    return gateway.igd_our_addr


func _exit_tree():
    upnp.delete_port_mapping(listen_port)