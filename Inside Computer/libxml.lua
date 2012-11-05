--local fsc = fs
--local fs = rfs or fs
-- Filename: libxml
-- Author: Regan Laitila
-- Date: N/A
-- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
libxml = {} -- :D
-- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
function libxml.init()

	-- SET COMMON CONFIGS
	libxml.require_path 		= "libxml."
	libxml.debug 				= false
end
-- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
function libxml.load(pObj)
	local parser = libxml.dom.createDomParser()
	local fh = fs.open(pObj,"r")
	local ret = fh.readAll()
	fh.close()
	return parser.parseFromString( ret )
end
-- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
function libxml.save(pDomObj, pFilePath)
	local xmltext 	= ""
	local indentc 	= 0
	local indent 	= function()
		local i = ""
		for a=1, indentc do
			i = i .. "	"
		end
		return i
	end
	recurseOutput = function(pDomNode)
		if pDomNode.nodeType == 1 or pDomNode.nodeType == 9 then
			local attrstring 	= ""
			local tagName		= tostring(libxml.trim(pDomNode.tagName))
			if pDomNode.hasAttributes() then
				attrstring = ""
				for a=1, pDomNode.attributes.length do
					attrstring = attrstring .. " " .. pDomNode.attributes[a].name .. "=\"" .. pDomNode.attributes[a].value .. "\""
				end
			end
			if pDomNode.isSelfClosing then
				xmltext = xmltext .. indent() .. "<" .. tagName .. attrstring .. " />\n"
			else
				xmltext = xmltext .. indent() .. "<" .. tagName .. attrstring .. ">\n"
			end
			if pDomNode.hasChildNodes() then
				indentc = indentc + 1
				for b=1, pDomNode.childNodes.length do
					recurseOutput(pDomNode.childNodes[b])
				end
				indentc = indentc -1
			end
			if pDomNode.isSelfClosing ~= true then
				xmltext = xmltext .. indent() .. "</" .. tagName .. ">\n"
			end
		elseif pDomNode.nodeType == 3 or pDomNode.nodeType == 4 then
			if pDomNode.nodeType == 3 then
				local text = pDomNode.data
				if text:len() > 20 then
					xmltext = xmltext .. indent() .. tostring(pDomNode.data) .. "\n"
				else
					xmltext = string.gsub(xmltext, "[\n]$", "")
					xmltext = xmltext .. libxml.trim(tostring(pDomNode.data))
				end
			elseif pDomNode.nodeType == 4 then
				local text = pDomNode.data
				if text:len() > 20 then
					xmltext = xmltext .. indent() ..  "<![CDATA[ \n" .. indent() .. tostring(pDomNode.data) .. "\n" .. indent() ..  "]]>\n"
				else
					xmltext = xmltext .. indent() .. "<![CDATA[ " .. tostring(pDomNode.data) .. " ]]>\n"
				end
			end
		end
	end
	recurseOutput(pDomObj.documentElement)
	if pFilePath ~= nil then
		local fh = fs.open(pFilePath,"w")
		fh.write(xmltext)
		fh.close()
	end
	return xmltext
end
-- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
function libxml.throw(pErrorType, pErrorText)
	local errorTypes = {}
	errorTypes[1] = "INFORMATION"
	errorTypes[2] = "WARNING"
	errorTypes[3] = "ERROR"
	errorTypes[4] = "FATAL ERROR"

	print("libxml::"..errorTypes[pErrorType] .. "::"..pErrorText)
end
-- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
function libxml.sleep(n)  -- seconds
	sleep(n)
end
-- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
function libxml.file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end
-- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
function libxml.trim(s)
	if s ~= nil then
		return s:match'^()%s*$' and '' or s:match'^%s*(.*%S)'
	end
end
-- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
-- tserial v1.23, a simple table serializer which turns tables into Lua script
-- by Taehl (SelfMadeSpirit@gmail.com)

-- Usage: table = libxml.tserial.unpack( libxml.tserial.pack(table) )
libxml.tserial = {}
function libxml.tserial.pack(t)
	assert(type(t) == "table", "Can only tserial.pack tables.")
	local s = "{"
	for k, v in pairs(t) do
		local tk, tv = type(k), type(v)
		if tk == "boolean" then k = k and "[true]" or "[false]"
		elseif tk == "string" then if string.find(k, "[%c%p%s]") then k = '["'..k..'"]' end
		elseif tk == "number" then k = "["..k.."]"
		elseif tk == "table" then k = "["..libxml.tserial.pack(k).."]"
		else error("Attempted to Tserialize a table with an invalid key: "..tostring(k))
		end
		if tv == "boolean" then v = v and "true" or "false"
		elseif tv == "string" then v = string.format("%q", v)
		elseif tv == "number" then	-- no change needed
		elseif tv == "table" then v = libxml.tserial.pack(v)
		else error("Attempted to Tserialize a table with an invalid value: "..tostring(v))
		end
		s = s..k.."="..v..","
	end
	return s.."}"
