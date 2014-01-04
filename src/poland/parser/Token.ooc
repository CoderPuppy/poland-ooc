import text/EscapeSequence

PTokenType: enum {
	id,
	comma,
	fwdSlash,
	backslash,
	lineCommentBegin,
	newline,
	whitespace,
	openParen,
	closeParen,
	dquote,
	squote,
	reset,
	
	openCurly,
	closeCurly,
	openSquare,
	closeSquare

	toString: func -> String {
		match this {
			case id => "id"
			case comma => "comma"
			case fwdSlash => "fwd_slash"
			case backslash => "backslash"
			case lineCommentBegin => "line_comment_begin"
			case newline => "newline"
			case whitespace => "whitespace"
			case openParen => "open_paren"
			case closeParen => "close_paren"
			case dquote => "dquote"
			case squote => "squote"
			case reset => "reset"

			// SUGAR
			case openCurly => "open_curly"
			case closeCurly => "close_curly"

			case openSquare => "open_square"
			case closeSquare => "close_square"
		}
	}
}

PToken: class {
	type: PTokenType
	text: String
	
	offset: Long
	line: Int
	column: Int

	init: func(=type, =text, =offset, =line, =column)

	toString: func -> String { "#{type toString()}:\"#{EscapeSequence escape(text)}\"" }
}