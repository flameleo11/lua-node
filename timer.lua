-- local inst = arg[1]

------------------------------------------------------------
-- timer
------------------------------------------------------------

return (function (inst)
  assert(inst, "timer inst is "..tostring(inst))

  function removeTimer(timer)
    if (timer) then
      timer:Cancel()
    end
  end

  function setTimeout(fn, interval)
    local elapse_time = 0
    local delay_sec = interval
    local timer = inst:DoTaskInTime(delay_sec, _f(function ()
      elapse_time = elapse_time + interval
      fn(elapse_time)
    end), 0)  
    return timer
  end

  function setInterval(fn, interval)
    local elapse_time = 0
    local delay_sec = interval
    local timer = inst:DoPeriodicTask(interval, _f(function ()
      fn(elapse_time)
      elapse_time = elapse_time + interval
    end), 0)  
    return timer
  end

  return _M
end)