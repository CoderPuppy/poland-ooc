import structs/ArrayList
import Msg, UserData, poland/runtime/Object

PMsgSeq: class extends PUserData {
	msgs := ArrayList<PMsg> new()

	init: func(args: ...) {
		args each(|arg|
			match arg {
				case msg: PMsg => msgs add(msg)
			}
		)
	}

	add: func(msg: PMsg) { msgs add(msg) }

	id: func -> String { msgs map(|m| m id()) join(',') }

	run: func~gc(ground: PObject, current: PObject) -> PObject {
		for(msg in msgs) {
			current = msg send(ground, current)
		}
		return current
	}
	run: func~g(ground: PObject) -> PObject { run(ground, ground) }
}