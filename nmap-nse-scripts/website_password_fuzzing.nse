local shortport = require "shortport"
local http = require "http"
local stdnse = require "stdnse"

description = [[
Simple password fuzzer for the admin account on a WordPress login page
]]

---
-- @usage
-- nmap --script website_password_fuzzing.nse <target>
---

author = "Thomas B."
license = "None"
categories = {"fuzzer", "intrusive"}

portrule = shortport.http

local URI = "/wp-login.php"
local USERVAR = "log"
local PASSVAR = "pwd"

local PASSLIST = {"test", "pass", "password"}

action = function(host, port)
  local result = http.get(host, port, URI)
  if (result.status == 200) then
    -- stdnse.debug1("Launching brute force attack")
    print("Launching brute force attack")
    for i = 1,PASSLIST.n do
      -- stdnse.debug1("Use password" .. PASSLIST[i])
      print("Use password" .. PASSLIST[i])
      -- to implement...
    end
  else
    -- stdnse.debug1("Initial check failed, uri is valid?")
    print("Initial check failed, uri is valid?")
  end
  return "End of the script"
end

