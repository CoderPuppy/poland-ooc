import poland/userdata/[MsgSeq, Msg, Symbol]
import structs/Stack

PShuffler: class {
	// a = b => =(a, b)
	// Foo bar = baz => Foo =(bar, baz)
	// foo = bar = baz => =(foo, =(bar, baz))
	assignment: static func(seq: PMsgSeq) -> PMsgSeq {
		newSeq := PMsgSeq new()

		stack := Stack<PMsgSeq> new()
		stack push(newSeq)

		for(msg in seq) {
			current := stack peek()

			newMsg := PMsg new(msg id)

			if(msg id instanceOf?(PSymbol) && msg id as PSymbol val == "=" && msg args size == 0) {
				// undo the last shuffle
				if(current size == 0) {
					stack pop()

					current = stack peek()

					current msgs reverse!()

					for((i, msg) in current) {
						if(msg id instanceOf?(PSymbol) && msg id as PSymbol val == "=" && msg args size == 2) {
							current msgs removeAt(i)

							if(msg args get(1) size > 0) {
								msg args get(1) msgs reverse!()

								for(arg in msg args get(1)) {
									current msgs add(i, arg)
									i += 1
								}
							}

							current msgs add(i, PMsg new(PSymbol new("=")))
							i += 1

							if(msg args get(0) size > 0) {
								msg args get(0) msgs reverse!()

								for(arg in msg args get(0)) {
									current msgs add(i, arg)
									i += 1
								}
							}

							break
						}
					}

					current msgs reverse!()
				}

				newMsg args add(PMsgSeq new(current msgs removeAt(current size - 1)))
				newMsg args add(PMsgSeq new())
				current add(newMsg)
				stack push(newMsg args get(1))
			} else if(msg id instanceOf?(PSymbol) && msg id as PSymbol val == "." && msg args size == 0) {
				while(stack size > 1) {
					stack pop()
				}

				stack peek() add(newMsg)
			} else {
				newMsg args = msg args map(|seq| assignment(seq))
				current add(newMsg)
			}
		}

		return newSeq
	}

	// Reduce multiple resets in a row down to just one
	multReset: static func(seq: PMsgSeq) -> PMsgSeq {
		newSeq := PMsgSeq new()

		lastWasReset := false

		for(msg in seq) {
			newMsg := PMsg new(msg id)

			if(msg id instanceOf?(PSymbol) && msg id as PSymbol val == "." && msg args size == 0) {
				if(!lastWasReset) {
					newSeq add(newMsg)
				}

				lastWasReset = true
			} else {
				newMsg args = msg args map(|seq| multReset(seq))
				newSeq add(newMsg)

				lastWasReset = false
			}
		}

		return newSeq
	}
}