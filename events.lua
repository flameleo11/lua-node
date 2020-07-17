local Emitter = require('Emitter')
local _emitter_list = {}
local events = setmetatable({}, {
	__call = function (_, name) 
		name = name or ""
		_emitter_list[name] = _emitter_list[name] or Emitter()
		return _emitter_list[name]
	end
})

return events