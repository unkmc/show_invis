class Item {

	static id
	static name
	static stackable
	static steps := []
	static stepIndex

	__new(id, name, stackable:=False, steps:="", stepIndex:=1) {
		this.id := id
		this.name := name
		this.stackable := stackable
		this.steps := steps
		if (this.steps == "") {
			this.steps := []
		}
		this.stepIndex := stepIndex
	}

	addStep(step) {
		this.steps.push(step)
	}

	addSteps(steps*) {
		for idx, step in steps {
			this.addStep(step)
		}
	}

	addStepRange(start, stop, step:=1) {
		if (start < 1 or stop < 1) {
			return	;; start and stop cannot be negative
		}
		
		steps := rangeincl(start, stop, step)
		this.addSteps(steps)
	}
}


class InventoryBot extends NexusTK {

	static LOGGED_ATTEMPTS := {}

	__new(program:="ahk_exe NexusTK.exe") {
		base.__new(program)
		this.initialize()
	}

	initialize() {
		this.loadLogs()
		for idx, item in ITEMS {
			attemptItems[item.id] := item.steps[1]
		}
	}

	onFirstCheck() {
		for idx, item in ITEMS {
			if (item.stepIndex != 1) {
				return False
			}
		}

		return True
	}

	calculateAllAttempts() {
		;; Update Analytics
		GuiControlGet, totalCombosToTry,, C_COMBOS_VAL
		GuiControl,, C_COMBOS_VAL, % --totalCombosToTry
		GuiControl,, C_EST_TIME_VAL, % (totalCombosToTry * 10 / 60)
		while (true) {
			item := ITEMS[START_INDEX]
			if (item.stepIndex < item.steps.length()) {
				item.stepIndex := item.stepIndex + 1
				attemptItems[item.id] := item.steps[item.stepIndex]
			} else {
				item.stepIndex := 1
				attemptItems[item.id] := item.steps[item.stepIndex]

				for idx in rangeincl((START_INDEX+1), ITEMS.length()) {
					if (attemptItems[ITEMS[idx].id] == ITEMS[idx].steps[ITEMS[idx].steps.length()]) {
						attemptItems[ITEMS[idx].id] := ITEMS[idx].steps[1]
						ITEMS[idx].stepIndex := 1
					} else {
						attemptItems[ITEMS[idx].id] := ITEMS[idx].steps[ITEMS[idx].stepIndex + 1]
						ITEMS[idx].stepIndex := ITEMS[idx].stepIndex + 1
						Break
					}
				}
			}

			if (this.hasBeenRun()) {
				;; Update Analytics
				totalCombosToTry--
			}
		}
		
		GuiControl,, C_COMBOS_VAL, % totalCombosToTry
		GuiControl,, C_EST_TIME_VAL, % (totalCombosToTry * 10 / 60)
	}
	
	;; Updates 'global attemptItems' with item quantities to use
	calculateNextAttempt() {
		item := ITEMS[START_INDEX]
		if (item.stepIndex < item.steps.length()) {
			item.stepIndex := item.stepIndex + 1
			attemptItems[item.id] := item.steps[item.stepIndex]
		} else {
			item.stepIndex := 1
			attemptItems[item.id] := item.steps[item.stepIndex]

			for idx in rangeincl((START_INDEX+1), ITEMS.length()) {
				if (attemptItems[ITEMS[idx].id] == ITEMS[idx].steps[ITEMS[idx].steps.length()]) {
					attemptItems[ITEMS[idx].id] := ITEMS[idx].steps[1]
					ITEMS[idx].stepIndex := 1
				} else {
					attemptItems[ITEMS[idx].id] := ITEMS[idx].steps[ITEMS[idx].stepIndex + 1]
					ITEMS[idx].stepIndex := ITEMS[idx].stepIndex + 1
					Break
				}
			}
		}

		;; Update GUI
		for idx, item in ITEMS {
			y := idx * 18 
			GuiControl,, C_ITEM_%idx%, % item.name . ": " . attemptItems[item.id]
		}
	}

	openCreationSystem() {
		while (true) {
			if (this.isMenuOpen()) {
				this.sendKeyStroke(this.K_ESC, 50)
				this.sendKeyStroke(this.K_ESC, 400)
			}

			this.sendKeyStroke("{ShiftDown}I{ShiftUp}", 500)
			
			if (this.isMenuOpen()) {
				break
			}
		}
	}