end

function libxml.tserial.unpack(s)
	assert(type(s) == "string", "Can only tserial.unpack strings.")
	assert(loadstring("libxml.tserial.table="..s))()
	local t = libxml.tserial.table
	libxml.tserial.table = nil
	return t
end
-- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
local Hex2Dec, BMOr, BMAnd, Dec2Hex
if(BinDecHex)then
	Hex2Dec, BMOr, BMAnd, Dec2Hex = BinDecHex.Hex2Dec, BinDecHex.BMOr, BinDecHex.BMAnd, BinDecHex.Dec2Hex
end

--- Returns a UUID/GUID in string format - this is a "random"-UUID/GUID at best or at least a fancy random string which looks like a UUID/GUID. - will use BinDecHex module if present to adhere to proper UUID/GUID format according to RFC4122v4.
--@Usage after require("UUID"), then UUID.UUID() will return a 36-character string with a new GUID/UUID.
--@Return String - new 36 character UUID/GUID-complient format according to RFC4122v4.
function libxml.UUID()
	local chars = {"0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"}
	local uuid = {[9]="-",[14]="-",[15]="4",[19]="-",[24]="-"}
	local r, index
	for i = 1,36 do
		if(uuid[i]==nil)then
			-- r = 0 | Math.random()*16;
			r = math.random (16)
			if(i == 20 and BinDecHex)then
				-- (r & 0x3) | 0x8
				index = tonumber(Hex2Dec(BMOr(BMAnd(Dec2Hex(r), Dec2Hex(3)), Dec2Hex(8))))
				if(index < 1 or index > 16)then
					print("WARNING Index-19:",index)
					return UUID() -- should never happen - just try again if it does ;-)
				end
			else
				index = r
			end
			uuid[i] = chars[index]
		end
	end
	return table.concat(uuid)
end
-- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
function libxml.literalize(str)
    text, occur =  str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", function(c)
		return "%" .. c
	end)
	return libxml.trim(text)
end
-- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
function libxml.split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
	 table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end
-- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
function libxml.trace (event, line, delay)
	local a = debug.getinfo(2).name
	local b = debug.getinfo(2).source
	print(tostring(a) .. ":::" .. tostring(b))
	libxml.sleep(delay or .05)
end
-- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
libxml.init()

