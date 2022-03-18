local tomato = {}

local db = require("tomato.db")

local config = {
    time_work = 0.01,
    time_break_short = 0.1,
    time_break_long = 0.4,
    pomodoros_big_break = 4,
}
local loaded_tomato = false

local timer_running = false
local uv_timer = vim.loop.new_timer()
local count = 0

local function start_break(long)
    local time
    if long == true then
        db.set_timer_status("long_break")
        time = config.time_break_long
    else
        db.set_timer_status("short_break")
        time = config.time_break_short
    end
    vim.loop.timer_start(uv_timer, time * 1000 * 60, 0, function()
        timer_running = false
        vim.schedule(function()
            print("break ende")
        end)
    end)
end

local function timer_ended()
    vim.loop.timer_stop(uv_timer)
    count = count + 1
    vim.ui.select({ "Take a break", "Quit" }, { prompt = "Pomodoro is finished. What to do?" }, function(_, idx)
        if idx == 1 then
            start_break()
        elseif idx == 2 then
            return
        end
    end)
    local topic = db:get_topic()
    db.update_log({
        start_time = db.get_start_time(),
        end_time = os.time(),
        topic = topic,
    })
end

--- Starts a timer
---@param time_arg number Lenghth of timer in minutes
---@param seconds boolean Whether time is in seconds or not
local function start_timer(time_arg, seconds, new_timer)
    local pomo_topic
    if new_timer then
        pomo_topic = vim.fn.input("What will you do during this pomodoro > ", "")
    end
    if timer_running then
        return
    end
    db.set_start_time(os.time())
    db.set_topic(pomo_topic)
    timer_running = true
    local time = config.time_work
    if time_arg then
        time = time_arg
    end
    if seconds then
        vim.loop.timer_start(uv_timer, time * 1000, 0, function()
            timer_running = false
            vim.schedule(function()
                timer_ended()
            end)
        end)
    else
        vim.loop.timer_start(uv_timer, time * 60 * 1000, 0, function()
            timer_running = false
            vim.schedule(function()
                timer_ended()
            end)
        end)
    end
end

--- Returns time since start of timer
---@return integer time Time since start in seconds
local function time_since_start()
    local time_diff = os.date("*t", os.difftime(os.time(), db.get_start_time()))
    return (time_diff.sec + time_diff.min * 60 + (time_diff.hour - 1) * 3600)
end

local function enter_vim()
    local passed_time = time_since_start()
    local timer_status = db.get_timer_status()
    --- Time to do in seconds
    local time_to_do
    if timer_status == "work" then
        time_to_do = config.time_work * 60 - passed_time
    elseif timer_status == "stopped" then
        return
    elseif timer_status == "short_break" then
        time_to_do = config.time_break_short * 60 - passed_time
    elseif timer_status == "long_break" then
        time_to_do = config.time_break_long * 60 - passed_time
    end
    if not time_to_do then
        return
    end
    if time_to_do <= 0 then
        return
    end
    start_timer(time_to_do, true, false)
end

function tomato.setup(update)
    if loaded_tomato then
        return
    end
    loaded_tomato = true
    config = vim.tbl_deep_extend("force", config, update or {})
    vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
            enter_vim()
        end,
        pattern = "*",
    })
    vim.api.nvim_add_user_command("TomatoStart", function(param)
        db.set_timer_status("work")
        if param.args then
            start_timer(param.args[1], false, true)
        else
            start_timer(false, false, true)
        end
    end, {
        desc = "Start a new timer",
    })
end

return tomato
