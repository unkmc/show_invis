#Include classes\Utilities.ahk



Class GridStencilReader {
	static mapFile

	__new(mapId) {
		this.mapFile := FileOpen(A_ScriptDir . "\GridStencils\TK" . this.padMapId(mapId) . ".gridstencil", "r")
	}

	getGridStencil() {
		gridStencil := Array()
		y := 0
		While (gridString := this.mapFile.ReadLine()) {
			y++
			For x in rangeincl(1, StrLen(gridString)) {
				gridStencil[x, y] := SubStr(gridString, x, 1)
			}
		}
		this.mapFile.Close()
		return gridStencil
	}

	padMapId(mapId) {
		While(StrLen(mapId) < 6) {
			mapId := "0" . mapId
		}

		Return mapId
	}

}
