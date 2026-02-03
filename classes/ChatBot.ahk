#Include NexusTK.ahk

class ChatBot extends NexusTK {

	static T_UNKNOWN		:= 1
	static T_SYSTEM			:= 2
	static T_WHISPER_OUT	:= 3
	static T_WHISPER_IN		:= 4
	static T_CLAN_OUT		:= 5
	static T_CLAN_IN		:= 6
	static T_SUBPATH_OUT	:= 7
	static T_SUBPATH_IN		:= 8
	static T_ARCHON			:= 9
	static T_TALK			:= 10
	static T_SHOUT			:= 11
	static TYPES := ["Unknown"
		, "System"
		, "Whisper (Outgoing)"
		, "Whisper (Incoming)"
		, "Clan (Outgoing)"
		, "Clan (Incoming)"
		, "Subpath (Outgoing)"
		, "Subpath (Incoming)"
		, "Archon"
		, "Talk"
		, "Shout"]

	;; NPCs, etc to blacklist from logging
	static BLACKLIST_AUTHORS := ["Akoya"
		, "Alfaquin"
		, "Amgine"
		, "Celestial"
		, "Dust"
		, "Flaps"
		, "Gorem"
		, "Guk-su"
		, "Haeng"
		, "Ixat"
		, "Ox"
		, "Pandemonium"
		, "Singe"
		, "Sliver"
		, "Smudge"
		, "Sorrow"
		, "Stigma"
		, "Toadstool"
		, "Ulema"
		, "Walsuk"]

	static logChat := True
	static soundVolume := 60

	static LAST_SYSTEM
	static LAST_TALK
	
	static LOG := []
	static LOG_SIZE := 0

	__new(nexusTkIni:="", logChat:=True, logFilePath:="", program:="ahk_exe NexusTK.exe") {
		base.__new(program)

		;; Try to Load NexusTK.ini
		if (nexusTkIni) {
			this.NEXUSTK_INI := nexusTkIni
		}
		this.loadConfig()

		;; Set Logging
		this.logChat := logChat
		if (logFilePath) {
			this.LOG_FILE_PATH := logFilePath
		}

		;; Set Last System/Talk
		this.LAST_SYSTEM := this.getSystem(True)["message"]
		this.LAST_TALK := this.getTalk(True)["message"]
	}

	;; Loads NexusTK.ini, creates a new one if it doesn't exist
	loadConfig() {
		;; Check if file exists
		if (FileExist(this.NEXUSTK_INI)) {
			;; Open file and read key-values
			ini := FileOpen(this.NEXUSTK_INI, "r")
			while (line := ini.ReadLine()) {
				StringReplace, line, line, `r,, All
				StringReplace, line, line, `n,, All
				if (InStr(line, "=")) {
					keyValue := StrSplit(line, "=")
					key := keyValue[1]
					value := keyValue[2]

					if (key == "SystemReadIndex") {
						this.SYSTEM_READ_INDEX := value
					}
				}
			}
			ini.Close()
		} else {
			;; Create new config file with default value
			ini := FileOpen(this.NEXUSTK_INI, "w")
			ini.WriteLine("SystemReadIndex" . "=" . this.SYSTEM_READ_INDEX)
			ini.Close()
		}
	}

	playSound() {
		;; Adjust volume and play beep
		SoundGet, masterVolume
		SoundSet, % this.soundVolume
		SoundPlay, resources\sounds\talk.wav
		SoundSet, % masterVolume
	}

