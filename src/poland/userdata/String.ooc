import UserData
import text/EscapeSequence

PString: class extends PUserData {
	val: String

	init: func(=val)

	toString: func -> String { "\"" + EscapeSequence escape(val) + "\"" }

	id: func -> String { "s#{val}" }
	type: func -> String { "poland:string" }

	dup: func -> This { This new(val) }
}