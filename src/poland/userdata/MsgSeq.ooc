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

	add: func(msg: PMsg) { msgs add(msg) }
	iterator: func -> BackIterator<PMsg> { msgs iterator() }
	get: func(i: Int) -> PMsg { msgs get(i) }

	id: func -> String { msgs map(|m| m id()) join(',') }
	type: func -> String { "poland:msgseq" }

	run: func~gc(runtime: PRuntime, ground: PObject, current: PObject) -> PObject {
		for(msg in msgs) {
			if(msg id instanceOf?(PSymbol) && msg id as PSymbol val == "." && msg args size == 0) {
				current = ground
			} else {
				"sending msg: #{msg} to: #{current}" println()
				current = msg send(runtime, ground, current)
			}
		}
		return current
	}
	run: func~g(runtime: PRuntime, ground: PObject) -> PObject { run(runtime, ground, ground) }
}