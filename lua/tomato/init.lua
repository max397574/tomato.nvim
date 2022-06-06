local tomato = {}

local db = require("tomato.db")

local config = {
    -- time in minutes for work
    time_work = 0.2,
    -- time in minutes for short break
    time_break_short = 0.1,
    -- time in minutes for big break
    time_break_long = 0.4,
    -- amount of pomodoros until big break
    pomodoros_big_break = 4,
}
local loaded_tomato = false

local timer_running = false
local uv_timer = vim.loop.new_timer()
local count = 0
local start_timer

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
            vim.ui.select(
                { "Start a new pomodoro", "Quit" },
                { prompt = "Break is finished. What to do?" },
                function(_, idx)
                    if idx == 1 then
                        start_timer(false, false, true)
                    elseif idx == 2 then
                        return
                    end
                end
            )
        end)
    end)
end

local function timer_ended()
    vim.loop.timer_stop(uv_timer)
    count = count + 1
    vim.ui.select(
        { "Take a break", "Quit" },
        { prompt = "Pomodoro is finished. What to do?" },
        function(_, idx)
            if idx == 1 then
                start_break()
            elseif idx == 2 then
                return
            end
        end
    )
    local topic = db.get_topic()
    db.update_log({
        start_time = db.get_start_time(),
        end_time = os.time(),
        topic = topic,
    })
end

--- Starts a timer
---@param time_arg number Lenghth of timer in minutes
---@param seconds boolean Whether time is in seconds or not
---@param new_timer boolean
start_timer = function(time_arg, seconds, new_timer)
    local pomo_topic
    if new_timer then
        pomo_topic = vim.fn.input(
            "What will you do during this pomodoro > ",
            ""
        )
    else
        pomo_topic = db.get_topic()
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
    else
        seconds = false
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
    db.sync_dec()
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
        -- TODO: functionality
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
    vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function()
            db.flush()
        end,
        pattern = "*",
    })
    vim.api.nvim_create_user_command("TomatoStart", function(param)
        db.set_timer_status("work")
        if param.args then
            start_timer(tonumber(param.fargs[1]), false, true)
        else
            start_timer(false, false, true)
        end
    end, {
        desc = "Start a new timer",
        nargs = "?",
    })
end

function tomato.get_log(today)
    local raw_log = db.get_log()
    local date = os.date("*t")
    local date_string = date.year .. "-" .. date.month .. "-" .. date.day
    local pretty_log = {}
    if today then
        raw_log = { [date_string] = raw_log[date_string] }
    end
    for day, daily_log in pairs(raw_log) do
        table.insert(pretty_log, day)
        for _, timer in ipairs(daily_log) do
            local start_time = os.date("*t", timer.start_time)
            local end_time = os.date("*t", timer.end_time)
            if timer.topic then
                table.insert(pretty_log, "  " .. timer.topic)
            end
            table.insert(
                pretty_log,
                "    From: " .. start_time.hour .. ":" .. start_time.min
            )
            table.insert(
                pretty_log,
                "    To: " .. end_time.hour .. ":" .. end_time.min
            )
            table.insert(pretty_log, "")
        end
    end
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
    vim.api.nvim_buf_set_keymap(
        buf,
        "n",
        "q",
        "<cmd>q<CR>",
        { noremap = true, silent = true, nowait = true }
    )
    local lines = pretty_log
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    local width = vim.api.nvim_win_get_width(0)
    local height = vim.api.nvim_win_get_height(0)
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "win",
        win = 0,
        width = math.floor(width * 0.9),
        height = math.floor(height * 0.9),
        col = math.floor(width * 0.05),
        row = math.floor(height * 0.05),
        border = "single",
        style = "minimal",
    })
    vim.api.nvim_win_set_option(win, "winblend", 20)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    return pretty_log
end

return tomato
