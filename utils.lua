local easing = require("easing")
local Text = require "widgets/text"
local Widget = require "widgets/widget"
local Image = require "widgets/image"

local DST_ROLES = DST_CHARACTERLIST
local MOD_ROLES = MODCHARACTERLIST

------------------------------------------------------------
-- this
------------------------------------------------------------

this = this or {}

this.key_inited = this.key_inited or {}
this.key_down_count = this.key_down_count or {}


this.selected_ents = this.selected_ents or {}
this.color = {x = 1, y = 1, z = 1}

local b_debug = true
local UPDATE_MS_INTERVAL = 1
local DEFAULT_FADE_TIME = 10

------------------------------------------------------------
-- tools
------------------------------------------------------------

function sformat(str, dict)
  str = string.gsub(str, "(%$%b{})", function (str)
    local key = string.sub(str, 3, -2)
    return tostring(dict[key] or str)
  end)
  return str
end

function split_by_space(s)
  local arr = {}
  for w in s:gmatch("%S+") do
    arr[#arr+1] = w
  end
  return arr
end

function shuffle(arr)
  local len = #arr
  for i=1, len-1 do
    local x = math.random(i, len)
    arr[i], arr[x] = arr[x], arr[i]
  end
  return arr
end

function random_color(x)
  local arr = this.arr_color
  if not (arr) then
    arr = {}
    for name, color in pairs(PLAYERCOLOURS) do
      push(arr, color)
    end
    this.arr_color = arr
  end

  local len = #arr
  local x = x or math.random(1, len)
  local t_color = {
    [1] = 0.5843137254902;
    [2] = 0.74901960784314;
    [3] = 0.94901960784314;
    [4] = 1;
  }
  if (t_color) then
    return t_color
  end
  return this.arr_color[x]
end

function sign(v)
  return (v >= 0 and 1) or -1
end

function round(v, bracket)
  bracket = bracket or 1
  return math.floor(v/bracket + sign(v) * 0.5) * bracket
end

------------------------------------------------------------
-- show msg
------------------------------------------------------------

function show_msg_api(msg, onlyClear)
  if not (TheFrontEnd and TheFrontEnd.overlayroot) then
    return
  end

  local inst = this.label
  -- if (inst) then
  --   inst:Hide()
  -- end
  if (this.update_msg_task) then
    this.update_msg_task:Cancel()
    this.update_msg_task = nil
  end

  if (b_debug and inst) then
    TheFrontEnd.overlayroot:RemoveChild(inst)
    inst:Hide()
    inst:Kill()
    this.label = nil
  end

  if (onlyClear) then
    return
  end


  if not (this.label) then
    inst = Text(TALKINGFONT, 32)
    inst:Hide()
    -- ANCHOR_BOTTOM ANCHOR_TOP
    -- ANCHOR_LEFT ANCHOR_RIGHT

    -- -- right corner status pos
    inst:SetPosition(-400, 170, 0)
    inst:SetHAnchor(ANCHOR_RIGHT)
    inst:SetVAnchor(ANCHOR_BOTTOM)
    inst:SetHAlign(ANCHOR_LEFT)
    inst:SetVAlign(ANCHOR_TOP)

    -- -- chat input pos
    -- inst:SetPosition(335, 170, 0)
    -- inst:SetHAnchor(ANCHOR_LEFT)
    -- inst:SetVAnchor(ANCHOR_BOTTOM)
    -- inst:SetHAlign(ANCHOR_LEFT)
    -- inst:SetVAlign(ANCHOR_TOP)

    this.label = inst
    TheFrontEnd.overlayroot:AddChild(inst)
  end

  inst:SetString(msg)
  inst:Show()

  local ontimeover = _f(function (inst)
    inst:Hide()
    this.update_msg_task:Cancel()
    this.update_msg_task = nil
  end)

  local fade_time = this.fade_time or DEFAULT_FADE_TIME
  if (fade_time > 0) then
    this.update_msg_task = TheWorld:DoTaskInTime(
      fade_time,
      function()
        ontimeover(inst)
      end,
      0
    )
  end
end

function show_msg(...)
  local arr = {}
  for i,v in ipairs({...}) do
    arr[i] = tostring(v)
  end
  local msg = tjoin(arr, "\n")
  show_msg_api(msg)
  print(msg)
end

function std_fade_time(s)
  local n = tonumber(s)
  if not (n) then return end;
  return math.min(math.max(n, -1), 60)
end

------------------------------------------------------------
-- AddUserCommand
------------------------------------------------------------

function AddChatCommand(cmd, fn, options)
  local onCommand = _f(function (params, caller)
    local args = {}
    if (params and params.rest and #params.rest > 0) then
      args = split_by_space(params.rest)
    end
    fn(params, unpack(args))
  end)

  -- todo check whether if cmd already reg
  -- overwrites options
  -- todo params, caller) to cmd & args
  AddUserCommand(cmd, {
    prettyname = nil, --default to STRINGS.UI.BUILTINCOMMANDS.BUG.PRETTYNAME
    desc = nil, --default to STRINGS.UI.BUILTINCOMMANDS.BUG.DESC
    permission = COMMAND_PERMISSION.USER,
    slash = false,
    usermenu = false,
    servermenu = false,
    params = {},
    vote = false,
    localfn = onCommand,
  })
end

function on_ls_player(guid)
  local arr_client = TheNet:GetClientTable() or {}
  local users = {}
  local _cache = {}
  local arr = {}
  for i, client in ipairs(arr_client) do
    users[client.userid] = client
    _cache[i-1] = client;

    local ln = ("%d %s %s %s %s \n"):format(i-1, client.userid, client.name, 
      client.admin and "admin" or "", 
      client.friend and "friend" or "")
    push(arr, ln)
    print(i-1, client.userid, client.name, client.admin, client.friend)
  end
  local text = tjoin(arr)
  show_msg(text)

  this.ls_client_cache = _cache;
end


return _M;