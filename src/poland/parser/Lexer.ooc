import structs/ArrayList
import Token

PLexerMode: abstract class {
	process: abstract func(c: Char, lexer: PLexer) -> Bool
	dup: abstract func -> This
}

PLexerMultCharMode: abstract class extends PLexerMode {
	maxChars: Int

	data: String

	init: func(=maxChars) {
		data = ""
	}
	init: func~any { init(INT_MAX) }

	check: abstract func(c: Char, lexer: PLexer) -> Bool

	process: func(c: Char, lexer: PLexer) {
		data += c toString()

		len := data length()

		if(len == maxChars) {
			lexer emit(PToken new(data, data))
			lexer mode = null
		}
	}
}

PLexerAnyCharMode: class extends PLexerMultCharMode {
	init: func(=maxChars)
	init: func~any

	check: func(c: Char, lexer: PLexer) -> Bool { true }
	dup: func -> This { This new(maxChars) }
}

PLexer: class {
	/*
	
	*/

	mode: PLexerMode
	modes := ArrayList<PLexerMode> new()

	init: func~mode(=mode) {
		init()
	}
	init: func {
		modes add(PLexerAnyCharMode new(1))
	}

	process: func(c: Char) -> Bool {
		if(mode != null && mode process(c, this)) {
			return true
		} else {
			for(modeClass in modes) {
				m := modeClass dup()
				if(m process(c, this)) {
					mode = m
					return true
				}
			}
		}

		return false
	}

	dup: func -> This { This new(mode) }

	tokens := ArrayList<PToken> new()

	emit: func(token: PToken) {
		tokens add(token)
	}
}