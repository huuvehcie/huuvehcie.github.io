-- Save this script as "simple_banner.nse"

description = [[
Retrieves a simple banner from a given host and port.
]]

author = "carlos"
license = "Same as Nmap--See https://nmap.org/book/man-legal.html"
categories = {"default", "discovery"}

-- The portrule to run the script against port 80 (HTTP)
portrule = function(host, port)
  return port.number == 80 and port.protocol == "tcp"
end

-- The action function that will be executed when the script is run
action = function(host, port)
	local try = nmap.new_try()

	-- Send a request and receive the response from the target
	local response = try(comm.exchange(host, port.number, "\r\n",
        	{lines=1, proto="tcp", timeout=5000}))

	-- Print the banner from the response
	if response then
		print("Banner: " .. response)
	else
		print("Unable to retrieve banner.")
	end
end
