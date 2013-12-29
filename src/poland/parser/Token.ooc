import text/EscapeSequence

PToken: class {
	name: String
	text: String

	init: func(=name, =text)

	toString: func -> String { "#{name}:\"#{EscapeSequence escape(text)}\"" }
}