	sendCombination() {
		;; Tab twice to hit "OK"
		this.sendKeyStroke(this.K_TAB, 60)
		this.sendKeyStroke(this.K_TAB, 60)
		this.sendKeyStroke(this.K_ENTER, 200)
	}

	verifyAddedItems(delay:=25) {
		Sleep, % delay ; gives time for the last item to appear in memory
		itemList := MEMORY_HANDLE.getCreationList()
		for idx, cItem in itemList {
			item := ITEMS[idx]
			if (!item.stackable) {
				if (item.name != cItem) {
					Sleep, 100
					if (item.name != cItem) {
						return false
					}
				}
			} else {
				if (item.name . " (" . attemptItems[item.id] . ")" != cItem) {
					Sleep, 100
					if (item.name . " (" . attemptItems[item.id] . ")" != cItem) {
						return false
					}
				}
			}
		}

		return true
	}

	addAttemptItem(item) {
		;; Hit 'Add'
		this.sendKeyStroke(this.K_ENTER, 1)

		;; Wait until the 'Add' page is up
		while (this.getOpenMenuCount() != 2) {
			Sleep, 1
		}
		Sleep, 50

		;; Move down to 1st item and 'Add'
		this.sendKeyStroke(this.K_DOWN, 80)

		if (item["stackable"]) {
			this.sendKeyStroke(this.K_ENTER, 180)
			Sleep, 600
			
			while (true) {
				this.sendKeyStroke(attemptItems[item.id], 200)
				this.sendKeyStroke(this.K_ENTER, 300)

				if (this.getOpenMenuCount() == 3) {
					;; Entered incorrect quantity
					this.sendKeyStroke(this.K_ENTER, 200)
					for i in range(6) {
						this.sendKeyStroke(this.K_BACKSPACE, 40)
					}
				} else {
					;; Entered without error
					break
				}
			}
		} else {
			this.sendKeyStroke("{CtrlDown}", 50)
			for idx in range(1, attemptItems[item.id]) {
				this.sendKeyStroke(this.K_DOWN, 50)
			}
			this.sendKeyStroke("{CtrlUp}", 50)
			this.sendKeyStroke(this.K_ENTER, 200)
		}
	}
	
	addAttemptItems() {
		for idx, item in ITEMS {
			this.addAttemptItem(item)
		}
	}

	getOpenMenuCount() {
		return this.nexusMemory.read(this.baseAddress + 0x2FE0C4, "UChar")
	}

	printAttemptItems() {
		solveString := ""
		for idx, item in ITEMS {
			solveString := solveString . item.name . ": " . attemptItems[item.id] . "`n"
		}
		
		MsgBox % solveString
	}

	logAmounts() {
		logFile := FileOpen(LOG_FILE_PATH, "a")

		for idx in rangeincl(1, ITEMS.length()) {
			for idy, item in ITEMS {
				if (item.id == idx) {
					if (idx == 1) {
						logString := attemptItems[item.id]
					} else {
						logString := logString . "," . attemptItems[item.id]
					}
				}
			}
		}

		logFile.write("`n" . logString)
		logFile.close()

		this.LOGGED_ATTEMPTS[this.getAttemptHash()] := 3
	}

	loadLogs() {
		if (FileExist(LOG_FILE_PATH)) {
			logFile := FileOpen(LOG_FILE_PATH, "r")
			while(logLine := logFile.readLine()) {
				if (!InStr(logLine, ",")) {
					Continue
				} Else {
					StringReplace, logLine, logLine, `r,, All
					StringReplace, logLine, logLine, `n,, All
					this.LOGGED_ATTEMPTS[StrReplace(logLine, ",", "")] := 3
				}
			}
		}
	}

	getAttemptHash() {
		attemptHash := ""
		for idx in rangeincl(1, ITEMS.length()) {
			for idy, item in ITEMS {
				if (item.id == idx) {
					attemptHash := attemptHash . attemptItems[item.id]
				}
			}
		}
		
		return attemptHash
	}
	
	hasBeenRun() {
		return (this.LOGGED_ATTEMPTS[this.getAttemptHash()] == 3)
	}
}