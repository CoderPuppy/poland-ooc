import Object, NativeFunction, Call
import poland/userdata/[Symbol, Msg, String]

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