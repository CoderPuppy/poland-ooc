import UserData

PString: class extends PUserData {
	val: String

	init: func(=val)

	id: func -> String { "s#{val}" }
}