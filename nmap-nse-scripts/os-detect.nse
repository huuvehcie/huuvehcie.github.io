description = [[
Attempts to determine the operating system of a web server by examining
the Server header in the HTTP response.
]]

author = "Kang Li"
license = "Same as Nmap--See https://nmap.org/book/man-legal.html"
categories = {"default", "discovery", "safe"}

-- Define the rule to run the script only when port 80 or 443 is open
portrule = function(host, port)
    return (port.number == 80 or port.number == 443) and port.state == "open"
end

-- Action to perform when the above rule is satisfied
action = function(host, port)
    -- Make the HTTP request using the http library
    local http = require "http"
    local stdnse = require "stdnse"
    local target = stdnse.get_hostname(host)
    local response

    -- If SSL is used (port 443), set the 'ssl' flag
    if port.number == 443 then
        response = http.get(host, port, "/", {ssl=true})
    else
        response = http.get(host, port, "/")
    end

    -- Check the response
    if response and response.header and response.header.server then
        local server_header = response.header.server
        stdnse.print_stdout("Server header for host %s on port %d: %s", target, port.number, server_header)

        -- Attempt to determine the OS from the Server header
        -- Note: This is a very simplistic check and might not be accurate.
        -- More sophisticated OS fingerprinting would be required for better accuracy.
        if server_header:lower():find("unix") then
            return "The operating system of the web server appears to be Unix-based."
        elseif server_header:lower():find("win") then
            return "The operating system of the web server appears to be Windows-based."
        else
            return "The operating system of the web server could not be determined from the Server header."
        end
    else
        return "The Server header is not available in the HTTP response."
    end
end
