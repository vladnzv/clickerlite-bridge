DeclareModule Clicker
	Declare click(MouseX.f, MouseY.f)
	
EndDeclareModule


Module Clicker
	
	Procedure click(MouseX.f, MouseY.f)
		SetCursorPos_	(MouseX, MouseY)
		mouse_event_	(#MOUSEEVENTF_ABSOLUTE | #MOUSEEVENTF_LEFTDOWN, MouseX, MouseY, 0, 0)
		mouse_event_	(#MOUSEEVENTF_ABSOLUTE | #MOUSEEVENTF_LEFTUP, MouseX, MouseY, 0, 0)
	EndProcedure
	
	
EndModule
; IDE Options = PureBasic 5.51 (Windows - x86)
; CursorPosition = 15
; Folding = -
; EnableUnicode
; EnableXP