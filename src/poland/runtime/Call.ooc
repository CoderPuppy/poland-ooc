import Object, Runtime
import poland/userdata/[Msg, MsgSeq, UserData, Symbol, String]

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
		ground := PObject new()
		msg := PMsg new(id)
		seq := PMsgSeq new(msg)
		return This new(runtime, ground, seq, receiver, msg)
	}

	send: func -> PObject {
		receiver receive(this)
	}
}