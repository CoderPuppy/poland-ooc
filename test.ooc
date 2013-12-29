use poland
import poland/runtime/[Object, Call]
import poland/userdata/[Symbol, String, Msg, MsgSeq]
import poland/parser/[Parser, Lexer]

lexer := PLexer new()

str := "10"
for(c in str) {
	if(!lexer process(c)) {
		"Bad! The lexer can't process this character!" println()
	}
}

lexer tokens each(|t| t toString() println())

//parser := PParser new()

ground := PObject new()