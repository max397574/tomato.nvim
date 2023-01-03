local M = {}

M.file = vim.fn.stdpath("data") .. package.config:sub(1, 1) .. "tomato.mpack"

M.data = {
    started = 0,
    status = "",
    topic = "",
    duration = 0,
    log = {},
    pomodoro_count = 0,
}

function M.sync_dec()
    local file = io.open(M.file, "r")
    if not file then
        return
    end
    local content = file:read("*a")
    io.close(file)
    M.data = vim.mpack.decode(content)
end

function M.flush()
    local file = io.open(M.file, "w")
    if not file then
        return
    end
    file:write(vim.mpack.encode(M.data))
    io.close(file)
end

function M.set_duration(duration)
    M.data.duration = duration
end

function M.get_duration()
    return M.data.duration
end

function M.set_pomodoro_count(count)
    M.data.pomodoro_count = count
end

function M.get_pomodoro_count()
    return M.data.pomodoro_count
end

function M.set_start_time(time)
    M.data.started = time
end

function M.set_timer_status(status)
    M.data.status = status
end

function M.get_timer_status()
    return M.data.status
end

function M.get_start_time()
    return M.data.started
end

function M.set_topic(topic)
    M.data.topic = topic
end

function M.get_topic()
    return M.data.topic
end

function M.update_log(timer)
    local date = os.date("*t")
    local date_string = date.year .. "-" .. date.month .. "-" .. date.day
    local log = M.data.log
    if not M.data.log[date_string] then
        log[date_string] = {}
        M.data.log = log
    end
    local log_tbl = M.data.log
    table.insert(log_tbl[date_string], timer)
    M.data.log = log_tbl
end

function M.get_log()
    return M.data.log
end

return M
