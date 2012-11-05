term.clear()
term.setCursorPos(1, 1)
function loadfile(file)
	local fh = fs.open(file,"r")
	loadstring(fh.readAll(),file)()
	fh.close()
end
loadfile("libxml.lua")
local function split(str, pat)
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

local function num2hex(num)
    local hexstr = '0123456789abcdef'
    local s = ''
    while num > 0 do
        local mod = math.fmod(num, 16)
        s = string.sub(hexstr, mod+1, mod+1) .. s
        num = math.floor(num / 16)
    end
    if s == '' then s = '0' end
    return s
end


local function hexifiy(s)
	local r = ""
	for i=1, #s do
		local c = s:sub(i,i)
		local n = c:byte()
		local e = num2hex(n)
		r = r..e.." "
	end
	return r:sub(1,#r-1)
end

local function dehexifiy(s)
	local r = ""
	for match in s:gmatch("(%x+)") do
		local n = tonumber(match,16)
		if n ~= nil then
			r = r..string.char(n)
		end
	end
	return r
end

local function encodeIMG(list)
  local xml = libxml.load("xmlbase.xml")
  local fsEle = xml.filesystem
  local dEle = {}
  dEle[0] = fsEle

  --Directory Entry: D:id:name:parentid
  --File Entry: F:id:name:parentid:size:contents
  for i=1, #list.directory do
	local newDirectory = libxml.dom.createElement("directory")
	newDirectory.setAttribute("name", list.directory[i].name)
	newDirectory.setAttribute("id", i)
	newDirectory.setAttribute("pid", list.directory[i].pid)
    dEle[pid].appendChild(newDirectory)
	dEle[i+1] = newDirectory
  end
  for i=1, #list.file do
	local newFile = libxml.dom.createElement("file")
	newFile.setAttribute("name", list.file[i].name)
	newFile.setAttribute("id", i)
	newFile.setAttribute("pid",list.file[i].pid)
	newFile.setAttribute("size", list.file[i].size)
	newFile.setAttribute("content", hexifiy(list.file[i].content))
    dEle[pid].appendChild(newFile)
  end
  return xml
end

local function parseIMG(xml)
	local directory = {}
	local file = {}
	local cnode = xml.documentElement
	local dat = 0
	local run = true
	while run do
		for i, v in pairs(cnode.childNodes.nodes) do
			if string.lower(v.nodeName) == "directory" then
				local id = tonumber(v.getAttribute("id"))
				local name = v.getAttribute("name")
				local pid = tonumber(v.getAttribute("pid"))
				term.write(id..":"..name..":"..pid)
				directory[id] = {id=id,name=name,pid=pid,fullpath="",xml=v}
			elseif string.lower(v.nodeName) == "file" then
				term.write(v.nodeName)
				local id = tonumber(v.getAttribute("id"))
				term.write("id")
				local name = v.getAttribute("name")
				term.write("name")
				local pid = tonumber(v.getAttribute("pid"))
				term.write("pid")
				local size = tonumber(v.getAttribute("size"))
				term.write("size")
				local contents = dehexifiy(v.getAttribute("content"))
				term.write("dehexifiy")
				term.write(id..":"..name..":"..pid)
				file[id] = {id=id,name=name,pid=pid, size=size, content=contents,fullpath="",xml=v}
			end
		end
		dat = dat+1
		if directory[dat] == nil then
			run = false
		else
			cnode = directory[dat].xml
		end
	end
	for i, v in pairs(directory) do
		local parents = {}
		local path = "/"
		local at = v
		while true do
			if at ~= nil then
				path="/"..at.name..path
				at = directory[at.pid]
			else
				break
			end
		end
		v.fullpath = path:sub(1,#path-1)
	end
	for i, v in pairs(file) do
		local parents = {}
		local path = "/"
		local at = v
		while true do
			if at ~= nil then
				path="/"..at.name..path
				at = directory[at.pid]
			else
				break
			end
		end
		v.fullpath = path:sub(1,#path-1)
	end
	return {directory=directory,file=file}
end
--term.write("Looking inside BOOT.xfs for /boot, No Mount!\n")
if not fs.exists("BOOT.xfs") then
  term.write("BOOT.xfs Not Found!")
  --term.write("You can insert a boot disk for startup from that, or you can quit")
  while true do
    coroutine.yield()
  end
end
local parseddata = parseIMG(libxml.load("BOOT.xfs"))
for i, v in pairs(parseddata.file) do
  if v.fullpath == "/boot" then
    local s, e = pcall(function() assert(loadstring(v.content,"bootloader"))() end)
    if not s then
	term.clear()
	term.setCursorPos(1,1)
	term.write(e)
	while true do
		coroutine.yield()
	end
	end
    break
  end
end

while true do
	coroutine.yield()
end
