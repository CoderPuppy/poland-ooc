import structs/ArrayList
import Msg, UserData, Symbol
import poland/runtime/[Object, Runtime]

PMsgSeq: class extends PUserData {
	msgs := ArrayList<PMsg> new()

	size ::= msgs size

	init: func(args: ...) {
		args each(|arg|
			match arg {
				case msg: PMsg => msgs add(msg)
			}
		)
	}

	toString: func -> String { "{ " + msgs map(|msg| msg toString()) join(" ") + " }" }

	id: func -> String { msgs map(|m| m id()) join(',') }
	type: func -> String { "poland:msgseq" }
	dup: func -> This {
		seq := This new()

		for(msg in this) {
			seq add(msg)
		}

		seq
	}

	add: func(msg: PMsg) { msgs add(msg) }
	iterator: func -> BackIterator<PMsg> { msgs iterator() }
	get: func(i: Int) -> PMsg { msgs get(i) }

	run: func~gc(runtime: PRuntime, ground: PObject, current: PObject) -> PObject {
		for(msg in msgs) {
			if(msg id instanceOf?(PSymbol) && msg id as PSymbol val == "." && msg args size == 0) {
				current = ground
			} else {
				current = msg send(runtime, ground, current)
			}
		}
		return current
	}
	run: func~g(runtime: PRuntime, ground: PObject) -> PObject { run(runtime, ground, ground) }
}