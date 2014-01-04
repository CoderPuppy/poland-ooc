import structs/ArrayList
import Token

Matcher: abstract class {
	check: abstract func(tok: PToken) -> Bool
}

MNone: class extends Matcher {
	init: func
	check: func(tok: PToken) -> Bool { false }
}

MAll: class extends Matcher {
	init: func
	check: func(tok: PToken) -> Bool { true }
}

MRange: class extends Matcher {
	minChar, maxChar: PToken

	init: func(=minChar, =maxChar)

	check: func(tok: PToken) -> Bool { tok >= minChar && tok <= maxChar }
}

MToken: class extends Matcher {
	matchToken: PToken

	init: func(=matchToken)

	check: func(tok: PToken) -> Bool { tok == matchToken }
}

MTokenType: class extends Matcher {
	matchType: PTokenType

	init: func(=matchType)

	check: func(tok: PToken) -> Bool { tok type == matchType }
}

MAnd: class extends Matcher {
	a, b: Matcher

	init: func(=a, =b)

	check: func(tok: PToken) -> Bool { a check(tok) && b check(tok) }
}

MOr: class extends Matcher {
	a, b: Matcher

	init: func(=a, =b)

	check: func(tok: PToken) -> Bool { a check(tok) || b check(tok) }
}

MNot: class extends Matcher {
	matcher: Matcher

	init: func(=matcher)

	check: func(tok: PToken) -> Bool { !matcher check(tok) }
}

MMOr: class extends Matcher {
	matchers := ArrayList<Matcher> new()

	init: func(args: ...) {
		args each(|arg|
			match arg {
				case matcher: Matcher => matchers add(matcher)
			}
		)
	}

	add: func(matcher: Matcher) {
		matchers add(matcher)
	}

	check: func(tok: PToken) -> Bool {
		for(matcher in matchers) {
			if(matcher check(tok))
				return true
		}

		return false
	}
}

MMAnd: class extends Matcher {
	matchers := ArrayList<Matcher> new()

	init: func(args: ...) {
		args each(|arg|
			match arg {
				case matcher: Matcher => matchers add(matcher)
			}
		)
	}

	add: func(matcher: Matcher) {
		matchers add(matcher)
	}

	check: func(tok: PToken) -> Bool {
		for(matcher in matchers) {
			if(!matcher check(tok))
				return false
		}

		return true
	}
}

not: func(matcher: Matcher) -> MNot { MNot new(matcher) }
or: func(a, b: Matcher) -> MOr { MOr new(a, b) }
range: func(min, max: PToken) -> MRange { MRange new(min, max) }
token: func(tok: PToken) -> MToken { MToken new(tok) }
type: func(type: PTokenType) -> MTokenType { MTokenType new(type) }
and: func(a, b: Matcher) -> MAnd { MAnd new(a, b) }
all: func -> MAll { MAll new() }
mor: func(args: ...) -> MMOr { MMOr new(args) }
mand: func(args: ...) -> MMAnd { MMAnd new(args) }