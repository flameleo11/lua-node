local Emitter = require('Emitter')
local events = require('events')
local push = table.insert

local EventProxy = {}

setmetatable(EventProxy, {
    __call = function (_, ...) 
        return EventProxy.new(...) 
    end
})

function EventProxy.new()
  local obj = {}
  local meta_obj = {
    __index = function (t, k)
      local v = EventProxy[k]
      if (type(v) == "function") then
        local warpper = function (...)
          return v(obj, ...)
        end
        return warpper;
      end
      return v
    end
  }
  setmetatable(obj, meta_obj)
  obj.init()
  return obj
end

function EventProxy.init(this)
	this._arr_off_fn = {}
end

function EventProxy.createfn(this, name)
	local em = events(name);
	local arr = this._arr_off_fn
	local fn_on = function (...)
		local args = {...}
		local fn_off = function ()
			em.off(unpack(args))
		end
		push(arr, fn_off)

		em.on(...)
	end
	return fn_on
end

function EventProxy.reset(this)
	local arr = this._arr_off_fn
	for i, fn in ipairs(this._arr_off_fn) do
		fn()
	end
end

return EventProxy