local getreg = debug.getregistry or getreg
local type = type
local debug_info = debug.info
local task = task
local filtergc = getgc or get_gc_objects
local isfunctionhooked = isfunctionhooked or function() return false end
local hookfunction = hookfunction or replaceclosure or detour_function
local getrawmetatable = getrawmetatable
local setreadonly = setreadonly or make_readonly

local noop = function() end
local RunService = game:GetService("RunService")

-- We target the internal "Remote" and "Process" tables revealed by the server code
local function bypassInternal()
    local gc = filtergc()
    for _, v in pairs(gc) do
        if type(v) == "table" then
            -- Adonis internal table detection
            local isAdonis = false
            if rawget(v, "Detected") and rawget(v, "Process") and rawget(v, "Remote") then
                isAdonis = true
            end
            
            if isAdonis then
                -- Hook the detection handler
                if type(v.Detected) == "function" and not isfunctionhooked(v.Detected) then
                    local oldDetected
                    oldDetected = hookfunction(v.Detected, newcclosure(function(action, info, ...)
                        -- Logs it locally so you know what triggered it, but doesn't report to server
                        print("[Zyntra] Blocked Adonis Detection:", action, "|", info)
                        return nil
                    end))
                end
                
                -- Hook the reporting/logging functions
                if type(v.AddLog) == "function" and not isfunctionhooked(v.AddLog) then
                    hookfunction(v.AddLog, noop)
                end
            end
            
            -- Targeted bypass for the Remote table's Fire/Send methods
            if rawget(v, "Send") and rawget(v, "Clients") then
                local oldSend = v.Send
                if type(oldSend) == "function" and not isfunctionhooked(oldSend) then
                    v.Send = newcclosure(function(self, name, ...)
                        local args = {...}
                        -- Only block detection-related sends
                        if name == "Detected" or name == "Log" or name == "ExploitDetected" then
                            print("[Zyntra] Prevented Remote Report:", name)
                            return nil
                        end
                        return oldSend(self, name, unpack(args))
                    end)
                end
            end
        end
    end
end

-- Kill specific anti-exploit threads without triggering namecall detectors
local function killAntiThreads()
    local reg = getreg()
    if not reg then return end
    for _, v in pairs(reg) do
        if type(v) == 'thread' then
            local ok, source = pcall(debug_info, v, 's')
            if ok and source then
                -- The server code mentions "ClientCheck" and "Anti" modules
                if source:find("Adonis") or source:find("Anti") then
                    -- Check if it's a core thread we shouldn't kill (like the heartbeat)
                    if not source:find("Remote") and not source:find("Network") then
                        pcall(task.cancel, v)
                    end
                end
            end
        end
    end
end

local function protect()
    pcall(bypassInternal)
    pcall(killAntiThreads)
end

-- Start protection
protect()

-- Fast loop to catch dynamic Adonis components
task.spawn(function()
    while task.wait(1.5) do
        pcall(protect)
    end
end)

print("[Zyntra] Adonis Anti Exploit was Bypassed.")
