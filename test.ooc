use poland
import poland/runtime/[Object, Call, Runtime]
import poland/userdata/[Symbol, String, Msg, MsgSeq]
import poland/parser/[Parser, Lexer, Token, Shuffler]
import io/File
import text/EscapeSequence

lexer := PLexer new()
parser := PParser new()

//lexer registerHandler(|t| t toString() println())
lexer registerHandler(|t|
	//"Parser is in mode: #{parser mode name()} for token: #{t}, line: #{t line}, column: #{t column}" println()

	if(!parser process(t)) {
		"Bad! The parser can't process this token: '#{t}' in mode: #{parser mode name()}" println()
	}
)

//str := "'test' 4789897*^*&%&^"

//file := File new("./poland/runtime.pd")
file := File new("./examples/test.pd")

str := file read()

for((i, c) in str) {
	//"Processing: #{c toString()}" println()
	if(!lexer process(c)) {
		"Bad! The lexer can't process this character! '#{EscapeSequence escape(c toString())}' at character #{i}" println()
	}
}
lexer done()
parser done()

seq := PShuffler assignment(PShuffler multReset(parser seq))

seq toString() println()

runtime := PRuntime new()

ground := runtime RGround send("new")

seq run(runtime, ground) toString() println()

(ground[PSymbol new("foo")] == runtime Rnil) toString() println()