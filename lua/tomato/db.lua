local tomato_db = {}

tomato_db.file = vim.fn.stdpath("data")
    .. package.config:sub(1, 1)
    .. "tomato.mpack"

tomato_db.data = {
    started = 0,
    status = "",
    topic = "",
    duration = 0,
    log = {},
    pomodoro_count = 0,
}

function tomato_db.sync_dec()
    local file = io.open(tomato_db.file, "r")
    if not file then
        return
    end
    local content = file:read("*a")
    io.close(file)
    tomato_db.data = vim.mpack.decode(content)
end

function tomato_db.flush()
    local file = io.open(tomato_db.file, "w")
    if not file then
        return
    end
    file:write(vim.mpack.encode(tomato_db.data))
    io.close(file)
end

function tomato_db.set_duration(duration)
    tomato_db.data.duration = duration
end

function tomato_db.get_duration()
    return tomato_db.data.duration
end

function tomato_db.set_pomodoro_count(count)
    tomato_db.data.pomodoro_count = count
end

function tomato_db.get_pomodoro_count()
    return tomato_db.data.pomodoro_count
end

function tomato_db.set_start_time(time)
    tomato_db.data.started = time
end

function tomato_db.set_timer_status(status)
    tomato_db.data.status = status
end

function tomato_db.get_timer_status()
    return tomato_db.data.status
end

function tomato_db.get_start_time()
    return tomato_db.data.started
end

function tomato_db.set_topic(topic)
    tomato_db.data.topic = topic
end

function tomato_db.get_topic()
    return tomato_db.data.topic
end

function tomato_db.update_log(timer)
    local date = os.date("*t")
    local date_string = date.year .. "-" .. date.month .. "-" .. date.day
    local log = tomato_db.data.log
    if not tomato_db.data.log[date_string] then
        log[date_string] = {}
        tomato_db.data.log = log
    end
    local log_tbl = tomato_db.data.log
    table.insert(log_tbl[date_string], timer)
    tomato_db.data.log = log_tbl
end

function tomato_db.get_log()
    return tomato_db.data.log
end

return tomato_db
