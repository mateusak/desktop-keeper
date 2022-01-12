#NoEnv
#Persistent
#SingleInstance Force
SetWorkingDir %A_ScriptDir%

loop
{
	if (A_ScreenWidth == ScreenW and A_ScreenHeight == ScreenH)
	{
		IconPositions := DeskIcons()
		
		if (IconPositions)
		{
			FileDelete, %A_ScreenWidth%x%A_ScreenHeight%.txt
			FileAppend, %IconPositions%, %A_ScreenWidth%x%A_ScreenHeight%.txt
		}
	}
	else
	{
		sleep 10000
		
		FileRead, IconPositions, %A_ScreenWidth%x%A_ScreenHeight%.txt
		DeskIcons(IconPositions)
	}
	
	ScreenW := A_ScreenWidth
	ScreenH := A_ScreenHeight
	
	sleep 10000
}

DeskIcons(coords="")
{
	Critical
	static MEM_COMMIT := 0x1000, PAGE_READWRITE := 0x04, MEM_RELEASE := 0x8000
	static LVM_GETITEMPOSITION := 0x00001010, LVM_SETITEMPOSITION := 0x0000100F, WM_SETREDRAW := 0x000B
	
	ControlGet, hwWindow, HWND,, SysListView321, ahk_class Progman

	if !hwWindow ; #D mode
		ControlGet, hwWindow, HWND,, SysListView321, A

	IfWinExist ahk_id %hwWindow%
		WinGet, iProcessID, PID

	hProcess := DllCall("OpenProcess", "UInt",	0x438
												, "Int",	FALSE
												, "ptr",	iProcessID)
	if hwWindow and hProcess
	{	
		ControlGet, list, list, Col1

		if !coords
		{
			VarSetCapacity(iCoord, 8)
			pItemCoord := DllCall("VirtualAllocEx", "ptr", hProcess, "ptr", 0, "UInt", 8, "UInt", MEM_COMMIT, "UInt", PAGE_READWRITE)

			Loop, Parse, list, `n
			{
				SendMessage, %LVM_GETITEMPOSITION%, % A_Index-1, %pItemCoord%
				DllCall("ReadProcessMemory", "ptr", hProcess, "ptr", pItemCoord, "UInt", &iCoord, "UInt", 8, "UIntP", cbReadWritten)

				ret .= A_LoopField ":" (NumGet(iCoord,"Int") & 0xFFFF) | ((Numget(iCoord, 4,"Int") & 0xFFFF) << 16) "`n"
			}

			DllCall("VirtualFreeEx", "ptr", hProcess, "ptr", pItemCoord, "ptr", 0, "UInt", MEM_RELEASE)
		}
		else
		{
			SendMessage, %WM_SETREDRAW%,0,0

			Loop, Parse, list, `n
				If RegExMatch(coords,"\Q" A_LoopField "\E:\K.*",iCoord_new)
					SendMessage, %LVM_SETITEMPOSITION%, % A_Index-1, %iCoord_new%
			
			SendMessage, %WM_SETREDRAW%,1,0
			ret := true
		}
	}

	DllCall("CloseHandle", "ptr", hProcess)

	return ret
}