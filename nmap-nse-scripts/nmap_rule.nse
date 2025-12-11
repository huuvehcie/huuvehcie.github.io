description = [[
Scans well-known ports (0-1023) and returns the host OS.
]]

-- Specify the rule function to define when the script should run
hostrule = function(host)
    return shortport.portnumber(1) and shortport.portnumber(1023)
end

-- Define the action function
action = function()
    -- Define the range of ports to scan
    local ports_to_scan = "1-1023"
    
    -- Run the port scan
    local result = nmap.scan_ports(ports_to_scan)
    
    -- Retrieve the host OS
    local os = osfinger.new()
    
    -- Print results
    if os and os.name then
        print('Host OS: ' .. os.name)
    else
        print('Unable to determine host OS')
    end
    
    -- Print open ports
    for port, state in pairs(result) do
        if state.state == "open" then
            print('Port ' .. port .. ' is open')
        end
    end
end



-- Resources: https://nmap.org/book/nse-tutorial.html, https://www.stationx.net/nmap-cheat-sheet/, https://www.lua.org/manual/5.1/, https://chat.openai.com/share/a9fda0b8-da9f-4ccc-8659-810841ef1e81