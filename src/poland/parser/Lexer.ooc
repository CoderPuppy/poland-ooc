import structs/ArrayList
import Token
import matching into P

PLexerMode: abstract class {
	process: abstract func(c: Char, lexer: PLexer) -> Bool
	enter: func(lexer: PLexer)
	leave: func(lexer: PLexer)
	dup: abstract func -> This
}

PLexerMultCharMode: abstract class extends PLexerMode {
	max := INT_MAX

	type: PTokenType
	data := ""

	init: func~name(=type, =max)
	init: func~name_any(=type)

	check: abstract func(c: Char, lexer: PLexer) -> Bool

	offset: Long
	line: Int
	column: Int

	process: func(c: Char, lexer: PLexer) -> Bool {
		if(check(c, lexer)) {
			data += c toString()

			if(data length() == max) {
				lexer leave()
			}

			return true
		} else {
			return false
		}
	}

	enter: func(lexer: PLexer) {
		offset = lexer offset
		line = lexer line
		column = lexer column
	}

	leave: func(lexer: PLexer) {
		lexer emit(PToken new(type, data, offset, line, column))
	}
}

PLexerMatcherMode: class extends PLexerMultCharMode {
	matcher: (P Matcher)

	init: func~name(=type, =matcher, =max)
	init: func~name_any(=type, =matcher)

	check: func(c: Char, lexer: PLexer) -> Bool { matcher check(c) }

	dup: func -> This { This new(type, matcher, max) }
}

PLexer: class {
	mode: PLexerMode
	modes := ArrayList<PLexerMode> new()

	offset := 0l
	line := 1
	column := 1

	init: func { init(true) }
	init: func~s(sugar: Bool) {
		if(sugar) {
			// '{'
			modes add(PLexerMatcherMode new(PTokenType openCurly, P char('{')))
			// '}'
			modes add(PLexerMatcherMode new(PTokenType closeCurly, P char('}')))
			// '['
			modes add(PLexerMatcherMode new(PTokenType openSquare, P char('[')))
			// ']'
		}

		modes add(PLexerMatcherMode new(PTokenType closeSquare, P char(']')))
		// ','
		modes add(PLexerMatcherMode new(PTokenType comma, P char(',')))
		// '/'
		modes add(PLexerMatcherMode new(PTokenType fwdSlash, P char('/')))
		// '\\'
		modes add(PLexerMatcherMode new(PTokenType backslash, P char('\\')))
		// '#'
		modes add(PLexerMatcherMode new(PTokenType lineCommentBegin, P char('#')))
		// '\n'
		modes add(PLexerMatcherMode new(PTokenType newline, P or(P char('\n'), P char('\r')), 1))
		// ('\t' | ' ')+
		modes add(PLexerMatcherMode new(PTokenType whitespace, P or(P char('\t'), P char(' '))))
		// '('
		modes add(PLexerMatcherMode new(PTokenType openParen, P char('('), 1))
		// ')'
		modes add(PLexerMatcherMode new(PTokenType closeParen, P char(')'), 1))
		// '"'
		modes add(PLexerMatcherMode new(PTokenType dquote, P char('"'), 1))
		// '\''
		modes add(PLexerMatcherMode new(PTokenType squote, P char('\''), 1))
		// '.'
		modes add(PLexerMatcherMode new(PTokenType reset, P char('.'), 1))

		nonId := P mor(
			P char('\''),
			P char('"'),
			P char('#'),
			P char('('),
			P char(')'),
			P char('\n'),
			P char('\r'),
			P char('\t'),
			P char(' '),
			P char('/'),
			P char('\\')
		)

		if(sugar)
			nonId add(P mor(
				P char('['),
				P char(']'),
				P char('{'),
				P char('}')
			))

		// '0'-'z' && !('"' || '\'')
		modes add(PLexerMatcherMode new(PTokenType id,
			/*P or(
				P or(
					P range('0', '9'),
					P range('A', 'z')
				),
				P mor(
					P char(':'),
					P char('='),
					P char('@')
				)
			)*/
			P not(nonId)
		))
	}

	leave: func {
		if(mode != null)
			mode leave(this)

		mode = null
	}

	process: func(c: Char) -> Bool {
		processed := true

		if(mode == null || !mode process(c, this)) {
			leave()

			processed = false

			for(modeClass in modes) {
				m := modeClass dup()
				mode = m
				m enter(this)
				if(m process(c, this)) {
					processed = true
					break
				} else {
					mode = null
				}
			}
		}
		
		offset += 1
		column += 1
		if(c == '\n' || c == '\r') {
			line += 1
			column = 1
		}

		return processed
	}

	done: func { leave() }

	handlers := ArrayList<Func(PToken)> new()

	registerHandler: func(h: Func(PToken)) {
		handlers add(h)
	}

	emit: func(tok: PToken) {
		handlers each(|h| h(tok))
	}

	/*tokens := ArrayList<PToken> new()

	emit: func(tok: PToken) {
		tokens add(tok)
	}*/
}