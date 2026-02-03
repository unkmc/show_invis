#Include Utilities.ahk

global nexusTKDataDir := "C:\Program Files (x86)\KRU\NexusTK\Data\"


Class SObjReader2 {

	static tileDat
	static dataStart

	static objectCount
	static objects := []

	__new() {
		;; https://autohotkey.com/docs/objects/File.htm#ReadNum
		;; tile.dat contains SObj.tbl -- (Static Objects)
		this.tileDat := FileOpen(nexusTKDataDir . "tile.dat", "r")

		;; File count
		fileCount := this.tileDat.ReadUInt() - 1

		;; Collect Files and find SObj.tbl
		For i in range(fileCount) {
			dataLocation := this.tileDat.ReadUInt()
			totalRead := 13
			readLength := this.lengthUntilZero()
			fileName := this.tileDat.Read(readLength)
			If (readLength < totalRead) {
				this.tileDat.Seek(totalRead-readLength, 1)
			}
			If (fileName == "SObj.tbl") {
				fileSize := this.tileDat.ReadUInt() - dataLocation
				this.tileDat.Seek(dataLocation)

				;; Object Count
				this.objectCount := this.tileDat.ReadUInt()

				this.tileDat.Seek(2, 1)

				;; Static Object Data Start
				this.dataStart := this.tileDat.Tell()

				Break
			} Else {
				Continue
			}
		}
	}

	getObject(index) {
		If (this.objects[index]) {
			Return this.objects[index]
		} Else {
			;; Try to find closest cached object
			For i in range(index, 0, -1) {
				If (this.objects[i].dataLocation) {
					startIndex := i
					startLocation := this.objects[i].dataLocation
					Break
				}
			}
			If (!startLocation) {
				startIndex := 1
				startLocation := this.dataStart
			}
		}

		;; Skip to index, collecting static objects
		this.tileDat.Seek(startLocation)
		For i in range(startIndex, index) {
			dataLocation := this.tileDat.Tell()
			this.tileDat.Seek(5, 1)
			movementDirection := this.tileDat.ReadChar()
			height := this.tileDat.ReadChar()
			If (!this.objects[i]) {
				this.objects[i] := { "dataLocation": dataLocation, "movementDirection": movementDirection }
			}

			;; Skip static object tiles
			this.tileDat.Seek((2 * height), 1)
		}

		;; Read Object Movement Direction
		this.tileDat.Seek(5, 1)
		this.objects[index] := { "dataLocation": dataLocation, "movementDirection": movementDirection }

		Return this.objects[index]
	}

	lengthUntilZero() {
		currentPosition := this.tileDat.Tell()
		length := 0

		While(True) {
			b := this.tileDat.ReadChar()
			If (b != 0) {
				length++
			} Else {
				Break
			}
		}

		this.tileDat.Seek(currentPosition)
		Return length
	}
}
