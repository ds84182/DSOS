term.clear()
term.setCursorPos(1, 1)
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
local function encodeIMG(list)
  local ret = ""
  local numfile = #list.file
  local numdir = #list.directory
  local numentry = numfile+numdir
  local nl = "\n"
  ret = ret..numentry..nl
  --Directory Entry: D:id:name:parentid
  --File Entry: F:id:name:parentid:size:contents
  for i=0, numdir-1 do
    ret = ret.."D:"..(i+1)..":"..list.directory[i+1].name..":"..list.directory[i+1].pid..nl
  end
  for i=0, numfile-1 do
    ret = ret.."F:"..(i+1)..":"..list.file[i+1].name..":"..list.file[i+1].pid..":"..list.file[i+1].size..":"..list.file[i+1].content..nl
  end
  return ret
end

local function parseIMG(str)
	local splitstr = split(str, "\n")
	local numentry = tonumber(splitstr[1])
	local directory = {}
	local file = {}
	local i = 2
	local place = 1
	while #file+#directory~=numentry do
		if splitstr[i]:sub(1,1) == "D" then
			local s = split(splitstr[i],":")
			local id = tonumber(s[2])
			local name = s[3]
			local pid = tonumber(s[4])
			directory[id] = {id=id,name=name,pid=pid,fullpath=""}
		elseif splitstr[i]:sub(1,1) == "F" then
			local inside = 1
			local contents = ""
			local contentstart = 0
			local id = ""
			local pid = ""
			local name = ""
			local size = ""
			for r=3, #splitstr[i] do
				if inside == 1 then --ID--
					if splitstr[i]:sub(r,r) == ":" then
						id = tonumber(id)
						inside=2
					else
						id=id..splitstr[i]:sub(r,r)
					end
				elseif inside == 2 then --Name--
					if splitstr[i]:sub(r,r) == ":" then
						inside=3
					else
						name=name..splitstr[i]:sub(r,r)
					end
				elseif inside == 3 then --PID--
					if splitstr[i]:sub(r,r) == ":" then
						pid = tonumber(pid)
						inside=4
					else
						pid=pid..splitstr[i]:sub(r,r)
					end
				elseif inside == 4 then --Size--
					if splitstr[i]:sub(r,r) == ":" then
						size = tonumber(size)
						contentstart = r+1
						break
					else
						size=size..splitstr[i]:sub(r,r)
					end
				end
			end
			contents = str:sub(place+contentstart+1,place+contentstart+size+1)
			file[id] = {id=id,name=name,pid=pid, size=size, content=contents,fullpath=""}
		end
		place=place+#splitstr[i]+1
		i=i+1
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
--term.write("Looking inside BOOT.img for /boot, No Mount!\n")
if not fs.exists("BOOT.img") then
  term.write("BOOT.img Not Found!")
  term.write("You can insert a boot disk for startup from that, or you can quit")
  while true do
    coroutine.yield()
  end
end
local fh = fs.open("BOOT.img", "r")
--term.write("Parsing")
local parseddata = parseIMG(fh:readAll())
--term.write("Parsed")
fh:close()
for i, v in pairs(parseddata.file) do
  if v.fullpath == "/boot" then
    --term.write("Boot Found At "..v.id.."! Size:"..v.size.."\n")
    assert(loadstring(v.content,"bootloader"))()
    break
  end
end
