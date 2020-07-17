local push = table.insert
local tjoin = table.concat

local for_serialize = false
local quote_fmt = [["%s"]] 	-- for trace debug
if (for_serialize) then
	quote_fmt = "%q"	-- for serialize
end

local function mulstr(s, n)
	-- local arr = {}
	-- for i=1,n do
	-- 	push(arr, s)
	-- end
	-- return tjoin(arr) or ""
	return s:rep(n)
end

local function scan_table(t, name, indent, verbose)
	name = name or "__noname__"
	indent = indent or "  "

	local arr = {}
	local tmp = {}	-- accessed table

	local function v2s(v)
		local s = tostring(v)
		if (type(v) == "number")
			or (type(v) == "boolean") then
			return s
		end
		if type(v) == "function" then
			local info = debug.getinfo(v, "S")
			-- info.name is nil because o is not a calling level
			if info.what == "C" then
				return string.format("%q", s .. ", C function")
			else
			-- the information is defined through lines
				return string.format("%q", s .. ", defined in (" ..
					info.linedefined .. "-" .. info.lastlinedefined ..
					")" .. info.source)
			end
		end
		return string.format(quote_fmt, s)
	end

	local function isemptytable(t)
		-- counts the number of elements in a table by pairs or ipairs
		return next(t) == nil
	end

	local function itor(k, v, n, path)
		path = path or k
		n = n or 0

		local tv = type(v)
		local pfx = indent:rep(n)
		local sfx = verbose and " -- "..path or ""

		if (tv == "table") then
			if (tmp[v]) then
				push(arr, pfx..k.." = {} -- "..tmp[v])
			else
				tmp[v] = path

				if (isemptytable(v)) then
					push(arr, pfx..k.." = {};"..sfx)
				else
					push(arr, pfx..k.." = {"..sfx)
					local path2
					for k2, v2 in pairs(v) do
						k2 = ("[%s]"):format(v2s(k2))
						path2 = path..k2
						itor(k2, v2, n+1, path2)
					end
					push(arr, pfx.."}")
				end
			end
		else
			push(arr, pfx..k.." = "..v2s(v)..";"..sfx)
		end

	end
	-- update arr
	itor(name, t, 0)
	return arr;
end

function tprint(t, name, indent, verbose)
	local arr = scan_table(t, name, indent, verbose)
	for i, line in ipairs(arr) do
		print(line)
	end

	-- local str = tjoin(arr, '\n')
	-- print(string.sub(str, 1, 65535))
	return arr
end

local function print_table(t)
	print("---------<<<<<<<<", t)
	for k,v in pairs(t) do
		print(type(v), k, v)
	end
	print("--------->>>>>>>>", t)
end

local function print_userdata(v)
	print("<<<<<<<<---------", v)
	local t = getmetatable(v)
	print("[1] meta:", t)
	for k,v in pairs(t) do
		print(type(v), k, v)
	end
	if (t.__index) then
		print("[2] t.__index:", t.__index)
		for k,v in pairs(t.__index) do
			print(type(v), k, v)
		end
	end
	print("--------->>>>>>>>", t)
end

function print_ls(t)
	if (type(t) == "table") then
		return print_table(t) 
	end
	if (type(t) == "userdata") then
		return print_userdata(t)
	end
	return print_table(t) 
end

function t_ls(t)
	print_ls(t)
end

print("[require] tprint ............ ok")
return tprint

