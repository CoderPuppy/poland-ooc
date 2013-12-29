import UserData

PSymbol: class extends PUserData {
	val: String

	id: func -> String { ":#{val}" }

	init: func(=val)
}