#Include Utilities.ahk

global nexusTKDataDir := "C:\Program Files (x86)\KRU\NexusTK\Data\"


Class SObjReader {

	static tileDat

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

				;; SObj.tbl
				this.objectCount := this.tileDat.ReadUInt()

				this.tileDat.Seek(2, 1)

				;; Collect SObjs
				For j in range(this.objectCount) {
					this.tileDat.Seek(5, 1)
					movementDirection := this.tileDat.ReadChar()
					height := this.tileDat.ReadChar()

					For k in range(height) {
						;; Skip tile indices
						this.tileDat.Seek(2, 1)
					}

					sObj := { movementDirection: movementDirection }
					this.objects.Push(sObj)
				}

				Break
			} Else {
				Continue
			}
		}

		this.tileDat.Close()
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
