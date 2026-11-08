DeclareModule ServerCore
	IncludeFile "server_constants.pb"
		
	Declare initParser(*AnalystRequest.request, Map _REQUEST.s(), Map _COOKIE())
	Declare sendError(ClientID)
	Global __request.s
EndDeclareModule

Module ServerCore
	
	; Sends a standard HTTP 404 Not Found response to the specified client
	Procedure sendError(ClientID)
		
		SendNetworkString(ClientID, "HTTP/1.1 404 Not Found" + #CRLF$)
		SendNetworkString(ClientID, "Date:" + FormatDate( #MASK_DATE, Date() ) + #CRLF$)
		SendNetworkString(ClientID, "Server: " + #SERVER_TITLE + #CRLF$)
		SendNetworkString(ClientID, "Content-Length: 0" + #CRLF$)
		SendNetworkString(ClientID, "Content-Type: text/html; charset=UTF-8" + #CRLF$)
		SendNetworkString(ClientID, "Access-Control-Allow-Origin: " + #DEFAULT_ADDRESS + #CRLF$)
		SendNetworkString(ClientID, #CRLF$)
		
	EndProcedure
	
	; Parses incoming HTTP 'Cookie' header into key-value pairs stored in the _COOKIE map
	Procedure parseCookie(Map _REQUEST.s(), Map _COOKIE.s())
		If Not FindMapElement( _REQUEST(), "Cookie" ) : ProcedureReturn #False : EndIf
		
		Protected temp_string.s, key.s, value.s
		
		For i=1 To CountString( _REQUEST("Cookie"), ";" ) + 1
			temp_string = StringField( _REQUEST("Cookie"), i, ";" )
			key		= Trim( StringField(temp_string, 1, "=") )
			value 	= Trim( StringField(temp_string, 2, "=") )
			_COOKIE(key) = value
		Next
		
		ProcedureReturn #True
	EndProcedure
	
	; Parses raw incoming HTTP request buffer into HTTP headers and payload parameters
	Procedure parseRequest(*AnalystRequest.request, Map _REQUEST.s())
		Protected request_text.s, string.s, key.s, value.s
		
		; Convert buffer to UTF-8 string
		request_text = PeekS( *AnalystRequest\buffer, 
		                      *AnalystRequest\buffer_size, 
		                      #PB_UTF8 ); flag is required to avoid invalid character decoding
		
		ReplaceString( request_text, Chr(13), Chr(10), #PB_String_InPlace )   ; Normalize line endings (CR to LF)
		request_text = ReplaceString( request_text, Chr(10)+Chr(10), Chr(10) ); Replace double LF with single LF
		
		__request = request_text
		CountString = CountString( request_text, Chr(10) )	    ; Count total lines in the request
		If CountString < 1   : ProcedureReturn #False : EndIf	; Return false if request is empty
		If CountString > 100 : CountString=100        : EndIf	; Limit parsing to the first 100 lines 
																; for security and efficiency
		
		CountString + 1											; Line index offset adjustment
		
		request_text = Trim (request_text)
		
		; Parse start line (HTTP method, target path, protocol version)
		string = StringField(request_text, 1, Chr(10))
		_REQUEST("method")		= Trim( StringField(string, 1, " ") )
		_REQUEST("address")		= Trim( StringField(string, 2, " ") )
		_REQUEST("protocol") 	= Trim( StringField(string, 3, " ") )
		
		; Parse remaining header lines into Key-Value pairs
		For i=2 To CountString
			string	= StringField(request_text, i, Chr(10))
			
			key		= StringField(string, 1, ":")   ; Extract header key
			value	= StringField(string, 2, ":")	; Extract header value
			_REQUEST( Trim(key) ) = Trim( value )
		Next
		
		; Extract payload body according to Content-Type
		If FindMapElement(_REQUEST(), "Content-Type")
			
			If FindString(_REQUEST("Content-Type"), "text/plain")
				_REQUEST("Content-Charset")	= StringField(_REQUEST("Content-Type"), 2, "=")
				_REQUEST("Content-Type")	= StringField(_REQUEST("Content-Type"), 1, ";")
				_REQUEST("Content-Data")	= StringField(request_text, CountString, Chr(10))
			ElseIf _REQUEST("Content-Type")	= "application/x-www-form-urlencoded"
				_REQUEST("x_form_data")		= StringField(request_text, CountString, Chr(10)) ; Extract request body line
			EndIf
		EndIf
		ProcedureReturn #True
	EndProcedure
	
	; Initializes the parser module, clears state maps, and initiates request/cookie parsing
	Procedure initParser(*AnalystRequest.request, Map _REQUEST.s(), Map _COOKIE.s())
		
		; MUST clear storage maps before processing a new request to remove stale data from previous calls
		
		ClearMap( _REQUEST() )
		ClearMap( _COOKIE() )
		
		If Not *AnalystRequest : ProcedureReturn #False : EndIf
		parseRequest(*AnalystRequest, _REQUEST())
		parseCookie(_REQUEST(), _COOKIE())
	EndProcedure
	
EndModule
; IDE Options = PureBasic 5.70 LTS (Windows - x86)
; CursorPosition = 93
; FirstLine = 33
; Folding = z-
; CompileSourceDirectory
; EnableUnicode