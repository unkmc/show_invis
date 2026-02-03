#Include classes\Utilities.ahk

global MOUNTS := ["Amethyst Dragon dog", "Armored horse saddle", "Red panther collar", "Black panther collar", "Mountain goat pan flute", "Green Rhino mount", "White Doe horn", "White tiger mount"]

class Waypoint {

	static mapId
	static x
	static y
	static direction

	__new(mapId, x, y, direction:=-1) {
		this.mapId := mapId
		this.x := x
		this.y := y
		this.direction := direction
	}
}

class NavigationBot Extends NexusTK {
	static waypoints := []

	__new(program:="ahk_exe NexusTK.exe") {
		base.__new(program)
	}

	addWaypoint(mapId, x, y, direction:="") {
		this.waypoints.push(new Waypoint(mapId, x, y, direction))
	}

	addWaypoints(waypoints) {
		for idx, waypoint in waypoints {
			this.waypoints.push(new Waypoint(waypoint.mapId, waypoint.x, waypoint.y, waypoint.direction))
		}
	}

	removeWaypoint(x, y) {
		for idx, waypoint in this.waypoints {
			if (waypoint.x == x and waypoint.y == y) {
				this.waypoints.remove(idx)
				break
			}
		}
	}

	getMountSlot() {
		For idx, mount in MOUNTS {
			mountSlot := this.getInventorySlot(mount)

			If (mountSlot != "") {
				Return mountSlot
			}
		}

		Return ""
	}

	useMount() {
		slot := "u" . this.getMountSlot()

		if (slot != "u") {
			this.sendKeyStroke(slot, 1000)
		}
	}

	unmount() {
		this.sendKeyStroke("r", 300)
	}

	getClosestWaypoint() {
		closest_dist := 999
		closest_idx  := 0
		for idx, waypoint in this.waypoints {
			dist := this.checkDistanceFromSelf(waypoint.x, waypoint.y)
			if (dist < closest_dist) {
				closest_dist := dist
				closest_idx := idx
			}
		}
		return closest_idx
	}

	addWaypointsFromRect(mapId, x, y, width, height, corner) {
		if (corner == "tl") {
			;; Top-left

			goingRight := true
			for i in range(height) {
				if (goingRight) {
					for j in range(width+1) {
						this.addWaypoint(mapId, (x + j), (y + i))
					}
				} else {
					for j in range(width, -1, -1) {
						this.addWaypoint(mapId, (x + j), (y + i))
					}	
				}
				goingRight := !goingRight
			}
		} else if (corner == "tr") {
			;; Top-right

			goingLeft := true
			for i in range(height) {
				if (goingLeft) {
					for j in range(width, -1, -1) {
						this.addWaypoint(mapId, (x + j), (y + i))
					}
				} else {
					for j in range(0, (width+1)) {
						this.addWaypoint(mapId, (x + j), (y + i))
					}	
				}
				goingLeft := !goingLeft
			}
		} else if (corner == "bl") {
			;; Bottom-left

			goingRight := true
			for i in range(height, -1, -1) {
				if (goingRight) {
					for j in range((width+1)) {
						this.addWaypoint(mapId, (x + j), (y + i))
					}
				} else {
					for j in range(width, -1, -1) {
						this.addWaypoint(mapId, (x + j), (y + i))
					}	
				}
				goingRight := !goingRight
			}
		} else if (corner == "br") {
			;; Bottom-right

			goingLeft := true
			for i in range(height, -1, -1) {
				if (goingLeft) {
					for j in range(width, -1, -1) {
						this.addWaypoint(mapId, (x + j), (y + i))
					}
				} else {
					for j in range(0, (width+1)) {
						this.addWaypoint(mapId, (x + j), (y + i))
					}
				}
				goingLeft := !goingLeft
			}
		}
	}
	
	removeWaypointsFromRect(x, y, width, height) {
		for i in range(height) {
			for j in range(width+1) {
				this.removeWaypoint((x + j), (y + i))
			}
		}
	}
}

;; Generates a list of waypoints for the given rectangle
waypointsFromRect(mapId, x, y, width, height, startX, startY) {
	waypoints := []

	if (startX == x and startY == y) {
		;; Top-left

		goingRight := true
		for i in range(height) {
			if (goingRight) {
				for j in range(width, -1) {
					waypoints.push(new Waypoint(mapId, (x + j), (y + i)))
				}
			} else {
				for j in range(width, -1, -1) {
					waypoints.push(new Waypoint(mapId, (x + j), (y + i)))
				}	
			}
			goingRight := !goingRight
		}
	} else if (startX == (x + width) and startY == y) {
		;; Top-right

		goingLeft := true
		for i in range(height) {
			if (goingLeft) {
				for j in range(width, -1, -1) {
					waypoints.push(new Waypoint(mapId, (x + j), (y + i)))
				}
			} else {
				for j in range(width, -1) {
					waypoints.push(new Waypoint(mapId, (x + j), (y + i)))
				}	
			}
			goingLeft := !goingLeft
		}
	} else if (startX == x and startY == (y + height)) {
		;; Bottom-left

		goingRight := true
		for i in range(height, -1, -1) {
			if (goingRight) {
				for j in range((width+1)) {
					waypoints.push(new Waypoint(mapId, (x + j), (y + i)))
				}
			} else {
				for j in range(width, -1, -1) {
					waypoints.push(new Waypoint(mapId, (x + j), (y + i)))
				}	
			}
			goingRight := !goingRight
		}
	} else if (startX == (x + width) and startY == (y + height)) {
		;; Bottom-right

		goingLeft := true
		for i in range(height, -1, -1) {
			if (goingLeft) {
				for j in range(width, -1, -1) {
					waypoints.push(new Waypoint(mapId, (x + j), (y + i)))
				}
			} else {
				for j in range(0, (width+1)) {
					waypoints.push(new Waypoint(mapId, (x + j), (y + i)))
				}
			}
			goingLeft := !goingLeft
		}
	}
	
	return waypoints
}