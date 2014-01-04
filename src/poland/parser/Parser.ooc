import Token
import poland/userdata/[Msg, MsgSeq, String, Symbol]
import structs/[Stack, ArrayList]
import tokenMatching into M

PParser: class {
	seq: PMsgSeq
	stack := Stack<PParserMode> new()

	mode ::= stack peek()

	init: func {
		seq = PMsgSeq new()
		enter(PParserBodyMode new(seq))
	}

	enter: func(newMode: PParserMode) {
		//"entering mode: #{newMode}" println()

		oldMode: PParserMode
		oldMode = stack empty?() ? null : stack peek()

		stack push(newMode)

		if(oldMode != null) {
			if(oldMode enterChild(newMode, this)) {
				mode enter(this)
			} else {
				stack pop()
			}
		} else {
			mode enter(this)	
		}
	}

	leave: func {
		if(!stack empty?()) {
			oldMode := stack pop()

			//"leaving mode: #{oldMode}" println()

			oldMode leave(this)

			if(!stack empty?()) {
				mode leaveChild(oldMode, this)
			}
		}
	}

	process: func(tok: PToken) -> Bool { mode process(tok, this) }

	done: func {
		while(!stack empty?()) {
			leave()
		}
	}
}

PParserMode: abstract class {
	name: abstract func -> String
	process: abstract func(tok: PToken, parser: PParser) -> Bool
	enter: func(parser: PParser)
	leave: func(parser: PParser)
	enterChild: func(child: PParserMode, parser: PParser) -> Bool { true }
	leaveChild: func(child: PParserMode, parser: PParser)

	toString: func -> String { name() }
}

PParserBodyMode: class extends PParserMode {
	name: func -> String { "body" }

	seq: PMsgSeq
	stopOn: (M Matcher)
	init: func(=seq, =stopOn)
	init: func~seq(=seq)

	lastWasSlash := false
	msgPossible := true

	process: func(tok: PToken, parser: PParser) -> Bool {
		if(stopOn != null && stopOn check(tok)) {
			parser leave()
			return parser process(tok)
		}

		match(tok type) {
			case PTokenType id =>
				if(msgPossible) {
					parser enter(PParserMsgMode new(PMsg new(PSymbol new(tok text))))
				} else {
					raise("expected: whitespace, got: id, at line #{tok line}, column #{tok column}")
				}
				msgPossible = false

			case PTokenType whitespace =>
				msgPossible = true

			case PTokenType newline =>
				seq add(PMsg new(PSymbol new(".")))
				msgPossible = true

			case PTokenType reset =>
				if(msgPossible) {
					parser enter(PParserMsgMode new(PMsg new(PSymbol new("."))))
				} else {
					seq add(PMsg new(PSymbol new(".")))
					msgPossible = true
				}

			case PTokenType openParen =>
				parser enter(PParserMsgMode new(PMsg new(PSymbol new("apply")), false))
				return parser process(tok)

			case PTokenType lineCommentBegin =>
				if(lastWasSlash) {
					lastWasSlash = false

					parser enter(PParserBlockCommentMode new())
				} else {
					parser enter(PParserLineCommentMode new())
				}

			case PTokenType fwdSlash =>
				// TODO: backtracking
				lastWasSlash = true

			case PTokenType dquote =>
				parser enter(PParserStringMode new(PTokenType dquote))

			case PTokenType squote =>
				parser enter(PParserStringMode new(PTokenType squote))

			case PTokenType openSquare =>
				parser enter(PParserWrapperMode new(PTokenType closeSquare, "[]"))

			case PTokenType openCurly =>
				parser enter(PParserWrapperMode new(PTokenType closeCurly, "{}"))

			case =>
				parser leave()
				return parser process(tok)
		}

		if(lastWasSlash && tok type != PTokenType fwdSlash) {
			raise("unexpected fwdslash at line #{tok line} column #{tok column}")
		}

		return true
	}

	enterChild: func(child: PParserMode, parser: PParser) -> Bool {
		match child {
			case mode: PParserMsgMode =>
				if(msgPossible) {
					seq add(mode msg)
				} else {
					return false
				}
		}

		return true
	}

	leaveChild: func(child: PParserMode, parser: PParser) {
		match child {
			case mode: PParserStringMode =>
				parser enter(PParserMsgMode new(PMsg new(PString new(mode str))))
		}
	}
}

