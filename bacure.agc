// version 0.9 13 13 Mar 2022

/*

 Bacure - Little help for Basickness patients
 App Game Kit 2 Tier 1 language helper functions 
 by Leo Rela Leo.Rela@gmail.com

 Note: Function names beginning with "_" e.g. like _DoSomething are internal ones, don't use them directly

 Features:
	+ Boolean constants
	+ Low performance string key/value maps + wrappers for float and integers
	+ Low performance string value sets + wrappers for float and integers	
	+ Type guess/check for string content: int, float or str
	+ (De)serialize maps to/from CSV files
	+ Logging
	+ TGF Trivial Graph Format parser
	+ Simple XML parser (Partial support)
	+ Tiled (map editor) TMX file parser (Partial support, read TMX support specification* for more info)
	+ Stack for string values
	+ Generate UUIDs
	+ Yarn document parser
	+ DialogTree D3 support http://sol.gfxile.net/d3/ (**)

 *) Use Tiled 1.1.0 with following export settings:
	Format: .tmx
	Orientation: Orthogonal
	Tile layer format: CSV
	
	As Tiled is only partially supported so there are NO support for:
	  - External TSX tile set files
	  - Other tile layer data formats than CSV
	  - Embedded Tile data, tile content must be taken from Image file
	  - Wang sets
	  - Chunks

 **) D3 Studio 110808 ALPHA supported
	 Format: XML 

*/

// set TRUE only for development purposes. 
// Set FALSE before you publish app except if you want it to write logs
global GLOBAL_LOGGER_ENABLED as string = TRUE

/*
 Boolean
*/
#constant TRUE "T"
#constant FALSE "F"

// type names for map/set type check
#constant TYPE_STRING "string"
#constant TYPE_FLOAT "float"
#constant TYPE_INTEGER "int"

// null return value for Maps and Stacks
#constant NULL_VAL "__null__"
// whitespaces
#constant WHITESPACES chr(32)+chr(10)+chr(11)+chr(12)+chr(13)
// chars used in UUID
#constant HEX_CHARS "abcdef1234567890"

// others
#constant CRLF chr(13)+chr(10)
#constant qq chr(34)


// internal logging
#constant BACLOG = "bacure.log"

// read file to string
function ReadFile(filename$, linesep$)
	file = OpenToRead(filename$)
	data$ = ""
	while FileEOF(file) <> 1
		data$ = data$ + ReadLine(file) + linesep$
	endwhile
	CloseFile(file)
endfunction data$

type Map
	keys as string[]
	values as string[]
endtype

