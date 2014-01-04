import UserData
import text/EscapeSequence

PSymbol: class extends PUserData {
	val: String

	toString: func -> String { ":'#{EscapeSequence escape(val)}'" }

	id: func -> String { ":#{val}" }
	type: func -> String { "poland:symbol" }

	init: func(=val)
}