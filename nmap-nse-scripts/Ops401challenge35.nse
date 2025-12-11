# Script:                        Ops 401 Challenge 35
# Author:                        Alex Wise
# Date of latest revision:       03/05/2023
# Purpose:                       write your own .nse script 

    # Task
    # In Kali Linux, write your own .nse script that gathers some kind of information about the target.
    # Post your LUA-language .nse script to your public GitHub repository. Share the link to it in your submission doc today.

# Main

# Declare the script's arguments
local port_range = stdnse.get_script_args('port-range') or '1-1000'

# Define the function that will be called for each open port found by Nmap
local function process_port(host, port)
    # Print the open port to the console
    print(string.format('%s:%d - open', host, port))
end

# Define the function that will be called for each target
local function scan_target(host)
    # Scan the target host using Nmap's default port scanning options
    local port_table = nmap.get_ports(port_range)

    # Call the process_port function for each open port found by Nmap
    nmap.new_portrule():set_ports(port_table):set_callback(process_port):scan(host)
end

# Register the script's arguments
portrule = function(host, port)
    return true
end

# Register the script with Nmap
action = function(host)
    scan_target(host)
end


# To run this script ,save it to a file and run Nmap with the --script option like the next line 
# nmap -p 1-1000 -sS -n -vvv --script=Wise_Pentest.nse <target>