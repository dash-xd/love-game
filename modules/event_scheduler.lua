local sel = require('posix.sys.select')
local unistd = require('posix.unistd')
local fcntl = require('posix.fcntl')

local EventScheduler = {}
EventScheduler.__index = EventScheduler

function EventScheduler.new()
    local self = setmetatable({}, EventScheduler)
    self.coroutines = {}  -- Map of file descriptor to coroutine
    self.read_fds = {}    -- List of file descriptors to monitor for readability
    return self
end

-- Register a coroutine to wait on a socket for readability
function EventScheduler:wait_for_read(socket_fd, co)
    self.coroutines[socket_fd] = co
    table.insert(self.read_fds, socket_fd)
end

-- Run the scheduler and resume coroutines when events occur
function EventScheduler:run()
    while true do
        -- Use sel to monitor the read_fds for readability
        local ready_fds = sel.sel(self.read_fds, nil, nil, 1)  -- 1-second timeout

        if ready_fds and ready_fds[1] then
            for _, fd in ipairs(ready_fds[1]) do
                local co = self.coroutines[fd]
                if co and coroutine.status(co) == "suspended" then
                    coroutine.resume(co)
                end
            end
        end
    end
end

return EventScheduler
