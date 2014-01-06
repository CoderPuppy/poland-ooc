import String, UserData, MsgSeq
import poland/runtime/[Call, Object, Runtime]
import structs/ArrayList

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