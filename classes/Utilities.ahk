decToHex(Value)
{
	SetFormat IntegerFast, Hex
	Value += 0
	Value .= ""
	SetFormat IntegerFast, D

	Return Value
}

StrLower(Str) {
	StringLower, NewStr, Str
	Return NewStr
}

printTime(t0, funcName) {
	if (profile) {
		tDelta := A_TickCount - t0
		MsgBox % "Time of " . funcName . " = " tDelta
	}
}
		
		
multiplyHex(hexValue, multiplicant) {
	newHexValue = 0x00
	Loop %multiplicant% {
		newHexValue := newHexValue + hexValue
	}

	Return newHexValue
}

isUpper(c) {
	StringUpper, upperC, c
	Return (c == upperC)
}

StrCount(H, N) {
	Pos := 0, Count := 0

	Loop
		If (Pos := InStr(H, N, False, Pos + 1))
			Count++
		Else
			break

	return Count
}

;; Range Utils: https://autohotkey.com/boards/viewtopic.php?t=4303
rangeincl(start, stop:="", step:=1) {
	If (stop) {
		stop := stop + step
	}
	return range(start, stop, step)
}

range(start, stop:="", step:=1) {
	static range := { _NewEnum: Func("_RangeNewEnum") }
	if !step
		throw "range(): Parameter 'step' must not be 0 or blank"
	if (stop == "")
		stop := start, start := 0
	if (step > 0 ? start < stop : start > stop) ;
		return { base: range, start: start, stop: stop, step: step }
}

_RangeNewEnum(r) {
	static enum := { "Next": Func("_RangeEnumNext") }
	return { base: enum, r: r, i: 0 }
}

_RangeEnumNext(enum, ByRef k, ByRef v:="") {
	stop := enum.r.stop, step := enum.r.step
	, k := enum.r.start + step*enum.i
	if (ret := step > 0 ? k < stop : k > stop)
		enum.i += 1
	return ret
}

HasVal(haystack, needle) {
	if !(IsObject(haystack)) || (haystack.Length() = 0)
		return 0
	for index, value in haystack
		if (value = needle)
			return index
	return 0
}

trimArray(arr) { ; Hash O(n)

    hash := {}, newArr := []

    for e, v in arr
        if (!hash[v])
            hash[(v)] := 1, newArr.push(v)

    return newArr
}


moveDirection(sX, sY, tX, tY) {
	xDistance := tX - sX
	yDistance := tY - sY

	If (Abs(xDistance) > Abs(yDistance)) {
		If (xDistance > 0) {
			Return 1
		} Else {
			Return 3
		}
	} Else {
		If (yDistance > 0) {
			Return 2
		} Else {
			Return 0
		}
	}
	Return False
}

Join(sep, params*) {
    for index,param in params
        str .= param . sep
    return SubStr(str, 1, -StrLen(sep))
}