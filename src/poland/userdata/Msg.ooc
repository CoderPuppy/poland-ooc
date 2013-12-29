import String, UserData, MsgSeq, poland/runtime/[Call, Object]
import structs/ArrayList

PMsg: class extends PUserData {
	id: PUserData
	args := ArrayList<PMsgSeq> new()

	id: func -> String { id id() + "(" + args map(|s| s id()) join(',') + ")" }

	init: func~args(=id, =args)
	init: func(=id)

	callFor: func~grs(ground: PObject, receiver: PObject, seq: PMsgSeq) -> PCall {
		return PCall new(ground, seq, receiver, this)
	}
	callFor: func~gr(ground: PObject, receiver: PObject) -> PCall { callFor(ground, receiver, PMsgSeq new(this)) }
	callFor: func~gs(ground: PObject, seq: PMsgSeq) -> PCall { callFor(ground, ground, seq) }
	callFor: func~g(ground: PObject) -> PCall { callFor(ground, ground, PMsgSeq new(this)) }

	send: func~grs(ground: PObject, receiver: PObject, seq: PMsgSeq) -> PObject {
		callFor(ground, receiver, seq) send()
	}
	send: func~gr(ground: PObject, receiver: PObject) -> PObject { send(ground, receiver, PMsgSeq new(this)) }
	send: func~gs(ground: PObject, seq: PMsgSeq) -> PObject { send(ground, ground, seq) }
	send: func~g(ground: PObject) -> PObject { send(ground, ground, PMsgSeq new(this)) }
}