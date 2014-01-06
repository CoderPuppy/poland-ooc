import Object, Call
import poland/userdata/UserData

PNativeFunction: abstract class extends PUserData {
	dup: func -> This { this }

	handle: abstract func(self: PObject, call: PCall, pass: Func(PCall) -> PObject) -> PObject

	activate: func(self: PObject, call: PCall) -> PObject {
		handle(self, call, |call|
			for(src in self srcs) {
				val: PObject

				try {
					val := src receive(call)
				} catch(e: Exception) {
					e print()
				}

				if(val != null)
					return val
			}

			raise("Can't pass on call: #{call}")
		)
	}
}