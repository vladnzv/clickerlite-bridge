#DEFAULT_PORT		= 80
#DEFAULT_IP			= "127.0.0.1"
#DEFAULT_ADDRESS	= "http://127.0.0.1"
#DEFAULT_TYPE		= #PB_Network_TCP

#SERVER_NAME 		= "GEPARD"
#SERVER_VERSION		= "1.0"
#SERVER_TITLE 		= #SERVER_NAME + " v" + #SERVER_VERSION + " lite"
#SERVER_PROG_TITLE	= "Server: " + #SERVER_TITLE
#MEMORY_SIZE		= 100000
#CHARSET			= "UTF-8"
#MASK_DATE			= "%yyyy-%mm-%dd, %hh:%ii:%ss"

	
#DIR_SESSION		= "data\session\"

Structure info
	id_server.l
	id_thread_events.l
	id_thread_main.l
	server_close.b
EndStructure

Structure request
	*buffer
	buffer_size.l
	client_id.l
EndStructure

Structure init
	port.u
	type.b
	ip.s
	setting.s
	*callback
EndStructure

Structure SessionMap
	Map hash.s()
EndStructure
	
Structure MapInStructure_i
	Map map_data.i()
EndStructure

Structure MapInStructure_s
	Map map_data.s()
EndStructure

; IDE Options = PureBasic 5.70 LTS (Windows - x86)
; EnableXP
; CompileSourceDirectory
; EnableUnicode