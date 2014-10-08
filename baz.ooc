import foo, bar

PCall: class extends PUserData {
	fromObjects: static func(args: ...) -> This {
		args each(|arg|
			match arg {
				case obj: PObject =>
			}
		)

		null
	}
}