import UserData
import text/EscapeSequence

PString: class extends PUserData {
	val: String

	toString: func -> String { "\"" + EscapeSequence escape(val) + "\"" }

	init: func(=val)

	id: func -> String { "s#{val}" }
	type: func -> String { "poland:string" }
}