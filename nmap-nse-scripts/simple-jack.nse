-- HEAD --

description = [[
This is an extremely simple script that just scans a network for open ports
]]

author = "Jeremy B."

-- RULE --

portrule = function(host, port)
        return port.protocol == "tcp"
                and port.state == "open"
end

-- ACTION --

action = function(host, port)
          return "This port IS OPEN!!!"
end
