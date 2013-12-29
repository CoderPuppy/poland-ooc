import Object, poland/userdata/[Msg, MsgSeq, UserData, Symbol, String]

PCall: class extends PUserData {
	seq: PMsgSeq
	msg: PMsg
	ground: PObject
	receiver: PObject

	init: func(=ground, =seq, =receiver, =msg)

	id: func -> String { "#{ground id()}-#{seq id()}-#{receiver id()}-#{msg id()}" }

	fromObjects: static func~sym(receiver: PObject, id: String, args: ...) -> This { fromObjects(receiver, PSymbol new(id), args) }
	fromObjects: static func~str(receiver: PObject, id: String, args: ...) -> This { fromObjects(receiver, PString new(id), args) }

	fromObjects: static func(receiver: PObject, id: PUserData, args: ...) -> This {
		ground := PObject new()
		msg := PMsg new(id)
		seq := PMsgSeq new(msg)
		return This new(ground, seq, receiver, msg)
	}

	send: func -> PObject { receiver receive(this) }
}