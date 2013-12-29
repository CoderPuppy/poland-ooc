import structs/[HashMap, ArrayList]
import Call, poland/userdata/[UserData, Symbol, Msg]
import math/Random

PObject: class extends PUserData {
	_id: String

	init: func {
		arr := ArrayList<Char> new()
		for(i in 0..12) {
			arr add(Random randInt(0, 75) as Char + '0')
		}
		_id = arr join()
	}

	id: func -> String { _id }

	send: func~objs(id: PUserData, args: ...) -> PObject {
		PCall fromObjects(this, id, args) send()
	}

	send: func~str_objs(id: String, args: ...) -> PObject {
		PCall fromObjects~str(this, id, args) send()
	}

	send: func~sym_objs(id: String, args: ...) -> PObject {
		PCall fromObjects~sym(this, id, args) send()
	}

	receive: func(call: PCall) -> PObject {
		cell := this[call msg id]
		return cell
	}

	mimics := ArrayList<PObject> new()

	cells := HashMap<String, PObject> new()
	operator [](name: String) -> PObject {
		if(cells contains?(name)) {
			return cells get(name)
		} else {
			for(mimic in mimics) {
				o := mimic[name]

				if(o != null) {
					return o
				}
			}

			return null
		}
	}
	operator []=(name: String, val: PObject) -> PObject {
		cells put(name, val)
		return val
	}

	operator [](key: PUserData) -> PObject { this[key id()] }
	operator []=(key: PUserData, val: PObject) -> PObject {
		this[key id()] = val
		return val
	}
}