import structs/[ArrayList, HashMap]
import text/EscapeSequence
import math/Random

PUserData: abstract class {
	id: func -> String { "" }
	type: abstract func -> String
	qid: func -> String { "#{type()}:#{id()}" }
	toString: func -> String { qid() }

	dup: abstract func -> This

	// TODO: serialization
}

PMsgSeq: class extends PUserData {
	msgs := ArrayList<PMsg> new()

	size ::= msgs size

	init: func(args: ...) {
		args each(|arg|
			match arg {
				case msg: PMsg => msgs add(msg)
			}
		)
	}

	toString: func -> String { "{ " + msgs map(|msg| msg toString()) join(" ") + " }" }

	id: func -> String { msgs map(|m| m id()) join(',') }
	type: func -> String { "poland:msgseq" }
	dup: func -> This {
		seq := This new()

		for(msg in this) {
			seq add(msg)
		}

		seq
	}

	add: func(msg: PMsg) { msgs add(msg) }
	iterator: func -> BackIterator<PMsg> { msgs iterator() }
	get: func(i: Int) -> PMsg { msgs get(i) }

	run: func~gc(runtime: PRuntime, ground: PObject, current: PObject) -> PObject {
		for(msg in msgs) {
			if(msg id instanceOf?(PSymbol) && msg id as PSymbol val == "." && msg args size == 0) {
				current = ground
			} else {
				current = msg send(runtime, ground, current)
			}
		}
		return current
	}
	run: func~g(runtime: PRuntime, ground: PObject) -> PObject { run(runtime, ground, ground) }
}

PMsg: class extends PUserData {
	id: PUserData
	args := ArrayList<PMsgSeq> new()

	init: func~args(=id, =args)
	init: func(=id)

	toString: func -> String { id toString() + "(" + args map(|seq| seq toString()) join(", ") + ")" }

	id: func -> String { id id() + "(" + args map(|s| s id()) join(',') + ")" }
	type: func -> String { "poland:msg" }
	dup: func -> This { This new(id dup(), args map(|seq| seq dup()) as ArrayList<PMsgSeq>) }

	callFor: func~grs(runtime: PRuntime, ground: PObject, receiver: PObject, seq: PMsgSeq) -> PCall {
		return PCall new(runtime, ground, seq, receiver, this)
	}
	callFor: func~gr(runtime: PRuntime, ground: PObject, receiver: PObject) -> PCall { callFor(runtime, ground, receiver, PMsgSeq new(this)) }
	callFor: func~gs(runtime: PRuntime, ground: PObject, seq: PMsgSeq) -> PCall { callFor(runtime, ground, ground, seq) }
	callFor: func~g(runtime: PRuntime, ground: PObject) -> PCall { callFor(runtime, ground, ground, PMsgSeq new(this)) }

	send: func~grs(runtime: PRuntime, ground: PObject, receiver: PObject, seq: PMsgSeq) -> PObject {
		callFor(runtime, ground, receiver, seq) send()
	}
	send: func~gr(runtime: PRuntime, ground: PObject, receiver: PObject) -> PObject { send(runtime, ground, receiver, PMsgSeq new(this)) }
	send: func~gs(runtime: PRuntime, ground: PObject, seq: PMsgSeq) -> PObject { send(runtime, ground, ground, seq) }
	send: func~g(runtime: PRuntime, ground: PObject) -> PObject { send(runtime, ground, ground, PMsgSeq new(this)) }
}

PString: class extends PUserData {
	val: String

	init: func(=val)

	toString: func -> String { "\"" + EscapeSequence escape(val) + "\"" }

	id: func -> String { "s#{val}" }
	type: func -> String { "poland:string" }

	dup: func -> This { This new(val) }
}

PSymbol: class extends PUserData {
	val: String

	init: func(=val)

	toString: func -> String { ":'#{EscapeSequence escape(val)}'" }

	id: func -> String { ":#{val}" }
	type: func -> String { "poland:symbol" }

	dup: func -> This { This new(val) }
}

PNativeFunction: abstract class extends PUserData {
	dup: func -> This { this }

	handle: abstract func(self: PObject, call: PCall, pass: Func(PCall) -> PObject) -> PObject

	activate: func(self: PObject, call: PCall) -> PObject {
		handle(self, call, |call|
			for(src in self srcs) {
				val: PObject

				try {
					val := src receive(call)
				} catch(e: Exception) {
					e print()
				}

				if(val != null)
					return val
			}

			raise("Can't pass on call: #{call}")
		)
	}
}

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

