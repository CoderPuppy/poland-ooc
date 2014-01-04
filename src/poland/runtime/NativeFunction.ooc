import Object, Call
import poland/userdata/UserData

PNativeFunction: abstract class extends PUserData {
	handle: abstract func(self: PObject, call: PCall, pass: Func(PCall) -> PObject) -> PObject

	activate: func(self: PObject, call: PCall) -> PObject {
		handle(self, call, |call|
			//"pass called with: #{call}, #srcs: #{srcs size}" println()
			for(src in self srcs) {
				try {
					val := src receive(call)
					if(val != null)
						return val
				} catch(e: Exception) {
					//e print()
				}
			}

			raise("Can't pass on call: #{call}")
		)
	}
}