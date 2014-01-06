import UserData
import text/EscapeSequence

PSymbol: class extends PUserData {
	val: String

	init: func(=val)

	toString: func -> String { ":'#{EscapeSequence escape(val)}'" }

	id: func -> String { ":#{val}" }
	type: func -> String { "poland:symbol" }

	dup: func -> This { This new(val) }
}