PRuntime: class {
	ROrigin, RDefaultBehavior, RKind, RSomething, RUserData, RNativeFunction, RString, RSymbol, RNumber, RGround, Rnil: PObject

	init: func {
		ROrigin = PObject new(this)

		Rnil = ROrigin mimic()

		RDefaultBehavior = ROrigin mimic()

		{
			RNativeFunction = PObject new(this)
			proto := RDefaultBehavior mimic()
			RNativeFunction[PSymbol new("prototype")] = proto
		}

		{
			RKind = PObject new(this)
			proto := RDefaultBehavior mimic()
			RKind[PSymbol new("prototype")] = proto 
			RKind mimic!(proto)

			proto[PSymbol new("extend")] = createNativeFunction(KindProtoExtendFunc new())
			proto[PSymbol new("extend!")] = createNativeFunction(KindProtoExtendBangFunc new())
			proto[PSymbol new("new")] = createNativeFunction(KindProtoNewFunc new())
			proto[PSymbol new("alloc")] = createNativeFunction(KindProtoAllocFunc new())
			proto[PSymbol new("initialize")] = createNativeFunction(KindProtoInitializeFunc new())

			"foo = %p" printfln(RKind[PSymbol new("extend!")])
		}

		{
			RSomething = RKind send("new")
			proto := RSomething[PSymbol new("prototype")]
			proto[PSymbol new("initialize")] = createNativeFunction(NOOPFunc new())
			RKind send("extend!", RSomething)
		}

		RGround = RSomething send("extend")
	}

	createNativeFunction: func(fn: PNativeFunction) -> PObject {
		obj: PObject

		if(RNativeFunction[PSymbol new("new")] == Rnil)
			obj = RNativeFunction[PSymbol new("prototype")] mimic()
		else
			obj = RNativeFunction send("alloc")

		obj userdata = fn

		obj
	}

	createSymbol: func(sym: PSymbol) -> PObject {
		obj := RSymbol send("alloc")

		obj userdata = sym

		obj
	}

	createString: func(str: PString) -> PObject {
		obj := RString send("alloc")

		obj userdata = str

		obj
	}
}

NOOPFunc: class extends PNativeFunction {
	init: func

	handle: func(self: PObject, call: PCall, pass: Func(PCall) -> PObject) -> PObject {
		return self runtime Rnil
	}

	type: func -> String { "poland:natfn-noop" }
}

KindProtoAllocFunc: class extends PNativeFunction {
	init: func

	handle: func(self: PObject, call: PCall, pass: Func(PCall) -> PObject) -> PObject {
		proto := self[PSymbol new("prototype")]

		if(proto == self runtime Rnil) {
			raise("this kind doesn't have a prototype")
		}

		return proto mimic()
	}

	type: func -> String { "poland:natfn-kind/proto/alloc" }
}

KindProtoNewFunc: class extends PNativeFunction {
	init: func

	handle: func(self: PObject, call: PCall, pass: Func(PCall) -> PObject) -> PObject {
		obj := call receiver send("alloc")

		icall := call dup()
		icall msg id = PSymbol new("initialize")
		icall receiver = obj
		icall send()

		return obj
	}

	type: func -> String { "poland:natfn-kind/proto/new" }
}

KindProtoInitializeFunc: class extends PNativeFunction {
	init: func

	handle: func(self: PObject, call: PCall, pass: Func(PCall) -> PObject) -> PObject {
		receiver := call receiver

		receiver[PSymbol new("prototype")] = PObject new(self runtime)

		for(i in 0..call msg args size) {
			receiver send("extend!", call evalArg(i))
		}

		return self runtime Rnil
	}

	type: func -> String { "poland:natfn-kind/proto/initialize" }
}

KindProtoExtendFunc: class extends PNativeFunction {
	init: func

	handle: func(self: PObject, call: PCall, pass: Func(PCall) -> PObject) -> PObject {
		cla := self runtime RKind send("new", call receiver)

		return cla
	}

	type: func -> String { "poland:natfn-kind/proto/extend" }
}