	getSystem(silent:=False) {
		system := this.nexusMemory.readString(this.SYSTEM_READ_ADDRESSES[this.SYSTEM_READ_INDEX], 0, "UTF-16")

		if (system != this.LAST_SYSTEM) {
			this.LAST_SYSTEM := system
			time := A_Now
			if (RegExMatch(this.LAST_SYSTEM, "\[([^\]]*)\]: (.*$)", matches)) {
				type := this.T_SYSTEM
				author := matches1
				recipient := "N/A"
				message := matches2
			} else if (RegExMatch(this.LAST_SYSTEM, "^<!([^\(]*)[^>]*>\s(.*$)", matches)) {
				author := matches1
				if (author == this.getName()) {
					type := this.T_CLAN_OUT
				} else {
					type := this.T_CLAN_IN
				}
				recipient := "N/A"
				message := matches2
			} else if (RegExMatch(this.LAST_SYSTEM, "^<@([^\(]*)[^>]*>\s(.*$)", matches)) {
				author := matches1
				if (author == this.getName()) {
					type := this.T_SUBPATH_OUT
				} else {
					type := this.T_SUBPATH_IN
				}
				recipient := "N/A"
				message := matches2
			} else if (RegExMatch(this.LAST_SYSTEM, "(^[^!]*)! (.*$)", matches)) {
				author := matches1
				type := this.T_ARCHON
				recipient := "N/A"
				message := matches2
			} else if (RegExMatch(this.LAST_SYSTEM, "(^[^>]*)> (.*$)", matches)) {
				type := this.T_WHISPER_OUT
				author := this.getName()
				recipient := matches1
				message := matches2
				;; Fix subpath w/ spaces bug in NexusTK whispering
				if (InStr(this.getSubpath(), " ")) {
					subpathParts := StrSplit(this.getSubpath(), " ").length()
					for idx in range(subpathParts) {
						message := RegExReplace(message, "^[^\s]*\s(.*$)", "$1")
					}
				}
			} else if (RegExMatch(this.LAST_SYSTEM, "(^[^\(]*)[^""]*""\s(.*$)", matches)) {
				type := this.T_WHISPER_IN
				author := matches1
				recipient := this.getName()
				message := matches2
				if (!silent) {
					this.playSound()
				}
			} else {
				author := "Unknown (S)"
				type := this.T_UNKNOWN
				recipient := "Unknown"
				message := this.LAST_SYSTEM
			}

			logItem := { "time": time, "type": type, "character": this.getName(), "author": author, "recipient": recipient, "message": message }
			this.LOG.Push(logItem)

			if (this.logChat) {
				this.writeToLog()
			}
			
			return logItem
		}
	}

	getTalk(silent:=False, offset_1:=0x424, offset_2:=0x2C, offset_3:=0x10, offset_4:=0x0, offset_5:=0x12C) {
		talk := this.getLastTalk()

		if (talk != this.LAST_TALK) {
			this.LAST_TALK := talk
			time := A_Now
			if (RegExMatch(this.LAST_TALK, "(^[^:]*):\s(.*$)", matches)) {
				type := this.T_TALK
				author := matches1
				recipient := "N/A"
				message := matches2
			} else if (RegExMatch(this.LAST_TALK, "(^[^!]*)!\s(.*$)", matches)) {
				type := this.T_SHOUT
				author := matches1
				recipient := "N/A"
				message := matches2
			} else {
				author := "Unknown"
				type := this.T_UNKNOWN
				recipient := "Unknown"
				message := this.LAST_TALK
			}

			if (author != "Unknown" and !HasVal(this.BLACKLIST_AUTHORS, author)) {
				logItem := { "time": time, "type": type, "character": this.getName(), "author": author, "recipient": recipient, "message": message }
				this.LOG.Push(logItem)

				if (!silent and author != this.getName()) {
					this.playSound()
				}
			}

			if (this.logChat) {
				this.writeToLog()
			}

			return logItem
		}
	}

	writeToLog() {
		;; Create NexusCE directory in App Data
		if (!FileExist(this.NEXUSCE_APPDATA)) {
			FileCreateDir, % this.NEXUSCE_APPDATA
		}

		if (this.LOG.length() > this.LOG_SIZE) {
			this.LOG_SIZE++
			logItem := this.LOG[this.LOG_SIZE]

			logFile := FileOpen(this.NEXUSCE_APPDATA . "\" . this.LOG_FILE, "a")
			logFile.WriteLine(logItem["time"] . ";;" . logItem["type"] . ";;" . logItem["character"] . ";;" . logItem["author"] . ";;" . logItem["recipient"] . ";;" . logItem["message"])
			logFile.Close()
		}
	}
}