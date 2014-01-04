import structs/ArrayList

Matcher: abstract class {
	check: abstract func(c: Char) -> Bool
}

MNone: class extends Matcher {
	init: func
	check: func(c: Char) -> Bool { false }
}

MAll: class extends Matcher {
	init: func
	check: func(c: Char) -> Bool { true }
}

MRange: class extends Matcher {
	minChar, maxChar: Char

	init: func(=minChar, =maxChar)

	check: func(c: Char) -> Bool { c >= minChar && c <= maxChar }
}

MChar: class extends Matcher {
	matchChar: Char

	init: func(=matchChar)

	check: func(c: Char) -> Bool { c == matchChar }
}

MAnd: class extends Matcher {
	a, b: Matcher

	init: func(=a, =b)

	check: func(c: Char) -> Bool { a check(c) && b check(c) }
}

MOr: class extends Matcher {
	a, b: Matcher

	init: func(=a, =b)

	check: func(c: Char) -> Bool { a check(c) || b check(c) }
}

MNot: class extends Matcher {
	matcher: Matcher

	init: func(=matcher)

	check: func(c: Char) -> Bool { !matcher check(c) }
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

	check: func(c: Char) -> Bool {
		for(matcher in matchers) {
			if(matcher check(c))
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

	check: func(c: Char) -> Bool {
		for(matcher in matchers) {
			if(!matcher check(c))
				return false
		}

		return true
	}
}

not: func(matcher: Matcher) -> MNot { MNot new(matcher) }
or: func(a, b: Matcher) -> MOr { MOr new(a, b) }
range: func(min, max: Char) -> MRange { MRange new(min, max) }
char: func(c: Char) -> MChar { MChar new(c) }
and: func(a, b: Matcher) -> MAnd { MAnd new(a, b) }
all: func -> MAll { MAll new() }
mor: func(args: ...) -> MMOr { MMOr new(args) }
mand: func(args: ...) -> MMAnd { MMAnd new(args) }