libxml.dom = {}
-- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
function libxml.dom.init()
	-- NODE TYPE DEFINITIONS
	libxml.dom.nodeTypes 		= {}
	libxml.dom.nodeTypes[1]		=  "ELEMENT_NODE"
	libxml.dom.nodeTypes[2]		=  "ATTRIBUTE_NODE"
	libxml.dom.nodeTypes[3]		=  "TEXT_NODE"
	libxml.dom.nodeTypes[4]		=  "CDATA_SECTION_NODE"
	libxml.dom.nodeTypes[5]		=  "ENTITY_REFERENCE_NODE"
	libxml.dom.nodeTypes[6]		=  "ENTITY_NODE"
	libxml.dom.nodeTypes[7]		=  "PROCESSING_INSTRUCTION_NODE"
	libxml.dom.nodeTypes[8]		=  "COMMENT_NODE"
	libxml.dom.nodeTypes[9]		=  "DOCUMENT_NODE"
	libxml.dom.nodeTypes[10]	=  "DOCUMENT_TYPE_NODE"
	libxml.dom.nodeTypes[11]	=  "DOCUMENT_FRAGMENT_NODE"
	libxml.dom.nodeTypes[12]	=  "NOTATION_NODE"
	libxml.dom.nodeTypes[13]	=  "NODE_LIST"

	-- DOM DEPENDENCIES
	function libxml.dom.createDocument()
		local self = libxml.dom.createNode(9)

		--===================================================================
		-- PROPERTIES                                                       =
		--===================================================================
		self.nodeName 			= "#document"
		---------------------------------------------------------------------

		--===================================================================
		-- MUTATORS                                                         =
		--===================================================================
		self.mutators.getDocumentElement = function()
			return self.firstChild
		end
		---------------------------------------------------------------------

		--====================================================================
		-- METHODS	                                                         =
		--====================================================================
		self.createElement 		= function(pTagName)
			local elementNodeObj = libxml.dom.createElementNodeObj(pTagName)
			return elementNodeObj
		end
		---------------------------------------------------------------------
		self.createAttribute 	= function(pAttributeName)
			local attributeNode = libxml.dom.createAttributeNodeObj(pAttributeName)
			return attributeNode
		end
		---------------------------------------------------------------------
		self.createTextNode  	= function(pText)
			local textNode = libxml.dom.createTextNodeObj(pText)
			return textNode
		end
		---------------------------------------------------------------------
		self.createCDATASection = function(pCDATAText)
			local CDATASectionNode = libxml.dom.createCharacterDataNodeObj(pCDATAText)
			return CDATASectionNode
		end
		---------------------------------------------------------------------
		self.createComment 		= function(pCommentText)
			local commentNode = libxml.dom.createCommentNodeObj(pCommentText)
			return commentNode
		end
		---------------------------------------------------------------------

		return self
	end
	-- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
	function libxml.dom.createNode(pNodeType)
		local self = {}

		--===================================================================
		-- OBJECT METATABLE                                                 =
		--===================================================================
		local self_mt = {}
		---------------------------------------------------------------------
		self_mt.__tostring = function(t)
			return "[object]:" .. tostring(self.nodeDesc)
		end
		---------------------------------------------------------------------
		self_mt.__index = function(t,k)
			local mutatorfound = false
			--print(rawget(t,k))

			if rawget(t,k) == nil then
				-- loop through the mutators table to see if we can match a getter
				for i,v in pairs( t.mutators ) do
					--print(i)
					if type(k) == "string" then
						if ("GET"..k:upper()) == i:upper() then
							--print("match")
							return t.mutators[i]()
						end
					end
				end

				--search dom path. ex: node.child.children[3]
				if rawget(t, "nodeType") ~= nil then
					if rawget(t, "nodeType") == 1 or rawget(t, "nodeType") == 9 then
						return libxml.dom.searchDomPath(t, k)
					end
				end
			else
				--if no mutator found, simply return the rawget key
				return rawget(t,k)
			end
		end
		---------------------------------------------------------------------
		self_mt.__newindex = function(t,k,v)
			local mutatorfound = false
			local mutatorkey = "SET"..k:upper()
			--print(k)
			if rawget(t, "mutators") then
				-- loop through the mutators table to see if we can match a setter
				for key in pairs(t.mutators) do
					if key:upper() == mutatorkey then
						t.mutators[key](v)
						mutatorfound = true
					end
				end
			end
			--if no mutator found, simply rawset the key and value
			if mutatorfound == false then
				rawset(t,k,v)
			end
		end
		---------------------------------------------------------------------

		--===================================================================
		-- PROPERTIES                                                       =
		--===================================================================
		self.nodeType 		= pNodeType
		---------------------------------------------------------------------
		self.nodeDesc		= libxml.dom.nodeTypes[pNodeType]
		---------------------------------------------------------------------
		self.attributes 	= libxml.dom.createNamedNodeMapObj()
		---------------------------------------------------------------------
		self.childNodes 	= libxml.dom.createNodeList()
		---------------------------------------------------------------------
		self.parentNode 	= nil
		---------------------------------------------------------------------

		--===================================================================
		-- MUTATORS                                                         =
		--===================================================================
		self.mutators = {}
		---------------------------------------------------------------------
		self.mutators.getId = function()
			return self.getAttribute("id")
		end
		---------------------------------------------------------------------
		self.mutators.getFirstChild = function()
			if self.hasChildNodes() then
				return self.childNodes[1]
			else
				return nil
			end
		end
		---------------------------------------------------------------------
		self.mutators.getLastChild = function()
			if self.hasChildNodes() then
				return self.childNodes[self.childNodes.length]
			else
				return nil
			end
		end
		---------------------------------------------------------------------
		self.mutators.getPreviousSibling = function()
			if self.parentNode ~= nil then
				if self.parentNode.hasChildNodes() then
					for i=1, self.parentNode.childNodes.length do
						if self == self.parentNode.childNodes[i] and i > 1 then
							return self.parentNode.childNodes[i-1]
						elseif i == self.parentNode.childNodes.length then
							return nil
						end
					end
				else
					return nil
				end
			else
				return nil
			end
		end
		---------------------------------------------------------------------
		self.mutators.getNextSibling = function()
			if self.parentNode ~= nil then
				if self.parentNode.hasChildNodes() then
					for i=1, self.parentNode.childNodes.length do
						if self == self.parentNode.childNodes[i] then
							return self.parentNode.childNodes[i+1]
						elseif i == self.parentNode.childNodes.length then
							return nil
						end
					end
				else
					return nil
				end
			else
				return nil
			end
		end
		---------------------------------------------------------------------
		self.mutators.getOwnerDocument = function()
			return libxml.document.firstChild
		end
		---------------------------------------------------------------------
		self.mutators.setId = function(pId)
			self.setAttribute('id', pId)
		end
		---------------------------------------------------------------------

		--====================================================================
		-- METHODS	                                                         =
		--====================================================================
		self.appendChild = function(pNodeObj)
			local newNode = self.childNodes.addItem(pNodeObj)
			newNode.parentNode = self

			libxml.dom.hasChanged = true
			return newNode
		end
		---------------------------------------------------------------------
		self.removeChild = function(pNodeObj)
			local removedNode = self.childNodes.removeItem(pNodeObj)

			libxml.dom.hasChanged = true
			return removedNode
		end
		---------------------------------------------------------------------
		self.setAttribute = function(pAttributeName, pAttributeValue)
			local attribute = libxml.dom.createAttribute(pAttributeName, pAttributeValue)
			self.attributes.setNamedItem(attribute)

			libxml.dom.hasChanged = true
		end
		---------------------------------------------------------------------
		self.removeAttribute = function(pAttributeName)
			local attribute = self.attributes.removeNamedItem(self.attributes.getNamedItem(pAttributeName).nodeName)

			libxml.dom.hasChanged = true
			return attribute
		end
		---------------------------------------------------------------------
		self.getAttribute = function(pAttributeName)
			if self.attributes ~= nil then
				local attribute = self.attributes.getNamedItem(pAttributeName)
				if attribute == nil then
					return nil
				else
					return attribute.nodeValue
				end
			else
				return nil
			end
		end
		---------------------------------------------------------------------
		self.hasChildNodes = function()
			if self.childNodes ~= nil and self.childNodes.length >= 1 then
				return true
			else
				return false
			end
		end
		---------------------------------------------------------------------
		self.hasAttributes = function()
			if self.attributes ~= nil and self.attributes.length > 0 then
				return true
			else
				return false
			end
		end
		---------------------------------------------------------------------
		self.hasAttribute = function( pAttribute )
			local response = self.getAttribute(pAttribute)
			if response ~= nil then
				return true
			else
				return false
			end
		end
		---------------------------------------------------------------------
		self.hasClass = function( pClass )
			local classes = libxml.split( self.getAttribute("class") or "", "%s" )
			for a=1, table.getn(classes) do
				if pClass == classes[a] then
					return true
				end
			end
			return false
		end
		---------------------------------------------------------------------
		self.getElementById = function(pId)
			return libxml.dom.getElementById(self, pId)
		end
		---------------------------------------------------------------------
		self.getElementsByTagName = function(pTagName)
			return libxml.dom.getElementsByTagName(self, pTagName)
		end
		---------------------------------------------------------------------
		self.getElementsByClassName = function(pClassName)
			return libxml.dom.getElementsByClassName(self, pClassName)
		end
		---------------------------------------------------------------------
		self.replaceChild = function(pNewNode, pOldNode)
			libxml.dom.hasChanged = true
		end
		---------------------------------------------------------------------
		self.isEqualNode = function(pCompareNode)
		end
		---------------------------------------------------------------------
		self.isSameNode = function(pCompareNode)
			if self == pCompareNode then
				return true
			else
				return false
			end
		end
		---------------------------------------------------------------------

		setmetatable(self, self_mt)
		return self
	end
	-- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
	function libxml.dom.createNodeList()
		local self = {}
		local self_mt = {}
		setmetatable(self, self_mt)

		-- PROPERTIES -------------------------------------------------------
		self.nodes 		= {}
		self.length 	= table.getn(self.nodes)
		self.nodeType 	= 13
		---------------------------------------------------------------------

		-- METHODS ----------------------------------------------------------
		self_mt.__index = function(t, k)
			if type(k) == "number" then
				return self.item(k)
			else
				return self.nodes
			end
		end
		self_mt.__tostring = function(t)
			return "[object]:NodeList"
		end
		---------------------------------------------------------------------
		self.item = function(pIndex)
			return self.nodes[pIndex]
		end
		---------------------------------------------------------------------
		self.addItem = function(pNodeObj, pIndex)
			if pIndex ~= nil and type(pIndex) == "number" then
				table.insert(self.nodes, pIndex, pNodeObj)
			else
				table.insert(self.nodes, pNodeObj)
			end
			self.length = self.length + 1
			return pNodeObj
		end
		---------------------------------------------------------------------
		self.removeItem = function(pNodeObj)
			if self.length > 0 then
				for k, v in ipairs(self.nodes) do
					if self.nodes[k] == pNodeObj then
						local oldNode = self.nodes[k]
						table.remove(self.nodes, k)
						self.length = self.length - 1
						return oldNode
					end
				end
			end
		end
		---------------------------------------------------------------------
		return self
	end
	function libxml.dom.createNamedNodeMapObj()
		local self = {}
		local cnnmo_mt = {}

		--===================================================================
		-- PROPERTIES                                                       =
		--===================================================================
		self.nodes 	= {}
		---------------------------------------------------------------------
		self.length = table.getn(self.nodes)
		---------------------------------------------------------------------

		--===================================================================
		-- OBJECT METATABLE                                                 =
		--===================================================================
		cnnmo_mt.__index = function(t, k)
			if type(k) == "number" then
				return self.nodes[k]
			elseif type(k) == "string" then
				for i, v in ipairs(self.nodes) do
					if self.nodes[i].nodeName == k then
						return self.nodes[i]
					end
				end
			else
				return nil
			end
		end
		---------------------------------------------------------------------
		cnnmo_mt.__tostring = function(t)
			return "[object]:NamedNodeMap"
		end
		---------------------------------------------------------------------

		--====================================================================
		-- METHODS	                                                         =
		--====================================================================
		self.setNamedItem = function(pNode, pIndex)
			if self.length == 0 then
				table.insert(self.nodes, pNode)
				self.length = table.getn(self.nodes)
				return pNode
			elseif self.length > 0 then
				for i, v in ipairs(self.nodes) do
					if self.nodes[i].nodeName == pNode.nodeName then
						self.nodes[i] = pNode
						return pNode
					else
						local oldNode = self.nodes[i]
						table.insert(self.nodes, pNode)
						self.length = table.getn(self.nodes)
						return oldNode
					end
				end
			end
		end
		---------------------------------------------------------------------
		self.getNamedItem = function(pName)
			local returnvalue = nil
			for k, v in ipairs(self.nodes) do
				if self.nodes[k].nodeName == pName then
					returnvalue = self.nodes[k]
				end
			end
			return returnvalue
		end
		---------------------------------------------------------------------
		self.removeNamedItem = function(pName)
			if self.length > 0 then
				for k, v in ipairs(self.nodes) do
					if self.nodes[k].nodeName == pName then
						local oldNode = self.nodes[k]
						table.remove(self.nodes, k)
						self.length = self.length - 1
						return oldNode
					end
				end
			end
		end
		---------------------------------------------------------------------
		self.item = function(pIndex)
			if self.length > 0 then
				return self.nodes[pIndex]
			else
				return nil
			end
		end
		---------------------------------------------------------------------

		setmetatable(self, cnnmo_mt)
		return self
	end
	-- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
	function libxml.dom.createDomParser()
		local self = {}

		--===================================================================
		-- PROPERTIES                                                       =
		--===================================================================
		self.parsedebug 				= false
		---------------------------------------------------------------------
		self.srcText					= nil
		---------------------------------------------------------------------
		self.openNodes	 				= {}
		---------------------------------------------------------------------
		self.lastNodeReference 			= nil
		---------------------------------------------------------------------
		self.textNodeCharBuffer 		= nil
		---------------------------------------------------------------------
		self.document					= libxml.dom.createDocument()
		---------------------------------------------------------------------

		--====================================================================
		-- METHODS	                                                         =
		--====================================================================
		self.parseFromString = function(pSrcText)
			local index = 1
			local char = function(charIndex) return  self.srcText:sub(charIndex,charIndex) end
			self.srcText = string.gsub(pSrcText, "[\t]", "")
			--self.srcText = string.gsub(pSrcText, "[\r\n]", "")
			while index <= self.srcText:len() do
				if char(index) == "<" then
					if textNodeCharBuffer ~= nil then
						self.openNode(index, "text")
					elseif char(index + 1) == "/" then
						index = self.closeNode(index)
					elseif self.srcText:sub(index+1, index+3) == "!--" then
						index = self.openNode(index, "comment")
					elseif self.srcText:sub(index+1, index+8) == "![CDATA[" then
						index = self.openNode(index, "CDATASection")
					else
						index = self.openNode(index, "tag")
					end
				else
					if textNodeCharBuffer == nil then textNodeCharBuffer = "" end
					textNodeCharBuffer = textNodeCharBuffer .. char(index)
					index = index +1
				end
			end

			return self.document
		end
		---------------------------------------------------------------------
		self.openNode = function(pIndex, pType)
			local nI = nil --nodeIndex
			local rI = pIndex --returnIndex
			-----------------------------------------------------------------
			if pType == "tag" then
				local tagContent = string.match(self.srcText, "<(.-)>", pIndex)
				local tagName = libxml.trim(string.match(tagContent, "([%a%d]+)%s?", 1))

				table.insert(self.openNodes, libxml.dom.createElement(tagName))
				nI = table.getn(self.openNodes)

				-- get attributes from tagContent
				for matchedAttr in string.gmatch(string.sub(tagContent,tagName:len()+1), "(.-=\".-\")") do
					for attr, value in string.gmatch(matchedAttr, "(.-)=\"(.-)\"") do
						self.openNodes[nI].setAttribute(libxml.trim(attr), libxml.trim(value))
					end
				end

				-- append new node to document
				if nI == 1 then
					lastNodeReference = self.document.appendChild(self.openNodes[nI])
				else
					lastNodeReference = lastNodeReference.appendChild(self.openNodes[nI])
				end

				-- check to see if the tag is self closing, else check against self.selfCloseElements
				if string.match(tagContent, "/$") then
					self.openNodes[nI].isSelfClosing = true
					self.closeNode(pIndex)
					nI = table.getn(self.openNodes)
				end

				rI = rI + string.match(self.srcText, "(<.->)", pIndex):len()

				return rI
			-----------------------------------------------------------------
			elseif pType == "comment" then
				local commentText = string.match(self.srcText, "<!%-%-(.-)%-%->", pIndex)
				local newTextNode =
				lastNodeReference.appendChild(libxml.dom.createCommentNodeObj(libxml.trim(commentText)))
				rI = pIndex + string.match(self.srcText, "(<!%-%-.-%-%->)", pIndex):len()
				return rI
			-----------------------------------------------------------------
			elseif pType == "text" then
				local text = libxml.trim(textNodeCharBuffer)
				if text ~= "" then
					lastNodeReference.appendChild(libxml.dom.createText(text))
				end
				textNodeCharBuffer = nil
			-----------------------------------------------------------------
			elseif pType == "CDATASection" then
				local cdataText = string.match(self.srcText, "<!%[CDATA%[(.-)%]%]>", pIndex)
				local newNode = libxml.dom.createCharacterData(cdataText)
				lastNodeReference.appendChild(newNode)
				return pIndex + string.match(self.srcText, "(<!%[CDATA%[.-%]%]>)", pIndex):len()
			end
			-----------------------------------------------------------------
		end
		---------------------------------------------------------------------
		self.closeNode = function(pIndex)
			local tagname = libxml.trim(string.match(self.srcText, "/?([%a%d]+)%s?", pIndex))
			local nI = table.getn(self.openNodes)
			if libxml.trim(self.openNodes[nI].tagName:upper()) == libxml.trim(tagname):upper() then
				table.remove(self.openNodes, table.getn(self.openNodes))
				lastNodeReference = lastNodeReference.parentNode
			end
			return pIndex + string.match(self.srcText, "(<.->)", pIndex):len()
		end
		---------------------------------------------------------------------

		return self
	end

	-- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
	function libxml.dom.createElement(pTagName)
		local tagName = libxml.trim(pTagName:lower())
		self = libxml.dom.createNode(1)

		--===================================================================
		-- PROPERTIES                                                       =
		--===================================================================
		self.nodeName 		= string.upper(pTagName)
		---------------------------------------------------------------------
		self.tagName 		= libxml.trim(pTagName)
		---------------------------------------------------------------------
		self.isSelfClosing 	= false
		---------------------------------------------------------------------

		return self
	end
	function libxml.dom.createAttribute(pAttributeName, pAttributeValue)
		local self = libxml.dom.createNode(2)

		--===================================================================
		-- PROPERTIES                                                       =
		--===================================================================
		self.nodeName 	= pAttributeName
		---------------------------------------------------------------------
		self.nodeValue 	= pAttributeValue
		---------------------------------------------------------------------
		self.attributes = nil --property not allowed
		---------------------------------------------------------------------
		self.parentNode = nil --property not allowed
		---------------------------------------------------------------------
		self.childNodes = nil --property not allowed
		---------------------------------------------------------------------

		--===================================================================
		-- MUTATORS                                                         =
		--===================================================================
		self.mutators.getName = function()
			return self.nodeName
		end
		---------------------------------------------------------------------
		self.mutators.getValue = function()
			return self.nodeValue
		end
		---------------------------------------------------------------------
		self.mutators.getId					= nil --mutator not allowed
		---------------------------------------------------------------------
		self.mutators.getClass				= nil --mutator not allowed
		---------------------------------------------------------------------
		self.mutators.getFirstChild 		= nil --mutator not allowed
		---------------------------------------------------------------------
		self.mutators.getLastChild			= nil --mutator not allowed
		---------------------------------------------------------------------
		self.mutators.getNextSibling 		= nil --mutator not allowed
		---------------------------------------------------------------------
		self.mutators.getPreviousSilbing 	= nil --mutator not allowed
		---------------------------------------------------------------------
		self.mutators.setId					= nil --mutator not allowed
		---------------------------------------------------------------------
		self.mutators.setClass				= nil --mutator not allowed
		---------------------------------------------------------------------


		--===================================================================
		-- METHODS	                                                        =
		--===================================================================
		self.appendChild 			= nil --method not allowed
		---------------------------------------------------------------------
		self.getElementById 		= nil --method not allowed
		---------------------------------------------------------------------
		self.getElementsByTagName 	= nil --method not allowed
		---------------------------------------------------------------------
		self.getElementsByClassName = nil --method not allowed
		---------------------------------------------------------------------
		self.removeChild 			= nil --method not allowed
		---------------------------------------------------------------------
		self.setAttribute			= nil --method not allowed
		---------------------------------------------------------------------
		self.getAttribute 			= nil --method not allowed
		---------------------------------------------------------------------
		self.removeAttribute 		= nil --method not allowed
		---------------------------------------------------------------------
		self.hasChildNodes 			= nil --method not allowed
		---------------------------------------------------------------------
		self.hasAttributes 			= nil --method not allowed
		---------------------------------------------------------------------
		self.replaceChild 			= nil --method not allowed
		---------------------------------------------------------------------
		self.isEqualNode 			= nil --method not allowed
		---------------------------------------------------------------------
		self.isSameNode 			= nil --method not allowed
		---------------------------------------------------------------------

		return self
	end
	function libxml.dom.createCharacterData(pData)
		--INHERIT FROM DOM NODE
		local self = libxml.dom.createNode(4)

		--===================================================================
		-- PROPERTIES                                                       =
		--===================================================================
		self.nodeName 	= "#CDATASECTION"
		---------------------------------------------------------------------
		self.nodeValue 	= pData
		---------------------------------------------------------------------
		self.attributes = nil --property not allowed
		---------------------------------------------------------------------
		self.parentNode = nil --property not allowed
		---------------------------------------------------------------------
		self.childNodes = nil --property not allowed
		---------------------------------------------------------------------

		--===================================================================
		-- MUTATORS                                                         =
		--===================================================================
		self.mutators.getData = function()
			return self.nodeValue
		end
		---------------------------------------------------------------------
		self.mutators.getLength = function()
			return self.nodeValue:len()
		end
		---------------------------------------------------------------------
		self.mutators.setData = function(pText)
			self.nodeValue = pText
		end
		self.mutators.setLength = function()
			return "libxml ERROR:: You cannot set the lengh property"
		end
		---------------------------------------------------------------------
		self.mutators.getId					= nil --mutator not allowed
		---------------------------------------------------------------------
		self.mutators.getClass				= nil --mutator not allowed
		---------------------------------------------------------------------
		self.mutators.getFirstChild 		= nil --mutator not allowed
		---------------------------------------------------------------------
		self.mutators.getLastChild			= nil --mutator not allowed
		---------------------------------------------------------------------
		self.mutators.getNextSibling 		= nil --mutator not allowed
		---------------------------------------------------------------------
		self.mutators.getPreviousSilbing 	= nil --mutator not allowed
		---------------------------------------------------------------------
		self.mutators.setId					= nil --mutator not allowed
		---------------------------------------------------------------------
		self.mutators.setClass				= nil --mutator not allowed
		---------------------------------------------------------------------

		--===================================================================
		-- METHODS	                                                        =
		--===================================================================
		self.appendData = function(pString)
			if type(pString) == "string" then
				self.nodeValue = self.nodeValue + pString
			else
				print("libxml:ERROR: appendData only accepts parameter of type 'string'")
			end
		end
		---------------------------------------------------------------------
		self.deleteData = function(pStart, pLength)
		end
		---------------------------------------------------------------------
		self.appendChild 			= nil --method not allowed
		---------------------------------------------------------------------
		self.getElementById 		= nil --method not allowed
		---------------------------------------------------------------------
		self.getElementsByTagName 	= nil --method not allowed
		---------------------------------------------------------------------
		self.getElementsByClassName = nil --method not allowed
		---------------------------------------------------------------------
		self.removeChild 			= nil --method not allowed
		---------------------------------------------------------------------
		self.setAttribute			= nil --method not allowed
		---------------------------------------------------------------------
		self.getAttribute 			= nil --method not allowed
		---------------------------------------------------------------------
		self.removeAttribute 		= nil --method not allowed
		---------------------------------------------------------------------
		self.hasChildNodes 			= function() return false end
		---------------------------------------------------------------------
		self.hasAttributes 			= function() return false end
		---------------------------------------------------------------------
		self.replaceChild 			= nil --method not allowed
		---------------------------------------------------------------------
		self.isEqualNode 			= nil --method not allowed
		---------------------------------------------------------------------
		self.isSameNode 			= nil --method not allowed
		---------------------------------------------------------------------

		return self
	end
	function libxml.dom.createText(pText)
		local self = libxml.dom.createCharacterData(pText)

		--===================================================================
		-- PROPERTIES                                                       =
		--===================================================================
		self.nodeName = "#text"
		---------------------------------------------------------------------
		self.nodeType = 3
		---------------------------------------------------------------------
		self.nodeDesc = libxml.dom.nodeTypes[3]
		---------------------------------------------------------------------

		--===================================================================
		-- MUTATORS                                                         =
		--===================================================================

		--===================================================================
		-- METHODS	                                                        =
		--===================================================================

		return self
	end
	function libxml.dom.createCommentNodeObj(pText)
		local self = libxml.dom.createCharacterDataNodeObj(pText)

		--===================================================================
		-- PROPERTIES                                                       =
		--===================================================================
		self.nodeName = "#comment"
		---------------------------------------------------------------------

		--===================================================================
		-- MUTATORS                                                         =
		--===================================================================

		--===================================================================
		-- METHODS	                                                        =
		--===================================================================

		return self
	end
