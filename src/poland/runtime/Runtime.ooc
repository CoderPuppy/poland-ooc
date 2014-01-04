import Object, NativeFunction, Call
import poland/userdata/[Symbol, Msg, String]

PRuntime: class {
	RBase, RSomething, Rnil, RNativeFunction, RSymbol, RString, RUserData: PObject

	init: func {
		RBase = PObject new()
		RSomething = RBase mimic()
		Rnil = RBase mimic()
		RUserData = RSomething mimic()
		RNativeFunction = RUserData mimic()
		RString = RUserData mimic()
		RSymbol = RUserData mimic()

		RBase metafn = createFunction(BaseReceiveFunc new(this))
	}

	createFunction: func(fn: PNativeFunction) -> PObject {
		//"hmm" println()
		obj := RNativeFunction send(this, "new")
		//obj := 
		//"blah" println()

		obj userdata = fn

		obj
	}

	createSymbol: func(sym: PSymbol) -> PObject {
		obj := RSymbol send(this, "new")

		obj userdata = sym

		obj
	}

	createString: func(str: PString) -> PObject {
		//obj := RString send(this, "new")
		obj := RBase mimic()

		obj userdata = str

		obj
	}

	createGround: func -> PObject {
		//ground := RSomething send("new")
		ground := RBase mimic()

		ground[PSymbol new("nil")] = Rnil

		ground[PSymbol new("=")] = createFunction(SetFunc new(this))

		ground metafn = createFunction(GroundReceiveFunc new(this))

		ground
	}
}

BaseReceiveFunc: class extends PNativeFunction {
	runtime: PRuntime
	init: func(=runtime)

	handle: func(self: PObject, call: PCall, pass: Func(PCall) -> PObject) -> PObject {
		"base receive: #{call msg}" println()

		cell := self[call msg id]

		if(cell == null) {
			raise("#{self} doesn't know how to handle #{call msg}")
			//cell = call runtime Rnil
		}

		if(cell userdata == this) {
			/*"wat? #{call}, cell: #{cell}, ground: #{call ground}, receiver: #{call receiver}, this: #{self}" println()
			e := Exception new(this class, "blah")
			e addBacktrace()
			e printBacktrace()*/
		}

		if(cell userdata != null && cell userdata instanceOf?(PNativeFunction)) {
			cell = cell userdata as PNativeFunction activate(self, call)
		}

		return cell
	}

	type: func -> String { "poland:natfn-base/receive" }
}

GroundReceiveFunc: class extends PNativeFunction {
	runtime: PRuntime
	init: func(=runtime)

	handle: func(self: PObject, call: PCall, pass: Func(PCall) -> PObject) -> PObject {
		msg := call msg
		id := msg id

		"ground receiving message: #{call msg}" println()

		if(id instanceOf?(PSymbol) && id as PSymbol val[0] == ':') {
			return runtime createSymbol(PSymbol new(id as PSymbol val substring(1)))
		} else if(id instanceOf?(PString)) {
			return runtime createString(id as PString)
		} else {
			return pass(call)
		}
	}

	type: func -> String { "poland:natfn-ground/receive" }
}

SetFunc: class extends PNativeFunction {
	runtime: PRuntime
	init: func(=runtime)

	handle: func(self: PObject, call: PCall, super: Func(PCall) -> PObject) -> PObject {
		"set func" println()

		msg := call msg

		if(msg args size < 2) {
			raise("Set needs two arguments")
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

		key toString() println()

		call receiver[key] = valSeq run(call runtime, call ground)

		"hmm: #{call receiver[key] == null}" println()

		return null
	}

	type: func -> String { "poland:natfn-set" }
}