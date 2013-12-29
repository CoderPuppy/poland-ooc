import Token
import poland/userdata/[Msg, MsgSeq, String, Symbol]

PParser: class {
	ast: PMsgSeq

	init: func {
		ast = PMsgSeq new()
	}

	handle: func(tok: PToken) {
		
	}
}