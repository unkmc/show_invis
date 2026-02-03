#Include NexusTK.ahk

Class Relogger Extends NexusTK {
	static Name
	static Pass
	static NTK_Path := "C:\Program Files (x86)\KRU\NexusTK\NexusTK.exe"
	static NTK_Dir
	static basePID
	
	__new(program:="ahk_exe NexusTK.exe", NTK_Path:="") {
		base.__new(program)
		
		;; Store PID
		UID := this.windowHandle
		WinGet, PID, PID, ahk_id %UID%
		this.basePID := PID
		
		;; Assign Relog Params
		Name := this.getName()
		Pass := "temp1"
		PassVer := "temp2"
		while (Pass != PassVer) {
			if (A_Index > 1) {
				MsgBox % "Passwords do not match, please try again"
			}
			InputBox, Pass, Please Enter %Name%'s Password,, HIDE
			InputBox, PassVer, Please Reenter %Name%'s Password,, HIDE
		}
		this.Name := Name
		this.Pass := Pass
		
		if (NTK_Path) {
			this.NTK_Path := NTK_Path
		}
		SplitPath, NTK_Path,,NTK_Dir
		this.NTK_Dir := NTK_Dir
	}
	
	isNexusOpen() {
		;; Get Process PID to check if the process is valid
		UID := this.windowHandle
		WinGet, PID, PID, ahk_id %UID%
		; MsgBox % "PID = " . PID . "`nthis.basePID = " . this.basePID
		Return PID == this.basePID
	}
	
	isAtLoginScreen() {
		if (this.isNexusOpen()) {
			idx := this.getLoginScreenIDX()
			if (idx) {
				return true
			} else {
				return false
			}
		} else {
			Return false
		}
	}
	
	;; Get the highlighted menu option i.e. (0 = new, 1 = continue, etc)
	getLoginScreenIDX(LOGIN_SCREEN_OFFSET:=0x2DDAE0, offset_1:=0xFA) {
		idx := this.nexusMemory.read(this.baseAddress + LOGIN_SCREEN_OFFSET, "UChar", offset_1) 
		return idx
	}
	
	getMenuName(LOGIN_DLG_NAME_OFFSET:=0x2FE1A8, offset_1 := 0x114, offset_2:=0x0, offset_3:=0x134, offset_4:=0x10, offset_5:=0) {
		name := this.nexusMemory.readString(this.baseAddress + LOGIN_DLG_NAME_OFFSET, 0, "UTF-16", offset_1, offset_2, offset_3, offset_4, offset_5) 
		return name
	}
	
	getMenuPassword(LOGIN_DLG_PASSWORD_OFFSET:=0x2FE1D4, offset_1 := 0x1FC, offset_2:=0x10, offset_3:=0x10, offset_4:=0x10C, offset_5:=0x134, offset_6:=0x10, offset_7:=0) {
		pass := this.nexusMemory.readString(this.baseAddress + LOGIN_DLG_PASSWORD_OFFSET, 0, "UTF-16", offset_1, offset_2, offset_3) 
		return pass
	}
	
	OpenNexus(OtherObj:="") {
		
		;; Run NexusTK.exe
		if (!this.isNexusOpen()) {
			MsgBox % "Opening Nexus"
			Path := this.NTK_Path
			WDir := this.NTK_Dir
			
			Run, %Path%, %WDir%,,PID
			this.basePID := PID
			Sleep 2000
			
			;; Hit enter to open
			Send, {Enter}
			Sleep, 5000
			
			;; Reassign memory handles
			program := "ahk_exe NexusTK.exe"
			this.nexusMemory := new _ClassMemory(program, "", hProcessCopy)
			this.nexusMemory.baseAddress := this.nexusMemory.baseAddress
			WinGet, hwnd, List, Nexus
			this.windowHandle := hwnd1
			
			if (OtherObj) {
				OtherObj.nexusMemory := new _ClassMemory(program, "", hProcessCopy)
				OtherObj.nexusMemory.baseAddress := this.nexusMemory.baseAddress
				OtherObj.windowHandle := hwnd1
			}

		}
		if (this.isAtLoginScreen()) {
			Sleep 500
			if (!this.isAtLoginScreen()) {
				return
			}
			;; Click on the login button
			idx := this.getLoginScreenIDX()
			while (idx != 1) {
				this.sendKeyStroke("{Down}", this.MEDIUM_DELAY)
				idx := this.getLoginScreenIDX()
			}
			this.sendKeyStroke("{Enter}", this.TINY_DELAY)
			Sleep, 500
			
			;; Enter UserName and Pass
			SetKeyDelay, 25, 10
			while (true) {
				this.sendKeyStroke(this.Name, this.TINY_DELAY)
				this.sendKeyStroke("{Tab}", this.TINY_DELAY)
				this.sendKeyStroke(this.Pass, this.TINY_DELAY)
				if (this.getMenuName() != this.Name or this.getMenuPassword != this.Pass) {
					this.sendKeyStroke("{Escape}", this.TINY_DELAY)
				} else {
					this.sendKeyStroke("{Enter}", this.TINY_DELAY)
					break
				}
			}
			
			;; Wait for Login
			While (!this.isLoggedIn()) {
				Sleep, 50
				If (A_Index > 100) {
					return
				}
			}
		}
	}
}