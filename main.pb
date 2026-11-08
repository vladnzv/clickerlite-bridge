XIncludeFile "click.pb"

XIncludeFile "servercore_module.pb"

DeclareModule Main
	IncludeFile "server_constants.pb"
	
	Global NewMap _REQUEST.s   () ; Stores the HTTP request data received from the client
	Global NewMap _COOKIE.s    () ; Stores cookies received from the client
	
	Global 	serverInfo.info,
	       	g__ClientID,
	       	g_Console
	
	#APP_TITLE      = "Clickerlite Bridge"
	#VERSION_MAJOR  = 0
	#VERSION_MINOR  = 1
	#VERSION_PATCH  = 0
	#VERSION_STRING = "0.1.0"
	#VERSION_NAME   = #APP_TITLE + " v" + #VERSION_STRING
	
	#L_START_SERVER = "Server started..."
	#L_SERVER_ERROR_START = "Unable to start server"
	
	#CTRL_CLOSE_EVENT = 2
	
	Declare init()
EndDeclareModule

Module Main
	#ENABLE_QUICK_EDIT_MODE = $0040
	Prototype requestCallback(ObjectValue)
	
	; Gracefully shuts down the server and closes the application
	Procedure closeApp()
		; 1. Signal that the server is closing
		serverInfo\server_close = #True
		
		; 2. Print a message to the console (if still available)
		PrintN("Console close event received!")
		
		; 3. Close the network server to unblock active threads
		If serverInfo\id_server
			CloseNetworkServer(serverInfo\id_server)
			serverInfo\id_server = 0
		EndIf
		
		; 4. Brief pause for background tasks to complete cleanly
		If serverInfo\id_thread_events
			WaitThread(serverInfo\id_thread_events, 500)
		EndIf
		Delay(500)
		
		; 5. Terminate the application
		End
	EndProcedure
	
	;{ AJAX Methods
	
	; Sends an HTTP/JSON response back to the connected client
	Procedure sendResponseAJAX(response.s="", cookie_callback=#False)
		
		mask_date.s = "%yyyy-%mm-%dd, %hh:%ii:%ss"
		
		content_type.s = "application/json; charset=UTF-8"
		responseType.s = "text"
		content_length.s = Str( StringByteLength(response, #PB_UTF8) )
		
		SendNetworkString(g__ClientID, "HTTP/1.1 200 OK" + #CRLF$)
		SendNetworkString(g__ClientID, "Date:" + FormatDate( mask_date, Date() ) + #CRLF$)
		SendNetworkString(g__ClientID, "Server: " + #SERVER_TITLE + #CRLF$)
		SendNetworkString(g__ClientID, "Content-Type: " + content_type + #CRLF$)
		SendNetworkString(g__ClientID, "responseType: " + responseType + #CRLF$)
		SendNetworkString(g__ClientID, "Content-Length: " + content_length + #CRLF$)
		SendNetworkString(g__ClientID, "Pragma: " + "no-cache" + #CRLF$)
		SendNetworkString(g__ClientID, "Access-Control-Allow-Origin: " + #DEFAULT_ADDRESS + #CRLF$)
		SendNetworkString(g__ClientID, #CRLF$)
		SendNetworkString(g__ClientID, response + #CRLF$)
		
	EndProcedure
	
	; Validates JSON object fields against a specific data type
	Procedure checkTypeJSON(ObjectValue, fields.s, type)
		
		If Not ObjectValue
			ProcedureReturn #False
		EndIf
		
		For i=1 To CountString(fields, ",")+1
			field.s = Trim ( StringField(fields, i, ",") )
			
			If Not JSONType( GetJSONMember(ObjectValue, field) ) = type
				ProcedureReturn #False
			EndIf
		Next
		
		ProcedureReturn #True
	EndProcedure
	
	; Sends an error message as a JSON string response
	Procedure sendErrorAJAX(string.s)
		response.s =  Chr('"') + string + Chr('"')
		sendResponseAJAX(response)
	EndProcedure
	
	; Parses incoming AJAX request payload and invokes the callback function
	Procedure handleAjaxRequest( *callback )
		
		requestCallback.requestCallback = *callback
		
		If _REQUEST("Content-Type") = "text/plain"
			hJSON = ParseJSON(#PB_Any, _REQUEST("Content-Data"), #PB_JSON_NoCase)
		EndIf
		
		If Not hJSON
			sendErrorAJAX("Error: Failed to receive JSON")
			ProcedureReturn #False
		EndIf
		
		ObjectValue = JSONValue(hJSON)
		
		If Not ObjectValue
			sendErrorAJAX("Error: Failed to parse JSON")
			ProcedureReturn #False
		EndIf
		
		If ExamineJSONMembers(ObjectValue)
			requestCallback(ObjectValue)
			FreeJSON(hJSON)
		EndIf
		
		ProcedureReturn #True
	EndProcedure
	
	;} End AJAX Method
	
	; Infinite loop to keep the console mode active and handle exit commands
	Procedure initConsoleMode()
		Repeat
			Select Input()
				Case "0", "e", "exit"
					closeApp()
			EndSelect
		ForEver
	EndProcedure
	
	; Disables the Windows console QuickEdit mode 
	; to prevent accidental text selection freezing execution
	Procedure DisableQuickEdit()
		Protected hInput = GetStdHandle_(#STD_INPUT_HANDLE)
		Protected mode.l
		If GetConsoleMode_(hInput, @mode)
			mode = mode & ~#ENABLE_QUICK_EDIT_MODE
			SetConsoleMode_(hInput, mode)
		EndIf
	EndProcedure
	
	; System control handler callback invoked when closing the console window
	Procedure ConsoleCtrlHandler(CtrlType.l)
		Select CtrlType
			Case #CTRL_CLOSE_EVENT
				closeApp()
		EndSelect
		
		ProcedureReturn #False ; Return False for all other system events
	EndProcedure
	
	; Callback executed upon receiving valid click coordinates via AJAX
	Procedure ajaxCallback( ObjectValue )
		x.f = GetJSONDouble(GetJSONMember(ObjectValue, "x"))
		y.f = GetJSONDouble(GetJSONMember(ObjectValue, "y"))
		Clicker::click(x, y)
		
		log.s = "["+ FormatDate("%yyyy-%mm-%dd, %hh:%ii:%ss", Date()) +"] " + "Client ID: " + g__ClientID + " | Click: X=" + StrF(x, 1) + ", Y=" + StrF(y, 1)
		PrintN(log)
		
		sendResponseAJAX("true")
	EndProcedure
	
	; Background thread monitoring network server events (connections, incoming data)
	Procedure handlerEvents(value)
		Repeat
			
			Select NetworkServerEvent(serverInfo\id_server)
					
				Case #PB_NetworkEvent_Data
					AnalystRequest.request
					g__ClientID = EventClient()
					AnalystRequest\client_id	= g__ClientID
					AnalystRequest\buffer		= AllocateMemory( ReadPreferenceInteger("memory_size", #MEMORY_SIZE) )
					AnalystRequest\buffer_size	= ReceiveNetworkData( AnalystRequest\client_id,
					                          	                      AnalystRequest\buffer,
					                          	                      ReadPreferenceInteger("memory_size", #MEMORY_SIZE) )
					
					If AnalystRequest\buffer_size > 0
						
						log.s = "["+ FormatDate("%yyyy-%mm-%dd, %hh:%ii:%ss", Date()) +"] " + "Client ID: " + AnalystRequest\client_id
						;PrintN ( log )
						
						ServerCore::initParser(@AnalystRequest, _REQUEST(), _COOKIE())
						
						handleAjaxRequest( @ajaxCallback() )
						
					EndIf
					
					FreeMemory(AnalystRequest\buffer)
					
				Case #PB_NetworkEvent_None					
				Case #PB_NetworkEvent_Connect
				Case #PB_NetworkEvent_Disconnect
			EndSelect
			Delay (1)
		Until serverInfo\server_close = #True
	EndProcedure
	
	; Choose a new port, if old is occupied
	Procedure ChooseNewPort()
		settings.init
		settings\ip = #DEFAULT_IP
		settings\port = #DEFAULT_PORT
		settings\type = #PB_Network_TCP
		Repeat
			Print("Enter a different port number (or type 'exit' to quit): ")
			inputStr.s = Trim(Input())
			
			; Allow the user to terminate the application gracefully
			If inputStr = "exit" Or inputStr = "e"
				End
			EndIf
			
			; Fallback to default port 8080 if left empty
			If inputStr = ""
				settings\port = #DEFAULT_PORT
			Else
				settings\port = Val(inputStr)
			EndIf
			
			; Attempt to create the network server on the requested port
			serverInfo\id_server = CreateNetworkServer(#PB_Any, settings\port, settings\type, settings\ip)
			
			If serverInfo\id_server
				PrintN("Server successfully started on port " + settings\port)
				Break ; Port bound successfully, exit loop
			Else
				PrintN("Failed to start server on port " + Str(settings\port) + ". Port may be occupied or requires administrator rights.")
				PrintN("")
			EndIf
		ForEver
	EndProcedure
	
	; Initializes network services and starts the background event listener thread
	Procedure start()
		settings.init
		settings\ip = #DEFAULT_IP
		settings\port = #DEFAULT_PORT
		settings\type = #PB_Network_TCP
		
		If Not InitNetwork()
			PrintN("Server error - network library initialization failed!")
			End
		EndIf
		
		serverInfo\id_server = CreateNetworkServer(#PB_Any, settings\port, settings\type, settings\ip)
		
		If Not serverInfo\id_server
			PrintN("Server error - failed to start server on port " + settings\port)
			ChooseNewPort()
		EndIf
		
		serverInfo\id_thread_events = CreateThread(@handlerEvents(), 42)
		If Not serverInfo\id_thread_events
			PrintN("Server error - failed to create event handler thread")
			End
		EndIf
		
		ProcedureReturn #True
	EndProcedure
	
	; Main module initialization routine
	Procedure init()
		g_Console = OpenConsole(#VERSION_NAME)
		If Not g_Console
			MessageRequester("Error", "Can't open Console!", #PB_MessageRequester_Error)
			End
		EndIf
		PrintN(#L_START_SERVER + " Port: " + #DEFAULT_PORT)
		
		SetConsoleCtrlHandler_(@ConsoleCtrlHandler(), #True) ; Intercept console close events
		
		; Disable QuickEdit mode
		DisableQuickEdit()
		
		If Not start()
			PrintN(#L_SERVER_ERROR_START)
		EndIf
		
		initConsoleMode()
	EndProcedure
	
EndModule

Main::init()
; IDE Options = PureBasic 5.70 LTS (Windows - x86)
; CursorPosition = 173
; FirstLine = 40
; Folding = Dg2
; Executable = ClickerliteBridge.exe
; CompileSourceDirectory
; IncludeVersionInfo
; VersionField0 = 0.1.0
; VersionField1 = 0.1.0
; VersionField2 = Vladyslav Nazarov
; VersionField3 = Clickerlite Bridge
; VersionField4 = 0.1.0
; VersionField5 = 0.1.0
; VersionField9 = 2026 Vladyslav Nazarov
; VersionField14 = https://github.com/vladnzv
; EnableUnicode