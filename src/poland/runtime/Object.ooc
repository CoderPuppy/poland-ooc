import structs/[HashMap, ArrayList]
import math/Random
import Call, NativeFunction, Runtime
import poland/userdata/[UserData, Symbol, Msg]

PObject: class extends PUserData {
	_id: String

	metafn: PObject
	userdata: PUserData

	init: func(args: ...) {
		arr := ArrayList<Char> new()
		for(i in 0..12) {
			arr add(Random randInt(0, 75) as Char + '0')
		}
		_id = arr join()
	}

	/*toString: func -> String {
		obj := send("toString")

		if(obj == null)
			return qid()

		data := obj userdata

		if(data == null) {
			return obj toString()
		} else {
			return data toString()
		}
	}*/

	id: func -> String { _id }
	type: func -> String { "poland:object" }

	send: func~objs(runtime: PRuntime, id: PUserData, args: ...) -> PObject {
		PCall fromObjects(runtime, this, id, args) send()
	}

	/*send: func~str_objs(runtime: PRuntime, id: String, args: ...) -> PObject {
		PCall fromObjects~str(runtime, this, id, args) send()
	}*/

	send: func~sym_objs(runtime: PRuntime, id: String, args: ...) -> PObject {
		PCall fromObjects~sym(runtime, this, id, args) send()
	}

	receive: func(call: PCall) -> PObject {
		//"receiving #{call msg id}" println()

		fn := metafn

		if(fn == null) {
			"hmm" println()
			iter := srcs iterator()
			(iter == null) toString() println()
			while(iter hasNext?()) {
				src := iter next()
				"grr" println()
				try {
					val := src receive(call)
					if(val != null)
						return val
				} catch(e: Exception) {}
				"rawr" println()
				(iter == null) toString() println()
			}

			"after" println()

			cell := this[call msg id]

			if(cell == null) {
				cell = call runtime Rnil
			}

			return cell
		} else {
			"huh" println()
			data := fn userdata

			if(data != null && data instanceOf?(PNativeFunction)) {
				"running native function" println()
				
				"foo" println()
				val := data as PNativeFunction activate(this, call)
				"bar" println()
				val
			} else {
				fn send(call runtime, "activate", call)
			}
		}
	}

	srcs := ArrayList<PObject> new()

	mimic!: func(src: PObject) -> PObject {
		srcs add(src)
		return this
	}

	mimic: func -> PObject {
		PObject new() mimic!(this)
	}

	cells := HashMap<String, PObject> new()
	operator [](name: String) -> PObject {
		if(cells contains?(name)) {
			return cells get(name)
		} else {
			for(src in srcs) {
				o := src[name]

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