PParserMsgMode: class extends PParserMode {
	name: func -> String { "msg" }

	msg: PMsg
	init: func~inName(=msg)
	init: func(=msg, =inName)

	inName := true
	inArgs := false
	lastWasSlash := false

	process: func(tok: PToken, parser: PParser) -> Bool {
		match(tok type) {
			case PTokenType id =>
				if(inName && msg id instanceOf?(PSymbol)) {
					msg id as PSymbol val += tok text
				}

			case PTokenType whitespace =>
				if(!inArgs) {
					parser leave()
					return parser process(tok)
				} else
					inName = false

			case PTokenType newline =>
				if(!inArgs) {
					parser leave()
					return parser process(tok)
				}

			case PTokenType lineCommentBegin =>
				if(inArgs) {
					if(lastWasSlash) {
						lastWasSlash = false
						parser enter(PParserBlockCommentMode new())
					} else {
						parser enter(PParserLineCommentMode new())
					}
				} else {
					parser leave()

					good := true

					if(lastWasSlash) {
						lastWasSlash = false
						good = good && parser process(PToken new(PTokenType fwdSlash, "/", tok offset - 1, tok line, tok column - 1))
					}

					if(good)
						return parser process(tok)
					else
						return false
				}

			case PTokenType fwdSlash =>
				lastWasSlash = true

			case PTokenType openParen =>
				inArgs = true
				parser enter(PParserListMode new(msg args, M type(PTokenType closeParen)))

			case PTokenType closeParen =>
				parser leave()
				if(!inArgs) {
					return parser process(tok)
				}

			case =>
				parser leave()
				return parser process(tok)
		}

		return true
	}

	enter: func(parser: PParser) {
		if(msg id instanceOf?(PString)) {
			inName = false
		}
	}
}

PParserLineCommentMode: class extends PParserMode {
	name: func -> String { "line_comment" }

	init: func

	process: func(tok: PToken, parser: PParser) -> Bool {
		match(tok type) {
			case PTokenType newline => parser leave()
		}

		return true
	}
}

PParserBlockCommentMode: class extends PParserMode {
	name: func -> String { "block_comment" }

	init: func

	lastWasComment := false

	process: func(tok: PToken, parser: PParser) -> Bool {
		match(tok type) {
			case PTokenType lineCommentBegin =>
				lastWasComment = true

			case PTokenType fwdSlash =>
				if(lastWasComment) {
					parser leave()
				}
		}

		return true
	}
}

PParserListMode: class extends PParserMode {
	name: func -> String { "list" }

	list: ArrayList<PMsgSeq>
	stopOn: (M Matcher)

	init: func(=list, =stopOn)
	init: func~list(=list)
	init: func~default { init(ArrayList<PMsgSeq> new()) }
	init: func~stopOn(=stopOn) { init() }

	process: func(tok: PToken, parser: PParser) -> Bool {
		if(stopOn != null && stopOn check(tok)) {
			parser leave()
			return parser process(tok)
		}

		match(tok type) {
			case PTokenType whitespace =>
			case PTokenType comma =>
				seq := PMsgSeq new()
				list add(seq)
				parser enter(PParserBodyMode new(seq, M or(stopOn, M type(PTokenType comma))))

			case =>
				if(list size == 0) {
					seq := PMsgSeq new()
					list add(seq)
					parser enter(PParserBodyMode new(seq, M or(stopOn, M type(PTokenType comma))))
					return parser process(tok)
				} else {
					raise("expected: comma, got: #{tok type}")
				}
		}

		return true
	}
}

PParserStringMode: class extends PParserMode {
	name: func -> String { "string" }

	type: PTokenType

	init: func(=type)

	str := ""

	process: func(tok: PToken, parser: PParser) -> Bool {
		match(tok type) {
			case type =>
				parser leave()

			case =>
				str += tok text
		}

		return true
	}
}

PParserWrapperMode: class extends PParserMode {
	name: func -> String { "wrapper" }

	close: PTokenType
	id: String
	init: func(=close, =id) {
		msg = PMsg new(PSymbol new(id))
		args = msg args
	}

	first := true

	msg: PMsg
	args: ArrayList<PMsgSeq>

	process: func(tok: PToken, parser: PParser) -> Bool {
		match(tok type) {
			case close =>
				if(first) {
					// TODO: this is very specific to being used in a body
					parser leave()
					parser enter(PParserMsgMode new(msg))
				}

			case =>
				parser enter(PParserListMode new(args, M type(close)))
				return parser process(tok)
		}

		first = false

		return true
	}
}