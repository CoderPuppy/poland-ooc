PUserData: abstract class {
	id: func -> String { "" }
	type: abstract func -> String
	qid: func -> String { "#{type()}:#{id()}" }
	toString: func -> String { qid() }

	// TODO: serialization
}