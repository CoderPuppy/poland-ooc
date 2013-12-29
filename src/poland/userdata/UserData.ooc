PUserData: abstract class {
	id: abstract func -> String
	qid: func -> String { "#{class name}:#{id()}" }
	toString: func -> String { qid() }
}