KindProtoExtendBangFunc: class extends PNativeFunction {
	init: func

	handle: func(self: PObject, call: PCall, pass: Func(PCall) -> PObject) -> PObject {
		receiver := call receiver

		if(call msg args size < 1) {
			raise("that's not enough arguments for extend!")
		}

		cla := call evalArg(0)

		receiver mimic!(cla)
		receiver[PSymbol new("prototype")] mimic!(cla[PSymbol new("prototype")])

		return receiver
	}

	type: func -> String { "poland:natfn-kind/proto/extend!" }
}

BaseReceiveFunc: class extends PNativeFunction {
	init: func

	handle: func(self: PObject, call: PCall, pass: Func(PCall) -> PObject) -> PObject {
		cell := self[call msg id]

		if(cell == self runtime Rnil) {
			raise("#{self} doesn't know how to handle #{call msg}")
			//cell = self runtime Rnil
		}

		if(cell userdata != null && cell userdata instanceOf?(PNativeFunction)) {
			cell = cell userdata as PNativeFunction activate(self, call)
		}

		return cell
	}

	type: func -> String { "poland:natfn-base/receive" }
}

GroundReceiveFunc: class extends PNativeFunction {
	init: func

	handle: func(self: PObject, call: PCall, pass: Func(PCall) -> PObject) -> PObject {
		msg := call msg
		id := msg id

		if(id instanceOf?(PSymbol) && id as PSymbol val[0] == ':') {
			return self runtime createSymbol(PSymbol new(id as PSymbol val substring(1)))
		} else if(id instanceOf?(PString)) {
			return self runtime createString(id as PString)
		} else {
			return pass(call)
		}
	}

	type: func -> String { "poland:natfn-ground/receive" }
}

SetFunc: class extends PNativeFunction {
	init: func

	handle: func(self: PObject, call: PCall, super: Func(PCall) -> PObject) -> PObject {
		msg := call msg

		if(msg args size < 2) {
			raise("Set needs two arguments, got: #{msg args size}")
		}

		keySeq := msg args get(0)

		if(keySeq size < 1) {
			raise("The first argument can't be empty")
		}

		key := keySeq get(0) id

		if(!key instanceOf?(PSymbol)) {
			raise("You can't set #{key type()}")
		}

		valSeq := msg args get(1)

		if(valSeq size < 1) {
			raise("The second argument can't be empty")
		}

		call receiver[key] = valSeq run(self runtime, call ground)

		return null
	}

	type: func -> String { "poland:natfn-defbehav/set" }
}

PCall: class extends PUserData {
	runtime: PRuntime
	seq: PMsgSeq
	msg: PMsg
	ground: PObject
	receiver: PObject

	init: func(=runtime, =ground, =seq, =receiver, =msg)

	id: func -> String { "#{ground id()}-#{seq id()}-#{receiver id()}-#{msg id()}" }
	type: func -> String { "poland:call" }

	toString: func -> String { "#{msg} -> #{receiver}" }

	fromObjects: static func~sym(runtime: PRuntime, receiver: PObject, id: String, args: ...) -> This { fromObjects(runtime, receiver, PSymbol new(id), args) }
	//fromObjects: static func~str(runtime: PRuntime, receiver: PObject, id: String, args: ...) -> This { fromObjects(runtime, receiver, PString new(id), args) }

	fromObjects: static func(runtime: PRuntime, receiver: PObject, id: PUserData, args: ...) -> This {
		ground := PObject new(runtime)
		msg := PMsg new(id)
		seq := PMsgSeq new(msg)

		i := 1
		args each(|arg|
			match arg {
				case obj: PObject => {
					sym := PSymbol new(i toString())
					msg args add(PMsgSeq new(PMsg new(sym)))
					ground[sym] = obj
					i += 1
				}
			}
		)

		return This new(runtime, ground, seq, receiver, msg)
	}

	send: func -> PObject {
		receiver receive(this)
	}

	dup: func -> This {
		nmsg := msg dup()

		This new(runtime, ground, PMsgSeq new(nmsg), receiver, nmsg)
	}

	evalArg: func(i: Int) -> PObject {
		return msg args get(i) run(runtime, ground)
	}
}

runtime := PRuntime new()

ground := runtime RGround send("new")