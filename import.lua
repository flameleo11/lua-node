local push = table.insert
local tjoin = table.concat

package._cache = package._cache or {}

------------------------------------------------------------
-- utils
------------------------------------------------------------

-- data | scripts main.lua
-- .. mylib/
-- step = 1
function concat_path(...)
  local arr = {...}
  return tjoin(arr, "/")
end

function str_split(str, sep)
  sep = sep or "%s"
  local pattern = ("([^%s]+)"):format(sep)
  -- print(pattern)
  local arr = {}
  for s in string.gmatch(str, pattern) do
    table.insert(arr, s)
  end
  return arr
end

------------------------------------------------------------
-- base
------------------------------------------------------------

local _print = function (...)
  local arr = {}
  for i,v in ipairs({...}) do
    push(arr, tostring(v))
  end
  return tjoin(arr, "  ")
end

local _err = function (...)
  local arr = {}
  for i,v in ipairs({...}) do
    -- todo nil str
    push(arr, tostring(v))
  end
  error(tjoin(arr, "  "), 2) 
end

local _f = function (f)
  return function (...)
    local args = {...}
    local ret = {}
    xpcall(function ()
      ret = { f(unpack(args)) }
    end, print)
    return unpack(ret)
  end
end

------------------------------------------------------------
-- api
------------------------------------------------------------

function CreateEnvWithModAPI(isworldgen)
  isworldgen = isworldgen or false

  local env = {
    -- lua
    pairs    = pairs,
    ipairs   = ipairs,
    print    = print,
    math     = math,
    table    = table,
    type     = type,
    string   = string,
    tostring = tostring,
    Class    = Class,
    -- runtime
    TUNING=TUNING,
    -- worldgen
    GROUND = GROUND,
    LOCKS = LOCKS,
    KEYS = KEYS,
    LEVELTYPE = LEVELTYPE,
    -- utility
    GLOBAL = _G,
    modname = "",
  }

  if isworldgen == false then
    env.CHARACTERLIST = GetActiveCharacterList()
  end

  env.env = env
  env.modimport = function(modulename) end

  local modutil = require("modutil")
  modutil.InsertPostInitFunctions(env, isworldgen, "myimport")

  return env
end

local function env_set_alias(env)
  env.push  = table.insert;
  env.pop   = table.remove;
  env.tjoin = table.concat;
end

------------------------------------------------------------
-- func
------------------------------------------------------------

function _resolveLookupPaths(filename)
  local pattern = "?.lua;?/index.lua;?/init.lua"
  local paths = str_split(string.gsub(pattern, "?", filename), ";")
  return paths
end

-- todo for itor
function _nodeModulePaths()
  -- from = from or "."
  local dirname = "node_modules"
  local paths = {
    concat_path(".", dirname);
    concat_path("..", dirname);
    concat_path("..", "..", dirname);
    concat_path("..", "..", "..", dirname);
    concat_path("..", "..", "..", "..", dirname);
  }
  -- local exist = fn_exists(path)
  return paths
end

function _resolveFilename(fillname, fn_exists)
  local dir_paths = _nodeModulePaths()
  local file_paths = _resolveLookupPaths(fillname)

  for i, dir in ipairs(dir_paths) do
    for j, filepath in ipairs(file_paths) do
      local path = concat_path(dir, filepath);
      local exist = fn_exists(path)
      if (exist) then
        return path
      end
    end
  end
  return nil;
end

------------------------------------------------------------
-- main
------------------------------------------------------------
local modenv1st = nil

--todo fix by my event dispatch api init
-- do not need modenv
local function get_mod_env(env, key)
  if not (modenv1st) then
    local mods = ModManager.mods
    if (mods and #mods > 0) then
      modenv1st = mods[1]
    end
  end
  if (modenv1st) then
    return rawget(modenv1st, key)
  end
  return rawget(env, key)
end

-- local modenv = CreateEnvWithModAPI(false)

local mt = {
  __index = function (t, key)
    return rawget(t, key)
     -- or get_mod_env(modenv, key)
     or rawget(_G, key);
  end
}

local _isfileexists = kleifileexists or function (fillname)
  local f = io.open(fillname)
  local exists = f and true or false
  if (f ~= nil) then
    io.close(f)
  end
  return exists
end

local _loadfile = kleiloadlua or function (filename)
  local fn, err = loadfile(filename);
  if (fn) then
    return fn
  end
  return err
end

local _load = function (modname, ...)
  if not (modname and #modname > 0) then
    _err("[error] import modname is ", modname)
  end

  local arr_lookup = {}
  local path = _resolveFilename(modname, 
    function (path)
      -- print(path)
      push(arr_lookup, path)
      return (_isfileexists(path) and true or false)
    end)
  if not (path) then
    tprint(arr_lookup)
    _err("[error] import not find src")
    return 
  end

  local fn = _loadfile(path)
  if not (fn and type(fn) == "function") then
    _err("import path", path, fn) 
  end

  local args = {...}
  args.n = #args
  args[0] = modname;

  local env = package._cache[modname]
  if (not env) then
    env = setmetatable({}, mt) 
  end

  env._err = _err;
  env._f = _f;
  env._path = path;
  env._M = env;
  env.arg = args;
  env_set_alias(env)

  setfenv(fn, env)
  local ret = {fn()}
  env._ret = ret;
  package._cache[modname] = env

  print("import", path)
  return unpack(ret)
end

reload = _f(_load);

function import(modname, ...)
  local env = package._cache[modname]
  if not (env) then
    return reload(modname, ...)
  end
  return unpack(env._ret or {})
end

function modget(modname)
  local env = package._cache[modname]
  if not (env) then
    reload(modname)
  end
  return env
end

function modset(modname, env)
  package._cache[modname] = env 
end


-- modset("t4", nil)
-- print(111, import("t4").gg)

print("[require] import ............ ok")

