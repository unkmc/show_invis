#Include Utilities.ahk

global mapDir := "C:\Users\" . A_UserName . "\Documents\NexusTK\Maps\TK"


Class CmpReader {

	static mapWidth
	static mapHeight

	static mapTiles := []

	__new(mapId) {
		;; https://autohotkey.com/docs/objects/File.htm#ReadNum
		mapFile := FileOpen(mapDir . this.padMapId(mapId) . ".cmp", "r")

		;; CMAP
		mapFile.Seek(4)

		;; Map Dimensions
		this.mapWidth := mapFile.ReadUShort()
		this.mapHeight := mapFile.ReadUShort()

		;; Inflate Map Data
		compressedDataLength := mapFile.Length - 8 ;; Header + Dimensions
		mapFile.RawRead(compressedMapData, compressedDataLength)
		decompressedLength := this.zlib_Decompress(decompressed, compressedMapData, compressedDataLength)

		;; Collect Tiles
		For i in range(0, (decompressedLength / 6)) {
			idx := (i * 6)
			passableTile := NumGet(decompressed, (idx + 2), "UShort")
			sObjTile := NumGet(decompressed, (idx + 4), "UShort") - 1
			tile := { "passableTile": passableTile, "sObjTile": sObjTile }
			this.mapTiles.Push(tile)
		}

		mapFile.Close()
	}

	padMapId(mapId) {
		While(StrLen(mapId) < 6) {
			mapId := "0" . mapId
		}

		Return mapId
	}

	;; https://autohotkey.com/board/topic/63343-zlib/
	zlib_Decompress(Byref Decompressed, Byref CompressedData, DataLen, OriginalSize = -1) {
		OriginalSize := (OriginalSize > 0) ? OriginalSize : DataLen*15 ;should be large enough for most cases
		VarSetCapacity(Decompressed,OriginalSize)
		ErrorLevel := DllCall(".\lib\zlib1\uncompress", "Ptr", &Decompressed, "UIntP", OriginalSize, "Ptr", &CompressedData, "UInt", DataLen)

		return ErrorLevel ? 0 : OriginalSize
	}
}
