#Include NexusTK.ahk

class AlertBot extends NexusTK {

	static beepDelay := 40		;; milliseconds
	static beepDuration := 250	;; milliseconds
	static beepFrequency := 950	;; Hz
	static beepVolume := 40		;; 0-100%

	static mobList := []

	__new(beepDelay:="", beepDuration:="", beepFrequency:="", beepVolume:="", program:="ahk_exe NexusTK.exe") {
		base.__new(program)

		if (beepDelay) {
			this.beepDelay := beepDelay
		}
		if (beepDuration) {
			this.beepDuration := beepDuration
		}
		if (beepFrequency) {
			this.beepFrequency := beepFrequency
		}
		if (beepVolume) {
			this.beepVolume := beepVolume
		}

		this.updateMobList()
	}

	beep(duration:="", frequency:="") {
		if (!duration) {
			duration := this.beepDuration
		}
		if (!frequency) {
			frequency := this.beepFrequency
		}

		;; Adjust volume and play beep
		SoundGet, masterVolume
		SoundSet, % this.beepVolume
		SoundBeep, frequency, duration
		SoundSet, % masterVolume
	}

	getMobList() {
		mobList := []

		;; Add Characters to Moblist
		mobInfo := this.compileMobInfo2()
		for index, element in mobInfo {
			if ((element["name"] != "") or (element["isInvisible"])) {
				mobList.Push(element["name"])
			}
		}

		return mobList
	}

	hasPlayerCountChanged() {
		if (this.mobList.length() != this.getMobList().length()) {
			return true
		}
		
		return false
	}

	updateMobList() {
		this.mobList := this.getMobList()
	}
}
