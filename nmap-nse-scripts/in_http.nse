-- HEAD --

lisense = 'same as nmap see: https://nmap.org/book/man-legal.html'

description = [[

find specific content in http response

nmap --script=./in_http 192.168.0.0/24 -p80,443 --open

-- TODO: add variable containing string to scan to make it more dynamic

ono7

]]

local shortport = require "shortport"
local http = require "http"

-- RULE --

portrule = shortport.http

-- ACTION --

action = function(host, port)
  local uri = "/"
  local r = http.get(host, port, uri)
  if (r.status == 200) then
    -- replace 'wireless' with whatever you want to find in the response body or
    -- other parts of the response..
    if string.match(r.body, 'wireless') then
      return r.body
    end
    return 'no match'
  end
end
