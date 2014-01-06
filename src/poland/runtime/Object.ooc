import structs/[HashMap, ArrayList]
import math/Random
import Call, NativeFunction, Runtime
import poland/userdata/[UserData, Symbol, Msg]

PObject: class extends PUserData {
	_id: String

	metafn: PObject
	userdata: PUserData

	runtime: PRuntime
	init: func(=runtime) {
		arr := ArrayList<Char> new()
		for(i in 0..12) {
			arr add(Random randInt(0, 75) as Char + '0')
		}
		_id = arr join()
	}

	id: func -> String { _id }
	type: func -> String { "poland:object" }
	dup: func -> This {
		obj := This new(runtime)

		obj _id = _id // todo: maybe?

		for((k, v) in cells) {
			obj cells[k] = v dup()
		}

		if(metafn != null) {
			obj metafn = metafn dup()
		}

		obj
	}

	send: func~objs(id: PUserData, args: ...) -> PObject {
		PCall fromObjects(runtime, this, id, args) send()
	}

	/*send: func~str_objs(runtime: PRuntime, id: String, args: ...) -> PObject {
		PCall fromObjects~str(runtime, this, id, args) send()
	}*/

	send: func~sym_objs(id: String, args: ...) -> PObject {
		PCall fromObjects~sym(runtime, this, id, args) send()
	}

	/*send: func~sym_blank(id: String) -> PObject {
		PCall fromObjects~sym_blank(runtime, this, id) send()
	}*/

	receive: func(call: PCall) -> PObject {
		fn := metafn

		call toString() println()

		if(call runtime != runtime) {
			raise("that call is from the wrong runtime")
		}

		if(fn == null) {
			return BaseReceiveFunc new() activate(this, call)
		} else {
			data := fn userdata

			if(data != null && data instanceOf?(PNativeFunction)) {
				data as PNativeFunction activate(this, call)
			} else {
				fn send("activate", call)
			}
		}
	}

	srcs := ArrayList<PObject> new()

	mimic!: func(src: PObject) -> PObject {
		srcs add(src)
		return this
	}

	mimic: func -> PObject {
		PObject new(runtime) mimic!(this)
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

			return runtime Rnil
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