function MapPutFloat(map ref as Map, key$, value#)
	MapPut(map, key$, Str(value#))
endfunction

function MapPutInt(map ref as Map, key$, value)
	MapPut(map, key$, Str(value))
endfunction

function MapPut(map ref as Map, key$, value$)
	MapPutStr(map, key$, value$)
endfunction

function MapPutStr(map ref as Map, key$, value$)
	idx = _MapGetKeyIdx(map, key$)
	// if key exists then overwrite value
	if(idx <> -1)
		map.values[idx] = value$
	else 
		// key does not exists
		map.keys.insert(key$)
		map.values.insert(value$)
	endif
endfunction

function MapHasKey(map ref as Map, key$)
	if(_MapGetKeyIdx(map, key$) = -1) then exitfunction FALSE
endfunction TRUE

function _MapGetKeyIdx(map ref as Map, key$)
	for i = 0 to map.keys.length
		if map.keys[i] = key$ then exitfunction i
	next
endfunction -1
	
function MapGetInt(map ref as Map, key$)
	v = Val(MapGet(map, key$))
endfunction v

function MapGetFloat(map ref as Map, key$)
	v as float
	v = ValFloat(MapGet(map, key$))
endfunction v

function MapGet(map ref as Map, key$)
	v$ = MapGetStr(map, key$)
endfunction v$

function MapGet2(map ref as Map, key$, default$)
	v$ = MapGetStr(map, key$)
	if v$ = NULL_VAL then exitfunction default$
endfunction v$

function MapGetStr(map ref as Map, key$)
	keyidx = _MapGetKeyIdx(map, key$)
	if(keyidx >= 0) then exitfunction map.values[keyidx]
endfunction NULL_VAL

function MapGetKeys(map ref as Map)
endfunction map.keys

function MapGetValues(map ref as Map)
endfunction map.values

function MapRemove(map ref as Map, key$)
	keyidx = _MapGetKeyIdx(map, key$)
	if(keyidx = -1) then exitfunction FALSE
	map.keys.remove(keyidx)
	map.values.remove(keyidx)
endfunction TRUE

function MapRemoveAll(map ref as Map)
	map.keys.length = -1
	map.values.length = -1
endfunction

function MapSortByIntValue(m ref as Map, ascbool$)

	for i = m.keys.length to 1 step -1
		for j = 0 to i-1
			//if val(m.values[j]) < val(m.values[j+1])
			if _IsAGreaterThanB(Val(m.values[j]), Val(m.values[j+1]), ascbool$) = TRUE
				tmpval$ = m.values[j]
				m.values[j] = m.values[j+1]
				m.values[j+1] = tmpval$

				tmpkey$ = m.keys[j]
				m.keys[j] = m.keys[j+1]
				m.keys[j+1] = tmpkey$
						
			endif
		next
	next	
endfunction

function _IsAGreaterThanB(a, b, reverse$)
	if reverse$ = TRUE and a > b then exitfunction TRUE
	if reverse$ = FALSE and a < b then exitfunction TRUE
endfunction FALSE

function SetToPrintable(set ref as Set)
	str$=""
	for i = 0 to set.values.length
		value$ = set.values[i]
		str$ = str$ + "'" + value$ + "',"
		str$ = str$ + CRLF
	next	
endfunction str$


// returns proper TYPE_xxx constant or NULL_VAL if no key/value not found
function MapGetType(map ref as Map, key$) 
	if MapHasKey(map, key$) = FALSE then exitfunction NULL_VAL
	v$ = MapGet(map, key$)
	typ$ = GetValueType(v$)
endfunction typ$

function MapGetSize(map ref as Map)
endfunction map.keys.length+1

function SetGetSize(set ref as Set)
endfunction set.values.length+1


/*
 Type guess functionality for string content
*/
// TRUE if character for given ascii is 0-9
function IsNumber(ascii)
	if ascii >= 48 and ascii <= 57 then exitfunction TRUE
endfunction FALSE

// TRUE if character for given ascii is A-Z or a-z
function IsAlpha(ascii)
	if (ascii >= 97 and ascii <= 122) or (ascii >= 65 and ascii <= 90) then exitfunction TRUE
endfunction FALSE

// true if character for given ascii is alpha or numeric
function IsAlphaNumeric(ascii)
	if IsNumber(ascii) = TRUE or IsAlpha(ascii) = TRUE then exitfunction TRUE
endfunction FALSE

// returns TYPE_INTEGER, TYPE_FLOAT or TYPE_STRING for given string 
// e.g. "77" returns TYPE_INTEGER, "77.1" returns TYPE_FLOAT and "77abdef." returns TYPE_STRING
// given string is trimmed for WHITESPACE chars 
function GetValueType(s$)
	s$ = TrimString(s$, WHITESPACES)
	if len(s$) = 0 then exitfunction TYPE_STRING

	hasNumber$ = FALSE
	pointCount = 0 // number of point "." chars, more than one means it string rather than float
	
	firstch$ = Left(s$, 1)
	if firstch$ = "-" or firstch$ = "+" and len(s$) > 1 then startidx = 2 else startidx = 1

	for i = startidx to len(s$)
		c$ = mid(s$, i, 1)		
		a = asc(c$)
		if IsNumber(a) = TRUE
			hasNumber$ = TRUE
		elseif a = 46 // point '.' found
			// TODO handle float like .1 = 0.1
			inc pointCount, 1
			if pointCount > 1 then exitfunction TYPE_STRING
		else // there is at least one char other than number or point "." then this is a string
			exitfunction TYPE_STRING
		endif
	next
	
	if hasNumber$ = TRUE
		if pointCount = 0 
			exitfunction TYPE_INTEGER
		elseif pointCount = 1
			exitfunction TYPE_FLOAT
		endif
	endif
	
endfunction TYPE_STRING

function IsEmptyOrNull(t$)
	if t$ = "" or t$ = NULL_VAL then exitfunction TRUE
endfunction FALSE

function MapToStr(map ref as Map)
	str$ = ""
	for i = 0 to map.keys.length
		key$ = map.keys[i]
		value$ = map.values[i]
		
		str$ = str$ + key$ + "=" + value$
		
		if i < map.keys.length then str$ = str$ + ", "
		
	next
endfunction str$


/*
 Map (de)serialization
*/
function MapToCsvLine(map ref as Map, mapname$)

	str$ = _HexEncodeStr(mapname$)
	//format: mapname, key1, value1, key2, value2 ..."
	for i = 0 to map.keys.length
		key$ = map.keys[i]
		value$ = map.values[i]
		
		str$ = str$ + "," + _HexEncodeStr(key$) + "," + _HexEncodeStr(value$)
	next
endfunction str$

function CsvLineToMap(str$)
	map as Map
	count = CountStringTokens2(str$, ",")

	for i = 2 to count step 2
		key$ = GetStringToken2(str$, ",", i)
		value$ = GetStringToken2(str$, ",", i+1)
		map.keys.insert(_HexDecodeStr(key$))
		map.values.insert(_HexDecodeStr(value$))
	next
	
endfunction map

function _HexEncodeStr(str$)
	ret$ = ""
	for i = 1 to Len(str$)
		char$ = Mid(str$, i, 1)
		code = Asc(char$)
		hex$ = Hex(code)
		ret$ = ret$ + hex$
	next
endfunction ret$

function _HexDecodeStr(str$)
	ret$ = ""
	for i = 1 to Len(str$) step 2
		hex$ = Mid(str$, i, 2)
		code = Val(hex$, 16)
		char$ = Chr(code)
		ret$ = ret$ + char$
	next	
endfunction ret$

/*
 Sets. Mostly copied code from Maps
*/
type Set
	values as string[]
endtype

function SetPutFloat(set ref as Set, value#)
	SetPut(set, Str(value#))
endfunction

function SetPutInt(set ref as Set, value)
	SetPut(set, Str(value))
endfunction

function SetPut(set ref as Set, value$)
	SetPutStr(set, value$)
endfunction

function SetPutStr(set ref as Set, value$)
	idx = _SetGetValueIdx(set, value$)
	// if key exists then overwrite value
	if(idx >= 0)
		set.values[idx] = value$
	else 
		set.values.insert(value$)
	endif
endfunction

function SetHasValue(set ref as Set, value$)
	keyidx = _SetGetValueIdx(set, value$)
	if(keyidx = -1) then exitfunction FALSE
endfunction TRUE

function _SetGetValueIdx(set ref as Set, value$)
	for i = 0 to set.values.length
		if(set.values[i] = value$)
			exitfunction i
		endif
	next
endfunction -1

function SetGetInt(set ref as Set, value$)
	v = Val(SetGet(set, value$))
endfunction v

function SetGetFloat(set ref as Set, value$)
	v as float
	v = ValFloat(SetGet(set, value$))
endfunction v

function SetGet(set ref as Set, value$)
	v$ = SetGetStr(set, value$)
endfunction v$

function SetGetStr(set ref as Set, value$)
	keyidx = _SetGetValueIdx(set, value$)
	if(keyidx >= 0)
		if(set.values[keyidx] = value$)
			exitfunction set.values[keyidx]
		endif
	endif
endfunction NULL_VAL

function SetRemove(set ref as Set, value$)
	keyidx = _SetGetValueIdx(set, value$)
	if(keyidx = -1)
		exitfunction FALSE
	endif
	set.values.remove(keyidx)
endfunction TRUE

function SetRemoveAll(set ref as Set)
	set.values.length = -1
endfunction

// returns proper TYPE_xxx constant or NULL_VAL if no key/value not found
function GetSetType(set ref as Set, value$) 
	if SetHasValue(set, value$) = FALSE then exitfunction NULL_VAL
	v$ = SetGet(set, value$)
	typ$ = GetValueType(v$)
endfunction typ$

/*
 * Logging
 */

#constant LOG_TIME_FORMAT_DATETIME "DT"
#constant LOG_TIME_FORMAT_TIME "T"
#constant LOG_TIME_FORMAT_NONE "N"

#constant LOG_ERROR 0
#constant LOG_WARN 1
#constant LOG_INFO 2
#constant LOG_DEBUG 3
#constant LOG_TRACE 4
#constant LOG_NONE 5


global LOGGER_LEVEL_NAMES as string[0]
global LOGGER_FILEIDS_BY_FILE as Map
global LOGGER_LEVELS_BY_FILE as Map
global LOGGER_TIME_FORMATS_BY_FILE as Map

function InitLog(file$, loglevel, appendbool$, timeformat$)

	if loglevel >= LOG_NONE or loglevel < LOG_ERROR then exitfunction

	// check if logger level names array needs to be initialized
	if LOGGER_LEVEL_NAMES.length = 0  //
		LOGGER_LEVEL_NAMES.length = 6
		LOGGER_LEVEL_NAMES[LOG_ERROR] = "ERROR"
		LOGGER_LEVEL_NAMES[LOG_WARN] = "WARN"
		LOGGER_LEVEL_NAMES[LOG_INFO] = "INFO"
		LOGGER_LEVEL_NAMES[LOG_DEBUG] = "DEBUG"
		LOGGER_LEVEL_NAMES[LOG_TRACE] = "TRACE"
		LOGGER_LEVEL_NAMES[LOG_NONE] = "NONE"
	endif
	
	GLOBAL_LOGGER_ENABLED = TRUE
	
	MapPutInt(LOGGER_LEVELS_BY_FILE, file$, loglevel)	
	MapPutStr(LOGGER_TIME_FORMATS_BY_FILE, file$, timeformat$)

	if appendbool$ = TRUE then append = 1 else append = 0
	fileid = OpenToWrite(file$, append)
	MapPutInt(LOGGER_FILEIDS_BY_FILE, file$, fileid)
	CloseFile(fileid)
	
	//info("*** Bacure logging initialized with level " + LOGGER_LEVEL_NAMES[LOGGER_LEVEL] + " ***")
endfunction

function _WriteLog(file$, level, msg$)

	if GLOBAL_LOGGER_ENABLED = FALSE then exitfunction

	if MapHasKey(LOGGER_LEVELS_BY_FILE, file$) = FALSE then exitfunction

	loggerlevel = MapGetInt(LOGGER_LEVELS_BY_FILE, file$)
	if level > loggerlevel or level < LOG_ERROR then exitfunction

	levelname$ = LOGGER_LEVEL_NAMES[level]

	timeformat$ = MapGetStr(LOGGER_TIME_FORMATS_BY_FILE, file$)

	if timeformat$ = LOG_TIME_FORMAT_DATETIME
		msg$ = "[" + GetCurrentDate() + " " + GetCurrentTime() + "] " + levelname$ + ": " + msg$
	elseif timeformat$ = LOG_TIME_FORMAT_TIME
		msg$ = "[" + GetCurrentTime() + "] " + levelname$ + ": " + msg$
	else
		msg$ = levelname$ + ": " + msg$
	endif

	fileid = MapGetInt(LOGGER_FILEIDS_BY_FILE, file$)
	OpenToWrite(fileid, file$, 1)
	WriteLine(fileid, msg$)
	CloseFile(fileid)

endfunction

function CloseAllLogs()	
	keys as string[]
	keys = MapGetKeys(LOGGER_FILEIDS_BY_FILE)
	for i = 0 to keys.length
		CloseLog(keys[i])
	next
endfunction

function CloseLog(file$)
	if MapHasKey(LOGGER_FILEIDS_BY_FILE, file$) = FALSE then exitfunction	
	fileid = MapGetInt(LOGGER_FILEIDS_BY_FILE, file$)
	CloseFile(fileid)
endfunction

function error(file$, msg$)
	_WriteLog(file$, LOG_ERROR, msg$)
endfunction

function warn(file$, msg$)
	_WriteLog(file$, LOG_WARN, msg$)
endfunction

function info(file$, msg$)
	_WriteLog(file$, LOG_INFO, msg$)
endfunction

function debug(file$, msg$)
	_WriteLog(file$, LOG_DEBUG, msg$)
endfunction

function trace(file$, msg$)
	_WriteLog(file$, LOG_TRACE, msg$)
endfunction




/*
 TGF Trivial Graph Format
*/
type TGraph
	id as string
	nodes as Map
	edges as TGraphEdge[]
endtype

type TGraphEdge
	fromId as string
	toId as string
	text as string
	tags as Map
endtype

function TgfParseFile(file$)
	graphs as TGraph[] 
	tgfFile = OpenToRead(file$)
	phase = 0 // 0=id, 1=nodes(npc lines), 2=edges(node to node, player lines and tags)
	graph as TGraph
	sep$ = Chr(34)
	while FileEOF(tgfFile) <> 1
		line$ = TrimString(ReadLine(tgfFile), " ") 
		if Left(line$, 1) = "#"
			Inc phase 
			if(phase = 3) 
				phase = 0 
				graphs.insert(graph)
			endif
		else
			select phase
				case 0: // id
					graph.id = line$
				endcase
				case 1: // nodes
					idx = FindString(line$, " ")
					nodeId$ = Left(line$, idx-1)
					textLen = Len(line$)-1-Len(nodeId$)
					nodeText$ = ReplaceString(Right(line$, textLen), "''", Chr(34), -1)
					MapPut(graph.nodes, nodeId$, nodeText$)
				endcase
				case 2: // edges
					edge as TGraphEdge
					// node ids from->to
					idPart$ = TrimString(GetStringToken(line$, sep$, 1), " ")
					edge.fromId = GetStringToken(idPart$, " ", 1)
					edge.toId = GetStringToken(idPart$, " ", 2)
					
					// text
					edge.text = ReplaceString(GetStringToken(line$, sep$, 2), "''", Chr(34), -1) 
					
					// tags map
					if(CountStringTokens(line$, sep$) >= 3)
						tagMap as Map
						tagPart$ = GetStringToken(line$, sep$, 3)
						for i = 1 to CountStringTokens(tagPart$, " ")
							tagItem$ = GetStringToken(tagPart$, " ", i)
							key$ = GetStringToken2(tagItem$, "=", 1)
							value$ = GetStringToken2(tagItem$, "=", 2)
							MapPut(tagMap, key$, value$)
						next
						edge.tags = tagMap
					endif

					graph.edges.insert(edge)
				endcase
			endselect
		endif
	endwhile
	CloseFile(tgfFile)
endfunction graphs



/*
 Stack
*/

// Tests if this stack is empty.
function StaEmpty(a ref as string[])
	if(a.length = -1) then exitfunction TRUE
endfunction FALSE

// Looks at the object at the top of this stack without removing it from the stack.
function StaPeek(a ref as string[])
	if(a.length = -1) then exitfunction NULL_VAL
	ret$ = a[a.length]
endfunction ret$

// Look idx object from at the top of stack. idx=1 is top
function StaPeekByIdx(a ref as string[], idx)
	if(idx > a.length+1) then exitfunction NULL_VAL
	ret$ = a[a.length+1 - idx]
endfunction ret$

// Removes the object at the top of this stack and returns that object as the value of this function.
function StaPop(a ref as string[])
	if(a.length = -1) then exitfunction NULL_VAL
	ret$ = StaPeek(a)
	a.remove()
endfunction ret$

// size of current stack
function StaLen(a ref as string[])
endfunction a.length+1

// Pushes an item onto the top of this stack.
function StaPush(a ref as string[], val as string)
	a.insert(val)
endfunction

// Returns the 1-based position where an object is on this stack. 1 = top
function StaSearch(a ref as string[], val as string)
	if(a.length >= 0) 
		dis = 1
		for i = a.length to 0 step -1
			if(a[i] = val) then exitfunction dis
			Inc dis, 1
		next
	endif
endfunction -1



/* 
 XML parser
*/

type XmlElement
	name as string
	content as string
	isSelfClosed as string
	isStartTag as string
	attributes as Map
	isValid as string
endtype

// decode XML unsafe characters
function _XmlStr(s$)
        s$ = ReplaceString(s$, "&apos;", "'", -1)
        s$ = ReplaceString(s$, "&lt;", "<", -1)
        s$ = ReplaceString(s$, "&gt;", ">", -1)
        s$ = ReplaceString(s$, "&quot;", chr(34), -1)
        s$ = ReplaceString(s$, "&amp;", "&", -1)
endfunction s$

function XmlParseFile(filename$)
	document as XmlElement[]
	document = XmlParseDocument(ReadFile(filename$, ""))
endfunction document

function XmlParseDocument(data as string)
	trace(BACLOG, "XmlParseDocument parsing content '" + data + "'")
	elements as XmlElement[]
	e as XmlElement
	tokenNum = CountStringTokens(data, "<")
	debug(BACLOG, "XmlParseDocument " + str(tokenNum) + " tokens found")
	for i = 1 to tokenNum
		token$ = GetStringToken(data, "<", i)
		trace(BACLOG, "Parsed token:"+token$)
		e = _XmlParseElement(token$)
		name$ = e.name
		debug(BACLOG, "XmlParseDocument found element:" + name$)
		elements.insert(e)
	next
endfunction elements

function _XmlParseElement(x as string)
	trace(BACLOG, "_XmlParseElement raw input '"+x+"'")
	e as XmlElement
	x = TrimString(x, WHITESPACES)

	//trace(BACLOG, "_XmlParseElement parse element '<" + x + "'")
		
	e.isValid = TRUE

	if(Left(x, 1) <> "/") 
		e.isStartTag = TRUE
	else
		e.isStartTag = FALSE
	endif

	trace(BACLOG, "_XmlParseElement is start tag: " + e.isStartTag)

	// if no content then Len = 0
	content$ = _XmlGetContent(x)
	
	// remove content from element data
	contentLen = Len(content$)
	if(contentLen > 0)
		e.content = _XmlStr(content$)
		x = Left(x, Len(x)-contentLen)
		trace(BACLOG, "_XmlParseElement content '" + content$ + "'")
	endif
		
	if(Right(x, 2) = "/>")
		e.isSelfClosed = TRUE
	elseif(Right(x, 1) = ">")
		e.isSelfClosed = FALSE
	else
		e.isValid = FALSE
		warn(BACLOG, "_XmlParseElement ignoring invalid element '" + x + "'")
		exitfunction e
	endif
	
	trace(BACLOG, "_XmlParseElement is self closed elem: " + e.isSelfClosed)
	
	// parse tag name
	tmp$ = ""
	
	wsIdx = _XmlFirstIndexOfChar(x, WHITESPACES) // returns -1 if no chars found 

	if(wsIdx = 0)
		// the element does not have attributes so parse only a tag name
		
		//tmp$ = ""
		il = Len(x)
		for i = 1 to il
			ch$ = Mid(x, i, 1)
			if(ch$ <> ">" and ch$ <> "/")
				tmp$ = tmp$ + ch$
			endif
		next

		e.name = tmp$

		//debug(BACLOG, "_XmlParseElement found new element '" + e.name + "'")
		trace(BACLOG, "_XmlParseElement element has no attributes")
		lll$ = "len=" + str(e.attributes.keys.length)
		trace(BACLOG, lll$)

		exitfunction e
	else
		// attributes must be parsed
		name$ = Left(x, wsIdx-1)
		e.name = name$
	
		// parser states, initial state is attrState
		state as string
		state = "a" // initial state is attr

		attribute as string

		for i = wsIdx to Len(x)
			ch$ = Mid(x, i, 1)
			
			select state
				case "a" // attribute
					if(ch$ = "=")
						attribute = tmp$
						trace(BACLOG, "_XmlParseElement found attribute name '" + attribute + "'")
						tmp$ = ""
						state = "="
					elseif(_XmlIsWhitespace(ch$) = FALSE)
						tmp$ = tmp$ + ch$
					endif
				endcase
				
				case "=" // equals
					if(_XmlIsWhitespace(ch$) = TRUE)
						// ignore
					elseif(ch$ = chr(34)) // " found
						state = "v" // next state: parse attr value
					else
						// onko error?
						warn(BACLOG, "_XmlParseElement attribute is invalid due missing " + chr(34))
						e.isValid = FALSE
					endif
				endcase

				case "v" // value
					if(ch$ = chr(34))
						state = "a"
						debug(BACLOG, "_XmlParseElement attribute found: name='" + attribute + "' value='" + tmp$ + "'")
						tmp$ = _XmlStr(tmp$)
						MapPut(e.attributes, attribute, tmp$)
						tmp$ = ""
					else
						tmp$ = tmp$ + ch$
					endif
				endcase

			endselect
		next
		
	endif

endfunction e

function _XmlIsWhitespace(char$) 
	if(char$ = " ") then exitfunction TRUE
	code = Asc(char$)
	if(code >= 10 and code <= 13) then exitfunction FALSE
endfunction FALSE
	
// returns 0 if no char found, otherwise char index
function _XmlFirstIndexOfChar(s as string, chars as string)
	for i = 1 to Len(s)
		ch$ = Mid(s, i, 1)
		//integer FindString( str, findStr )
		if(FindString(chars, ch$) > 0)
			exitfunction i
		endif		
	next	
endfunction 0

function _XmlGetContent(elem$)
	elemLen = Len(elem$)
	for i = elemLen to 1 step -1
		c$ = Mid(elem$, i, 1)
		if(c$ = ">") then exit
	next
	content$ = Mid(elem$, i+1, elemLen)
endfunction content$




/*
 * UUID
 */
function GenUUID()
	uuid$ = ""
	for i = 0 to 35
		charidx = random(1, 16)
		if i = 8 or i = 13 or i = 18 or i = 23
			uuid$ = uuid$ + "-"
		else
			uuid$ = uuid$ + Mid(HEX_CHARS, charidx, 1)
		endif
	next
endfunction uuid$



/*
 * Yarn dialogue editor support. This does not support new "->" kind lines yet
 */
/*
// returns -1 if no match
function _GetFirstIndexOfChar(str$, singleChar$)
	le = Len(str$)
	for i = 1 to le
		if Mid(str$, i, 1) = singleChar$ then exitfunction i
	next 
endfunction -1

type YarnDialogEntry
	text as string
endtype

type YarnNode
	title as string
	tags as Set
	lines as YarnDialogEntry[]
	replies as YarnOptionEntry[]
endtype

type YarnOptionEntry
	text as string
	target as string
endtype

type YarnDocument
	nodes as YarnNode[]
endtype

#constant YARN_HEADER = "h"
#constant YARN_BODY = "b"

function ParseYarnDocument(content$)
	state as String
	state = YARN_HEADER
	lineCount = CountStringTokens(content$, chr(10))

	doc as YarnDocument

	currentNode as YarnNode
	currentOptionEntry as YarnOptionEntry
	currentDialogEntry as YarnDialogEntry
	
	for lineNum = 1 to lineCount
		line$ = GetStringToken(content$, chr(10), lineNum)
		line$ = TrimString(line$, WHITESPACES)
		itemCount = CountStringTokens(line$, ":")

		// if it's header line with content like key:value then it is really header line
		if state = YARN_HEADER and _GetFirstIndexOfChar(line$, ":") >= 2
			key$ = GetStringToken(line$, ":", 1)
			if key$ = "title" 
				currentNode.title = GetStringToken(line$, ":", 2)
			elseif key$ = "tags"
				// TODO: add items to set, selvitä välimerkki
			endif
		// else, it's a body line: either raw text or with a line with options
		elseif state = YARN_BODY
			// minimum option line [[a|b]] len=7
			sepIdx = _GetFirstIndexOfChar(line$, "|") 
			if len(line$) >= 7 and left(line$, 2) = "[[" and right(line$, 2) = "]]" and sepIdx >= 4
				// it is an option line				
			else
				currentDialogEntry.text = line$
			endif
			
		elseif line$ = "---"
			//body starts
			state = YARN_BODY
		elseif line$ = "==="
			// next entry
			state = YARN_HEADER
		endif
	next
	
	
endfunction doc
*/


/*
 * D3 studio XML format
 */ 

type D3Text
	lang as string
	data as string
endtype

type D3Answer
	targetid as string
	need as Set
	not_ as Set
	answer as D3Text
	userdata as string
endtype

type D3Card
	id as string
	settags as Set
	cleartags as Set
	userdata as string
	question as D3Text
	answers as D3Answer[]
endtype

type D3Deck
	id as string
	userdata as String
	cards as D3Card[]
endtype

// keep all decks in memory?
global _decks as D3Deck[]
global _deckIdx as integer
global _card as D3Card
global _d3tags as Set

// returns TRUE if mytags will pass 
function D3PassTags(mytags as Set, need as Set, not_ as Set)
	if(SetGetSize(need) > 0)
		needtagspass$ = FALSE
		// this needs some tags
		for i = 0 to mytags.values.length
			mytag$ = mytags.values[i]
			if(SetHasValue(need, mytag$) = FALSE) then needtagspass$ = TRUE
		next
		if(needtagspass$ = FALSE) then exitfunction FALSE
	endif
		
	for i = 0 to mytags.values.length
		// check not-tags
		mytag$ = mytags.values[i]
		if(SetHasValue(not_, mytag$) = TRUE) then exitfunction FALSE
	next
endfunction TRUE

function D3InitCard(id$)
	for i = 0 to _decks.length
		if(_decks[i].id = id$)
			_deckIdx = i
			_card = _decks[_deckIdx].cards[0]			
			//handle tags
			exitfunction TRUE
		endif		
	next
endfunction FALSE

function D3GetQuestion()
endfunction _card.question.data

function D3GetAnswers()
	answers as string[]
	answers.length = _card.answers.length
	for i = 0 to _card.answers.length
		// TODO filter answers based on need, not, userdata ...
		answers[i] = _card.answers[i].answer.data
	next
endfunction answers

//  sets new card
function D3Answer(answerIdx as integer)
	targetId$ = _card.answers[answerIdx].targetid
	D3InitCard(targetId$)
endfunction

function D3XmlStrToTags(str as string)
	c = CountStringTokens(str, " ")
	tags as Set
	for i = 0 to c
		tag$ = GetStringToken(str, " ", c)
		tag$ = TrimString(str, " ")
		if(tag$ <> "") then SetPut(tags, tag$)
	next
		
endfunction tags

function D3LoadDeck(filename$)
	deck as D3Deck
	deck = D3ParseDeck(ReadFile(filename$, ""))
endfunction	deck
	
function D3ParseDeck(content$)

	deck as D3Deck
	e as XmlElement[]

	card as D3Card
	a as D3Answer
	txt as D3Text

	ename as string
	xsta as string[]

	cardidx = -1
	aidx = -1

	e = XmlParseDocument(content$)
	
	//info(BACLOG, "D3ParseDeck parse file " + filename$)

	for i = 0 to e.length
		ename = Lower(e[i].name) // element name is now in low case
		//debug(BACLOG, "next D3 element:" + ename)

		if(e[i].isStartTag = TRUE)
			StaPush(xsta, ename)

			debug(BACLOG, "handling D3 element:" + ename)

			if ename = "deck"
				info(BACLOG, "handling D3 element:" + ename)
				deck.id = MapGetStr(e[i].attributes, "id")				
				// check if duplicate deck.id found
				for ii = 0 to _decks.length
					if(_decks[ii].id = deck.id)
						error(BACLOG, "duplicate D3Deck id " + deck.id)
					endif
				next
			elseif ename = "card"
				aidx = -1
				card.id = MapGetStr(e[i].attributes, "id")
				
				tmp$ = MapGet2(e[i].attributes, "set", "")
				card.settags = D3XmlStrToTags(tmp$)
				tmp$ = MapGet2(e[i].attributes, "clear", "")
				card.cleartags = D3XmlStrToTags(tmp$)
				
				deck.cards.insert(card)
				inc cardidx, 1
			elseif ename = "question"
				txt.lang = MapGet2(e[i].attributes, "lang", "")
				txt.data = e[i].content
				deck.cards[cardidx].question = txt
			elseif ename = "userdata"
				// check stack
				parent$ = StaPeekByIdx(xsta, 2)
				debug(BACLOG, "parent for userdata is " + parent$)
				select parent$
					case "a"
						deck.cards[cardidx].answers[aidx].userdata = e[i].content
						debug(BACLOG, "set userdata="+e[i].content+" for " + parent$)
					endcase
					case "card"
						deck.cards[cardidx].userdata = e[i].content
						debug(BACLOG, "set userdata="+e[i].content+" for " + parent$)
					endcase
					case "deck"
						deck.userdata = e[i].content
						debug(BACLOG, "set userdata="+e[i].content+" for " + parent$)
					endcase
				endselect
				
			elseif ename = "a" // answer
				
				for ii = 0 to e[i].attributes.keys.length
					z$ = "attr:" + e[i].attributes.keys[ii] + "=" + e[i].attributes.values[ii]
					debug(BACLOG, z$)
				next

				//card.id = MapGetStr(e[i].attributes, "id")
				debug(BACLOG, "targetid idx=" + str(_MapGetKeyIdx(e[i].attributes, "targetid")))
				
				/*
				tmp2$ = MapGetStr(e[i].attributes, "targetid")
				a.targetid = tmp2$
				debug(BACLOG, "zzzzz targetid="+tmp2$)
				*/

				tmp$ = MapGet2(e[i].attributes, "need", "")
				a.need = D3XmlStrToTags(tmp$)
				
				tmp$ = MapGet2(e[i].attributes, "not", "")
				a.not_ = D3XmlStrToTags(tmp$)
				
				deck.cards[cardidx].answers.insert(a)
				inc aidx, 1
				
				debug(BACLOG, "found targetid="+a.targetid)
				
			elseif ename = "answer"
				txt.lang = MapGet2(e[i].attributes, "lang", "")
				txt.data = e[i].content
				deck.cards[cardidx].answers[aidx].answer = txt
			endif
			
			if(e[i].isSelfClosed = TRUE) then StaPop(xsta)
			
		elseif(e[i].isStartTag = FALSE)
			StaPop(xsta)
		endif
	next
	
	// perform post handling, e.g. setting deck entry card as first item
	targets as Set
	for i = 0 to deck.cards.length
		for j = 0 to deck.cards[i].answers.length
			if deck.cards[i].answers.length > 0
				targetid$ = deck.cards[i].answers[j].targetid
				SetPutStr(targets, targetid$)
			endif
		next
	next

	// entry card must be first item in array
	for i = 0 to deck.cards.length
		if SetHasValue(targets, deck.cards[i].id) = FALSE
			if i <> 0
				tmpdeck as D3Card
				tmpdeck = deck.cards[0]
				deck.cards[0] = deck.cards[i]
				deck.cards[i] = tmpdeck
			endif
			debug(BACLOG, "entry card is id="+deck.cards[0].id)
			exit
		endif
	next
	
	trace(BACLOG, D3Deck2XML(deck))

endfunction deck
				


/*
 Tiled TMX CSV Map parser
*/

#constant TMX_MAP_VERSION "1.1"

// TMX property types
#constant TMX_TYPE_STRING "s"
#constant TMX_TYPE_INT "i"
#constant TMX_TYPE_FLOAT "f"
#constant TMX_TYPE_BOOL "b"
#constant TMX_TYPE_COLOR "C"
#constant TMX_TYPE_FILE "F"

type TmxProperties
	map as Map
	tmxtype as string[]
endtype


function TmxPropertiesValidateType(value$, typ$)
	
	if typ$ = TMX_TYPE_STRING then exitfunction TRUE
	
	typedetected$ = GetValueType(value$)
	
	if typ$ = TMX_TYPE_INT and typedetected$ = TYPE_INTEGER then exitfunction TRUE
	if typ$ = TMX_TYPE_FLOAT and typedetected$ = TYPE_FLOAT  then exitfunction TRUE
	
	//if typedetected$ <> TYPE_STRING then exitfunction FALSE // this should never happen
	
	tmp$ = Lower(value$)
	
	if typ$ = TMX_TYPE_BOOL and (tmp$ = "true" or tmp$ = "false") then exitfunction TRUE
	
	// e.g. //#00112233 or #aabb33
	if typ$ = TMX_TYPE_COLOR
		
		if Left(tmp$, 1) <> "#" then exitfunction FALSE
		
		l = Len(tmp$)
		if l <> 9 and l <> 7 then exitfunction FALSE
		
		for i = 2 to Len(tmp$)
			tmpch$ = Mid(tmp$, i, 1)
			if FindString(HEX_CHARS, tmpch$, 0, 1) = 0 then exitfunction FALSE
		next
		
		exitfunction TRUE
		
	endif
endfunction FALSE

function TmxPropertiesPut(p ref as TmxProperties, key$, rawstrvalue$, tmxtype$)
	if TmxPropertiesValidateType(rawstrvalue$, tmxtype$) = FALSE then exitfunction FALSE
	
	idx = _MapGetKeyIdx(p.map, key$)
	if idx = -1
		MapPutStr(p.map, key$, rawstrvalue$)
		idx = p.map.keys.length - 1
	endif
	p.tmxtype[idx] = tmxtype$
	exitfunction TRUE
endfunction FALSE

// and a wrapper for each type
function TmxPropertiesGetInt(p ref as TmxProperties, key$)
	exitfunction MapGetInt(p.map, key$)
	// it's safe to return -1 because type format is being check when value is added
endfunction -1

function TmxPropertiesGetFloat(p ref as TmxProperties, key$)
	exitfunction MapGetFloat(p.map, key$)
endfunction -1.0

function TmxPropertiesGetString(p ref as TmxProperties, key$)
	exitfunction MapGetStr(p.map, key$)
endfunction NULL_VAL

function TmxPropertiesGetBool(p ref as TmxProperties, key$)
	exitfunction MapGetStr(p.map, key$)
endfunction FALSE

function TmxPropertiesGetColor(p ref as TmxProperties, key$)
	exitfunction MapGetStr(p.map, key$)
endfunction NULL_VAL

function TmxPropertiesGetType(p ref as TmxProperties, key$)
	idx = _MapGetKeyIdx(p.map, key$)
	typ$ = TmxPropertiesGetType(p, key$)
endfunction typ$

type TmxGenericLayer
	name as string
	opacity as float // def 1
	visible as string // def=true
	offsetx as integer // def 0
	offsety as integer // def 0
endtype

function _TmxParseGenericLayer(attrs ref as Map)
	g as TmxGenericLayer
	g.name = _TmxParseAttrStr(attrs, "name", "")
	g.offsetx = _TmxParseAttrInt(attrs, "offsetx", 0)
	g.offsety = _TmxParseAttrInt(attrs, "offsety", 0)
	g.opacity = _TmxParseAttrFloat(attrs, "opacity", 0.0)
	g.visible = _TmxInt2Bool(_TmxParseAttrStr(attrs, "visible", ""))
	
endfunction g

function _TmxInt2Bool(val$)
	bool$ = _TmxInt2Bool2(val$, FALSE)
endfunction bool$

function _TmxInt2Bool2(val$, defbool$)
	val$ = lower(val$)
	if val$ = "true" then exitfunction TRUE
	if val$ = "false" then exitfunction FALSE
endfunction defbool$

function _TmxParseBoolInt(attrs ref as Map, name$, defbool$)
	bool$ = _TmxParseAttrStr(attrs, name$, defbool$)
	exitfunction _TmxInt2Bool2(bool$, defbool$)
endfunction FALSE

// Group voi sisältää groupin, ei tehdä typeä vaan hoidetaan parserissa	

type TmxColor
	r as integer
	g as integer
	b as integer
	a as integer
endtype

function _TmxColor2Str(t ref as TmxColor)
	s$ = "#"
	if t.a >= 0 then s$ = s$ + Hex(t.a)	
	s$ = s$ + Hex(t.r) + Hex(t.g) + Hex(t.b)
endfunction s$

function _TmxIsNullColor(t ref as TmxColor)
	if t.a >= 0 and t.r >= 0 and t.g >= 0 and t.b >= 0 then exitfunction TRUE
endfunction FALSE

type TmxText
	fontfamily as string
	pixelsize as integer
	wrapbool as string
	boldbool as string
	italicbool as string
	underlinebool as string
	strikeoutbool as string
	kerningbool as string
	haling as string
	valing as string
	color as TmxColor
	data as string
endtype

function _TmxBool2IntStr(bool as string)
	if bool = TRUE then exitfunction "1" 
endfunction "0"


type TmxImage
	source as string
	trans as TmxColor
	width as integer
	height as integer
endtype

type TmxTile
	id as integer
	terrain as integer[]
	propability as float
	tiletype as integer
	objectgroup as TmxObjectGroup
	//image as TmxImage
	animframes as TmxFrame[]
	properties as TmxProperties
endtype


/*
type TmxWangTile
	id as integer
	// index order: top, right, down, left
	edgescolors as integer[]
	cornercolors as integer[]	
endtype

type TmxWangColor
	name as string
	color as TmxColor
	tileid as string
	propability as float
endtype

type TmxWangEdgeColor
	edge as TmxWangColor
endtype

type TmxWangCornerColor
	corner as TmxWangColor
endtype	

type TmxWangSet
	name as string
	tileid as string
	cornercolor as TmxWangCornerColor
	edgecolor as TmxWangEdgeColor
	tile as TmxWangTile
endtype

type TmxWangSets
	wangsets as TmxWangSet[]
endtype
*/

type TmxFrame
	tileid as integer
	duration as integer	
endtype

type TmxTerrain
	name as string
	tile as integer
	properties as TmxProperties
endtype

type TmxTileset
	firstgid as integer
	name as string
	tilewidth as integer
	tileheight as integer
	spacing as integer
	margin as integer
	tilecount as integer
	columns as integer
	
	image as TmxImage
	properties as TmxProperties
	
	hastileoffsetbool as string
	tileoffsetx as integer
	tileoffsety as integer
	tiles as TmxTile[]
	//tileoffset as TmxTileOffset
	terraintypes as TmxTerrain[]
endtype

function _TmxCloseTag(name as string, siblingcount as integer)
	if siblingcount = 0 then s$ = "/>" else s$ = CRLF + "</"+name+">"
endfunction s$

type TmxLayer
	gen as TmxGenericLayer
	width as integer
	height as integer
	properties as TmxProperties
	data as integer[]
endtype


type TmxImageLayer
	gen as TmxGenericLayer
	properties as TmxProperties
	image as TmxImage
endtype


type TmxObjectShape
	shapetype as string // "e"=ellipse, "g"=polygon, "l"=polyline
	points as integer[] // x1,y1,x2,y2
endtype

type TmxObject
	id as integer
	name as string
	otype as string
	x as float
	y as float
	width as integer // def 0
	height as integer // def 0
	rotation as integer //def 0
	gid as integer
	visible as string // def=true
	tid as integer
	
	properties as TmxProperties
	shape as TmxObjectShape
	//image as TmxImage
	text as TmxText
endtype

type TmxObjectGroup
	gen as TmxGenericLayer
	color as TmxColor
	draworder as string // i = index, t = topdown(default)
	objects as TmxObject[]
	properties as TmxProperties
endtype

type TmxMap
	orientation as string
	renderorder as string
	width as integer
	height as integer
	tilewidth as integer //
	tileheight as integer //
	hexsidelength as integer //
	staggeraxis as string  //
	staggerindex as string //
	nextobjectid as integer
	backgroundcolor as TmxColor //

	tilesets as TmxTileset[]
	layers as TmxLayer[]
	objectgroups as TmxObjectGroup[]
	imagelayers as TmxImageLayer[]
	properties as TmxProperties
endtype


// parse color hex str to TmxColor, #AARRGGBB or without alpha channel #RRGGBB, e.g. "#FF00FF00" or "FF00FF00"
function _TmxParseColor(hexrgba$)
	hexrgba$ = TrimString(hexrgba$, WHITESPACES)
	if left(hexrgba$, 1) = "#" then offset = 1 else offset = 0
	len_ = len(hexrgba$)
	debug(BACLOG, "len_="+str(len_))
	c as TmxColor
	
	if len_ = 8+offset
		// there is alpha channel
		idx = 1 + offset
		c.a = val(mid(hexrgba$, idx, 2), 16)
		inc idx, 2
	elseif len_ = 6+offset
		c.a = 255
		idx = 1+offset
	else
		c.a = -1
		c.r = -1
		c.g = -1
		c.b = -1
		exitfunction c
	endif

	c.r = val(mid(hexrgba$, idx, 2), 16)
	Inc idx, 2
	c.g = val(mid(hexrgba$, idx, 2), 16)
	Inc idx, 2
	c.b = val(mid(hexrgba$, idx, 2), 16)
	
endfunction c



// e.g. "../Program Files/Tiled/examples/tiles.png" returns "tiles.png"
// it actually just stripts path away
function _TmxParseImageSource(imageSource$)
	i = FindStringReverse(imageSource$, "/")
	filenameLen = Len(imageSource$) - i
	ret$ = Right(imageSource$, filenameLen)
endfunction ret$

function TmxGetTile(m ref as TmxMap, l ref as TmxLayer, x, y)
	tIdx = x + y*m.height
endfunction l.data[tIdx] 

function TmxGetTilesetIdxByName(m ref as TmxMap, name$)
	for i = 0 to m.tilesets.length
		if(m.tilesets[i].name = name$) then exitfunction i
	next
endfunction -1

function _TmxGetLayerIdxByName(m ref as TmxMap, name$)
	for i = 0 to m.layers.length
		if(m.layers[i].gen.name = name$) then exitfunction i
	next
endfunction -1

function _TmxParseShapePointData(data$)
	// 1,2 3,4 5,6
	data$ = TrimString(data$, WHITESPACES)
	num = CountStringTokens(data$, ","+WHITESPACES)
	points as integer[]
	i = 1
	repeat
		x = Val(GetStringToken(data$, ","+WHITESPACES, i))
		points.insert(x)
		Inc i, 1
		
		y = Val(GetStringToken(data$, ","+WHITESPACES, i))
		points.insert(y)
		Inc i, 1
	until i > num
endfunction points

//				if(MapHasKey(e[i].attributes, "offsetx") = TRUE) then il.gen.offsetx = Val(MapGet(e[i].attributes, "offsetx")) else il.gen.offsetx = 0

function _TmxParseAttrStr(attrs as Map, name$, defval$)
	if MapHasKey(attrs, name$) = TRUE then exitfunction MapGetStr(attrs, name$)
endfunction defval$

function _TmxParseAttrInt(attrs as Map, name$, defval)
	if MapHasKey(attrs, name$) = TRUE then exitfunction MapGetInt(attrs, name$)
endfunction defval

function _TmxParseAttrFloat(attrs as Map, name$, defval#)
	if MapHasKey(attrs, name$) = TRUE then exitfunction MapGetFloat(attrs, name$)
endfunction defval#

/*
 * This src used only to convert some Types like TMX* back to XML strings for validation purposes
 */
#include "bacure2xml.agc"

function TmxParseFile(filename$)
	m as TmxMap
	info(BACLOG, "TmxParseFile parse file " + filename$)
	m = TmxParse(ReadFile(filename$, CRLF))
endfunction	m

function TmxParse(data$) 
	m as TmxMap
	e as XmlElement[]
	
	// types
	sh as TmxObjectShape
	la as TmxLayer
	og as TmxObjectGroup
	ob as TmxObject
	il as TmxImageLayer
	ts as TmxTileset
	im as TmxImage
	ti as TmxTile
	fr as TmxFrame
	te as TmxTerrain
	
	ename as string
	xsta as string[]

	// init indexes
	layerIdx = -1
	objIdx = -1
	objGroupIdx = -1
	tilesetIdx = -1
	tileIdx = -1
	imageLayerIdx = -1
	terrainIdx = -1

	e = XmlParseDocument(data$)
	
	for i = 0 to e.length
		ename = Lower(e[i].name) // element name is now in low case
		if(e[i].isStartTag = TRUE)
			StaPush(xsta, ename)

			if(ename = "map")
				
				// o = orthogonal, i = isometric, s = staggered, h = hexagonal
				m.orientation = Left(MapGet(e[i].attributes, "orientation"), 1)

				// 1 = right down, 2 = left down, 3 = right up, 4 = left up, 
				select _TmxParseAttrStr(e[i].attributes, "renderorder", "right-down")
					case "right-down"
						m.renderorder = "1"
					endcase
					case "left-down"
						m.renderorder = "2"
					endcase
					case "right-up"
						m.renderorder = "3"
					endcase
					case "left-up"
						m.renderorder = "4"
					endcase
				endselect

				
				m.width = Val(MapGet(e[i].attributes, "width"))
				m.height = Val(MapGet(e[i].attributes, "height"))
				m.tilewidth = Val(MapGet(e[i].attributes, "tilewidth"))
				m.tileheight = Val(MapGet(e[i].attributes, "tileheight"))		
				m.nextobjectid = Val(MapGet(e[i].attributes, "nextobjectid"))

				m.hexsidelength = _TmxParseAttrInt(e[i].attributes, "hexsidelength", 0)
				m.staggeraxis = _TmxParseAttrStr(e[i].attributes, "staggeraxis", "")
				m.backgroundcolor = _TmxParseColor(MapGet(e[i].attributes, "backgroundcolor"))

				// o = odd, e = even
				m.staggerindex = left(_TmxParseAttrStr(e[i].attributes, "staggerindex", ""), 1)				
								
			elseif(ename = "tileset")
				tileIdx = -1
				ts.firstgid = Val(MapGet(e[i].attributes, "firstgid"))			
				ts.name = MapGet(e[i].attributes, "name")
				ts.tilewidth = Val(MapGet(e[i].attributes, "tilewidth"))
				ts.tileheight = Val(MapGet(e[i].attributes, "tileheight"))
				ts.tilecount = Val(MapGet(e[i].attributes, "tilecount"))
				ts.columns = Val(MapGet(e[i].attributes, "columns"))

				ts.spacing = _TmxParseAttrInt(e[i].attributes, "spacing", 0)
				ts.margin = _TmxParseAttrInt(e[i].attributes, "margin", 0)
			
				m.tilesets.insert(ts)
				Inc tilesetIdx, 1
			elseif(ename = "tileoffset")
				m.tilesets[tilesetIdx].tileoffsetx = _TmxParseAttrInt(e[i].attributes, "x", 0)
				m.tilesets[tilesetIdx].tileoffsety = _TmxParseAttrInt(e[i].attributes, "y", 0)
			elseif(ename = "tile")
				// support only tiles in tileset
				select StaPeekByIdx(xsta, 2)
					case "tileset"
						ti.id = Val(MapGet(e[i].attributes, "id"))
						ti.animframes.length = -1
						ti.properties.map.keys.length = -1
						ti.properties.map.values.length = -1
						ti.properties.tmxtype.length = -1
						m.tilesets[tilesetIdx].tiles.insert(ti)
						Inc tileIdx, 1
					endcase
				endselect
			elseif(ename = "frame")
				select StaPeekByIdx(xsta, 4)
					case "tileset"
						fr.tileid = Val(MapGet(e[i].attributes, "tileid"))
						fr.duration = Val(MapGet(e[i].attributes, "duration"))
						m.tilesets[tilesetIdx].tiles[tileIdx].animframes.insert(fr)
					endcase
				endselect
			elseif(ename = "image")
				//im.format = MapGet(e[i].attributes, "format")
				//im.format = TmxPropertiesGetString(e[i].attributes, "format") //format is used only for embedded images
				im.source = _TmxParseImageSource(MapGet(e[i].attributes, "source"))
				im.trans = _TmxParseColor(MapGet(e[i].attributes, "trans"))
				im.width = Val(MapGet(e[i].attributes, "width"))
				im.height = Val(MapGet(e[i].attributes, "height"))
				select StaPeekByIdx(xsta, 2) // take 3rd top item from current xml stack
					case "tileset"
						//m.tilesets[tilesetIdx].images.insert(im)
						m.tilesets[tilesetIdx].image = im
					endcase
					case "imagelayer"
						m.imagelayers[imageLayerIdx].image = im
					endcase
				endselect
			elseif(ename = "layer")
				la.gen = _TmxParseGenericLayer(e[i].attributes)				
				la.height = _TmxParseAttrInt(e[i].attributes, "height", 0)
				la.width = _TmxParseAttrInt(e[i].attributes, "width", 0)				
				m.layers.insert(la)
				Inc layerIdx, 1
			elseif(ename = "data")
				select StaPeekByIdx(xsta, 2)
					case "layer"
						count = CountStringTokens(e[i].content, ",")
						for j = 1 to count
							valStr$ = GetStringToken(e[i].content, ",", j)
							valStr$ = TrimString(valStr$, WHITESPACES)
							value = Val(valStr$)
							m.layers[layerIdx].data.insert(Val(valStr$))
						next
					endcase
				endselect
				// other data than layer data is ignored
			elseif(ename = "objectgroup")
				og.gen = _TmxParseGenericLayer(e[i].attributes)
				og.color = _TmxParseColor(MapGet(e[i].attributes, "color"))
				// t = topdown, i = index
				og.draworder = left(_TmxParseAttrStr(e[i].attributes, "draworder", "t"),1) // t = topdown
				
				select StaPeekByIdx(xsta, 2) // previous item from stack
					case "map"
						m.objectgroups.insert(og)
						Inc objGroupIdx, 1
					endcase
					case "tile"
						m.tilesets[tilesetIdx].tiles[tileIdx].objectgroup = og
						Inc objGroupIdx, 1
					endcase

					/*
					case "tile"
						// TODO
					endcase
					*/
				endselect

			elseif(ename = "object")
				ob.id = Val(MapGet(e[i].attributes, "id"))
				ob.name = MapGet(e[i].attributes, "name")
				ob.otype = MapGet(e[i].attributes, "type")
				ob.x = ValFloat(MapGet(e[i].attributes, "x"))
				ob.y = ValFloat(MapGet(e[i].attributes, "y"))

				ob.width = _TmxParseAttrInt(e[i].attributes, "width", 0)
				ob.height = _TmxParseAttrInt(e[i].attributes, "height", 0)
				ob.rotation = _TmxParseAttrInt(e[i].attributes, "rotation", 0)
				ob.gid = _TmxParseAttrInt(e[i].attributes, "gid", 0)

				if _TmxParseAttrStr(e[i].attributes, "visible", "0") = "1" then ob.visible = TRUE else ob.visible = FALSE

				m.objectgroups[objGroupIdx].objects.insert(ob)
				Inc objIdx, 1
			elseif(ename = "property")
				// [map, tileset, layer, objectgroup, object] -> properties -> property

				// default type for property is string				
				if MapHasKey(e[i].attributes, "type") = FALSE then MapPut(e[i].attributes, "type", "string")
				
				key$ = MapGet(e[i].attributes, "name")
				value$ = MapGet(e[i].attributes, "value")
				type$ = MapGet(e[i].attributes, "type")
				
				select StaPeekByIdx(xsta, 3) // take 3rd top item from current xml stack
					case "map"
						TmxPropertiesPut(m.properties, key$, value$, type$)
					endcase
					case "tileset"						
						TmxPropertiesPut(m.tilesets[tilesetIdx].properties, key$, value$, type$)
					endcase
					case "layer"
						TmxPropertiesPut(m.layers[layerIdx].properties, key$, value$, type$)
					endcase
					case "imagelayer"
						TmxPropertiesPut(m.imagelayers[imageLayerIdx].properties, key$, value$, type$)
					endcase					
					case "objectgroup"
						select StaPeekByIdx(xsta, 4)
							case "map"
								TmxPropertiesPut(m.objectgroups[objGroupIdx].properties, key$, value$, type$)
							endcase
							case "tile"
								TmxPropertiesPut(m.tilesets[tilesetIdx].tiles[tileIdx].properties, key$, value$, type$)
							endcase
							case "terrain"
								TmxPropertiesPut(m.tilesets[tilesetIdx].terraintypes[terrainIdx].properties, key$, value$, type$)
							endcase
						endselect
					endcase
					case "object"
						TmxPropertiesPut(m.objectgroups[objGroupIdx].objects[objIdx].properties, key$, value$, type$)
					endcase
				endselect

			elseif(ename = "imagelayer")
				il.gen = _TmxParseGenericLayer(e[i].attributes)
				m.imagelayers.insert(il)
				Inc imageLayerIdx, 1
			elseif(ename = "group")
				/*
				 * A group layer, used to organize the layers of the map in a hierarchy. 
				 * Its attributes offsetx, offsety, opacity and visible recursively affect child layers.
				 */ 
 				warn(BACLOG, "groups are not supported")
			elseif(ename = "ellipse")
				sh.shapetype = "e"
				m.objectgroups[objGroupIdx].objects[objIdx].shape = sh
			elseif(ename = "polygon")
				sh.shapetype = "g"
				sh.points = _TmxParseShapePointData(e[i].content)
				m.objectgroups[objGroupIdx].objects[objIdx].shape = sh
			elseif(ename = "polyline")
				sh.shapetype = "l"
				sh.points = _TmxParseShapePointData(e[i].content)
				m.objectgroups[objGroupIdx].objects[objIdx].shape = sh
			elseif(ename = "terrain")
				te.name = _TmxParseAttrStr(e[i].attributes, "name", "")
				te.tile = _TmxParseAttrInt(e[i].attributes, "tile", 0)				
				m.tilesets[tilesetIdx].terraintypes.insert(te)
				Inc terrainIdx, 1
			elseif(ename = "text")
				txt as TmxText
				txt.fontfamily = _TmxParseAttrStr(e[i].attributes, "fontfamily", "sans-serif")
				txt.pixelsize = _TmxParseAttrInt(e[i].attributes, "pixelsize", 16)
				txt.wrapbool = _TmxParseBoolInt(e[i].attributes, "wrap", FALSE)
				txt.color = _TmxParseColor(_TmxParseAttrStr(e[i].attributes, "color", "#000000"))
				
				txt.boldbool = _TmxParseBoolInt(e[i].attributes, "bold", FALSE)
				txt.italicbool = _TmxParseBoolInt(e[i].attributes, "italic", FALSE)
				txt.underlinebool = _TmxParseBoolInt(e[i].attributes, "underline", FALSE)
				txt.strikeoutbool = _TmxParseBoolInt(e[i].attributes, "strikeout", FALSE)
				txt.kerningbool = _TmxParseBoolInt(e[i].attributes, "kerning", TRUE)
				
				txt.haling = left(_TmxParseAttrStr(e[i].attributes, "haling", "l"), 1) // default left = "l"
				txt.valing = left(_TmxParseAttrStr(e[i].attributes, "valing", "l"), 1) // default left = "l"

				m.objectgroups[objGroupIdx].objects[objIdx].text = txt
			endif

			// clean all
			sh.points.length = -1
			sh.shapetype = ""
			
			if(e[i].isSelfClosed = TRUE) then StaPop(xsta)
			
		elseif(e[i].isStartTag = FALSE)
			StaPop(xsta)
		endif
	next
	
	trace(BACLOG, TmxMap2XML(m))

endfunction m