end
-- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
function libxml.dom.domTreeDump(pRootDomNode)
	local indent = "--"
	local indent_count = 0

	libxml.throw(1, "calling libxml.dom.domTreeDump()")
	print("-----------------------------------------")
	recurseOutput = function(pDomNode)
		local curr_indent = ""
		for a=1, indent_count do curr_indent = curr_indent .. indent end

		print(curr_indent .. tostring(pDomNode.nodeDesc))
		if pDomNode.hasChildNodes() then
			indent_count = indent_count + 1
			for b=1, pDomNode.childNodes.length do
				recurseOutput(pDomNode.childNodes[b])
			end
			indent_count = indent_count - 1
		end
	end
	recurseOutput(pRootDomNode)
	print("-----------------------------------------")
end
-- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
function libxml.dom.searchDomPath(pObjRef, pTagName)
	local self = pObjRef
	local tag  = pTagName
	local nodeCollec = libxml.dom.createNodeList()

	if self.nodeType == 1 or self.nodeType == 9 then
		if self.hasChildNodes() then
			for a=1, self.childNodes.length do
				local child = self.childNodes[a]
				--print(a .. " searching ".. tostring(child).. " for ".. tostring(tag) .."")
				if child.tagName == tag then
					--print("tag match!")
					nodeCollec.addItem(child)
				end
			end
		end
	end

	if #nodeCollec.nodes > 1 then
		return nodeCollec
	elseif #nodeCollec.nodes == 1 then
		return nodeCollec[1]
	else
		libxml.throw(3, "libxml.dom.searchDomPath()::No node with tagName: " .. tostring(tag))
		return libxml.dom.createNode(1)
	end
