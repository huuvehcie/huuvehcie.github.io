local http = require "http"
local shortport = require "shortport"
local stdnse = require "stdnse"
local table = require "table"

description = [[
This script attempts to find directories on a web server by accessing a list of common directory names.
]]

author = "Your Name"

license = "Same as Nmap--See https://nmap.org/book/man-legal.html"

categories = {"discovery", "intrusive"}

portrule = shortport.http

-- List of common directories to check
local directories = {
    "admin", "images", "js", "css", "uploads", "files", "backup", "data"
}

action = function(host, port)
    local found_directories = {}

    for _, dir in ipairs(directories) do
        local url = string.format("http://%s:%d/%s/", host.targetname or host.ip, port.number, dir)
        local response = http.get(url)

        if response and response.status == 200 then
            table.insert(found_directories, dir)
        end
    end

    if #found_directories > 0 then
        return stdnse.format_output(true, "Found directories:\n%s", table.concat(found_directories, "\n"))
    else
        return "No directories found."
    end
end
