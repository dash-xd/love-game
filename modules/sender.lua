local unistd = require('posix.unistd')
local fcntl = require('posix.fcntl')
local pb = require("message_pb")

local function create_sender(socket_path, hub, scheduler)
    local socket_fd = unistd.open(socket_path, fcntl.O_RDWR)
    assert(socket_fd, "Failed to open socket for writing")

    -- Coroutine to send messages
    return coroutine.create(function(serialized_message)
        while true do
            coroutine.yield()  -- Yield until we have a message to publish
            unistd.write(socket_fd, serialized_message)
            print("Message sent from sender!")
        end
    end)
end

return create_sender