end
-- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
function libxml.dom.searchDomXPath(pXPath)
end
-- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
function libxml.dom.getAllElements(pObjRef)
	local self = pObjRef
	local returnList = libxml.dom.createNodeList()

	recurse = function(pSearchNode)
		if pSearchNode.nodeType == 1 then returnList.addItem( pSearchNode ) end
		if pSearchNode.hasChildNodes() then
			for a=1, pSearchNode.childNodes.length do
				recurse(pSearchNode.childNodes[a])
			end
		end
	end
	recurse(self)
	return returnList
end
-- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
function libxml.dom.getElementById(pObjRef, pId)
	local self = pObjRef
	local returnnode = nil
	local stopsearch = false
	local checkId = nil
	local search = {}
	search = function(pSearchNode, pSearchId)
		if stopsearch == false then
			if self.getAttribute ~= nil then
				checkId = pSearchNode.getAttribute("id")
			end
			if checkId ~= nil and checkId == pSearchId  then
				returnnode = pSearchNode
				stopsearch = true
			else
				if pSearchNode.hasChildNodes() then
					for i=1, pSearchNode.childNodes.length do
						if pSearchNode.childNodes[i].getAttribute ~= nil then
							search(pSearchNode.childNodes[i], pId)
						end
					end
				end
			end
		end
	end
	search(self, pId)
	return returnnode
