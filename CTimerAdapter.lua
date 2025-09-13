-- CTimerAdapter.lua
-- Provides C_Timer.After, C_Timer.NewTicker, and C_Timer.NewTimer
-- for Wrath/Classic clients. Uses Blizzard's built-ins if present.

C_Timer = C_Timer or {}

-----------------------------------------------------------------------
-- Timer storage and driver frame
-----------------------------------------------------------------------

local activeTimers = {}
local driver = CreateFrame("Frame")
driver:SetScript("OnUpdate", function(self, elapsed)
    for i = #activeTimers, 1, -1 do
        local t = activeTimers[i]
        t.elapsed = t.elapsed + elapsed
        if t.elapsed >= t.delay then
            t.elapsed = t.elapsed - t.delay
            t.callback()
            if t.type == "after" or t.type == "timer" then
                table.remove(activeTimers, i)
            elseif t.type == "ticker" then
                if t.iterations > 0 then
                    t.iterations = t.iterations - 1
                    if t.iterations == 0 then
                        table.remove(activeTimers, i)
                    end
                end
                if t.cancelled then
                    table.remove(activeTimers, i)
                end
            end
        end
    end
end)

-----------------------------------------------------------------------
-- C_Timer.After(delay, callback)
-- One-shot, fire-and-forget (no cancel).
-----------------------------------------------------------------------

if not C_Timer.After then
    function C_Timer.After(delay, func)
        table.insert(activeTimers, {
            type = "after",
            delay = delay,
            callback = func,
            elapsed = 0,
        })
    end
end

-----------------------------------------------------------------------
-- Ticker / Timer base object
-----------------------------------------------------------------------

local TimerBase = {}
TimerBase.__index = TimerBase

function TimerBase:Cancel()
    self.cancelled = true
end

-----------------------------------------------------------------------
-- C_Timer.NewTicker(interval, callback, iterations)
-- Repeating timer, returns an object with :Cancel().
-----------------------------------------------------------------------

if not C_Timer.NewTicker then
    function C_Timer.NewTicker(interval, callback, iterations)
        local self = setmetatable({}, TimerBase)
        self.type = "ticker"
        self.delay = interval
        self.callback = callback
        self.elapsed = 0
        self.iterations = iterations or -1 -- -1 = infinite
        self.cancelled = false
        table.insert(activeTimers, self)
        return self
    end
end

-----------------------------------------------------------------------
-- C_Timer.NewTimer(delay, callback)
-- One-shot object that returns the same kind of handle as a ticker,
-- so you can :Cancel() it before it fires.
-----------------------------------------------------------------------

if not C_Timer.NewTimer then
    function C_Timer.NewTimer(delay, callback)
        local self = setmetatable({}, TimerBase)
        self.type = "timer"
        self.delay = delay
        self.callback = function()
            if not self.cancelled then
                callback()
            end
        end
        self.elapsed = 0
        self.cancelled = false
        table.insert(activeTimers, self)
        return self
    end
end
