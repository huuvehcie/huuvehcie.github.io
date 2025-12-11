license = "Same as Nmap--See https://nmap.org/book/man-legal.html"

categories = {"discovery", "safe"}

-- Import necessary modules
local shortport = require "shortport"
local stdnse = require "stdnse"
local http = require "http"

portrule = shortport.http

action = function(host, port)
    local response = http.get(host, port, "/")
    
    if not response then
        stdnse.print_debug(1, "HTTP request failed.")
        return "HTTP request failed."
    end

    if response.status then
        return "HTTP Server Information:\n" ..
               "Status: " .. response.status .. "\n" ..
               "Headers: " .. stdnse.strjoin("\n", response.header)
    else
        stdnse.print_debug(1, "Failed to retrieve HTTP server information.")
        return "Failed to retrieve HTTP server information."
    end
end