end
-- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
function libxml.dom.getElementsByTagName(pObjRef, pTagName)
	local self 				= pObjRef
	local returnnodelist 	= libxml.dom.createNodeList()
	local stopsearch 		= false
	local checkTag 			= nil
	local search 			= {}

	search = function(pSearchNode, pSearchTag)
		if pSearchNode ~= nil then
			if pSearchNode.tagName ~= nil then
				checkTag = pSearchNode.tagName
				if checkTag ~= nil and checkTag == pSearchTag  then
					returnnodelist.addItem(pSearchNode)
				end
			end
			if pSearchNode.hasChildNodes ~= nil then
				if pSearchNode.hasChildNodes() then
					for i=1, pSearchNode.childNodes.length do
						search(pSearchNode.childNodes[i], pTagName)
					end
				end
			end
		end
	end
	search(self, pTagName)

	return returnnodelist
end
-- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
function libxml.dom.getElementsByClassName(pObjRef, pClassName)
	local self = pObjRef
	local returnnodelist = libxml.dom.createNodeList()
	local stopsearch = false
	local checkClass = nil
	local search = {}
	search = function(pSearchNode, pSearchClass)
		if stopsearch == false then
			if pSearchNode.getAttribute ~= nil then
				checkClass = pSearchNode.getAttribute("class")
				if checkClass ~= nil then
					for class in string.gmatch(checkClass, "[%a%d]+") do
						if class ~= nil and libxml.trim(class) == libxml.trim(pSearchClass)  then
							returnnodelist.addItem(pSearchNode)
						end
					end
				end
			end
			if pSearchNode.hasChildNodes() then
				for i=1, pSearchNode.childNodes.length do
					search(pSearchNode.childNodes[i], pClassName)
				end
			end
		end
	end
	search(self, pClassName)
	return returnnodelist
end
-- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
function libxml.dom.getElementsByAttributeName( pObjRef, pAttrName )
	local self = pObjRef
	local returnnodelist = libxml.dom.createNodeList()
	local stopsearch = false
	local checkAttr = nil
	local search = {}
	search = function(pSearchNode, pSearchAttr)
		if stopsearch == false then
			if pSearchNode.getAttribute ~= nil then
				checkAttr = pSearchNode.getAttribute(pAttrName)
				if checkAttr ~= nil  then
					returnnodelist.addItem(pSearchNode)
				end
			end

			if pSearchNode.hasChildNodes() then
				for i=1, pSearchNode.childNodes.length do
					search(pSearchNode.childNodes[i], pAttrName)
				end
			end
		end
	end
	search(self, pAttrName)
	return returnnodelist
end
-- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
libxml.dom.init()
--fs = rfs
