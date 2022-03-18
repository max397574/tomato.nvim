local sql = require("sqlite.db")

local tbl = require("sqlite.tbl")
local db = sql:open(vim.fn.stdpath("data") .. "/databases/tomato.db") -- open in memory
local db_table = tbl("db_table", {
    key = { "text", primary = true, required = true, default = "none" },
    started = "number",
    status = "text",
    topic = "text",
    log = "luatable",
}, db)

local name = vim.fn.stdpath("data") .. package.config:sub(1, 1) .. "tomato_nvim_first_use"
local f = io.open(name, "r")
if f ~= nil then
    io.close(f)
else
    db_table.timer = { started = nil, status = nil, topic = nil }
    db_table.log = { log = {} }
    f = io.open(name, "w+")
    io.close(f)
end

-- db_table.timer = { started = nil, status = nil, topic = nil }
-- db_table.log = { log = {} }

local tomato_db = {}

function tomato_db.set_start_time(time)
    db_table.timer.started = time
end

function tomato_db.set_timer_status(status)
    db_table.timer.status = status
end

function tomato_db.get_timer_status()
    return db_table.timer.status
end

function tomato_db.get_start_time()
    return db_table.timer.started
end

function tomato_db.set_topic(topic)
    db_table.timer.topic = topic
end

function tomato_db.get_topic()
    return db_table.timer.topic
end

function tomato_db.update_log(timer)
    local date = os.date("*t")
    local date_string = date.year .. "-" .. date.month .. "-" .. date.day
    local log = db_table.log.log
    if not db_table.log.log[date_string] then
        log[date_string] = {}
        db_table.log.log = log
    end
    local log_tbl = db_table.log.log
    table.insert(log_tbl[date_string], timer)
    db_table.log = { log = log_tbl }
end

function tomato_db.get_log()
    return db_table.log.log
end

return tomato_db
