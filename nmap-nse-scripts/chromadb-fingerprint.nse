local http = require "http"
local shortport = require "shortport"
local stdnse = require "stdnse"
local json = require "json"

description = "Identifies and fingerprints ChromaDB vector database instances."

-- PORT     STATE SERVICE
-- 8000/tcp open  http-alt
-- | chromadb-fingerprint: 
-- |   chroma-trace-id: found
-- |   version: "1.0.0"
-- |   health check: found
-- |   heartbeat: 1756387486698286801
-- |   tenant: default_tenant
-- |   databases: 
-- |     default_database
-- |   collections: 
-- |     
-- |       name: my_collection
-- |       log_position: 0
-- |       id: b1835c6e-a103-43e5-b982-f22d72a90191
-- |       configuration_json: 
-- |         spann: 
-- |         embedding_function: 
-- |           name: default
-- |           config: 
-- |           type: known
-- |         hnsw: 
-- |           sync_threshold: 1000
-- |           resize_factor: 1.2
-- |           ef_search: 100
-- |           max_neighbors: 16
-- |           ef_construction: 100
-- |           space: l2
-- |       version: 0
-- |       tenant: default_tenant
-- |       dimension: 384
-- |       metadata: 
-- |_      database: default_database

author = "Summit"
license = "Same as Nmap--See https://nmap.org/book/man-legal.html"
categories = {"discovery", "safe"}

portrule = shortport.portnumber("1-65535", "tcp", {"open", "open|filtered"})


action = function(host, port)
    local tenant, databases
    local output = stdnse.output_table()
    local resp = http.get(host, port, "/")

    if resp and resp.header and resp.header["chroma-trace-id"] then
        output["chroma-trace-id"] = "found"
    else
        return nil
    end

    resp = http.get(host, port, "/api/v2/version")

    if resp and resp.status == 200 then
        output["version"] = resp.body
    end

    resp = http.get(host, port, "/api/v2/healthcheck")

    if resp and resp.status == 200 then
        output["health check"] = "found"
    end

    resp = http.get(host, port, "/api/v2/heartbeat")

    if resp and resp.status == 200 then
        local _, json_data = json.parse(resp.body)
        output["heartbeat"] = json_data["nanosecond heartbeat"]
    end

    resp = http.get(host, port, "/api/v2/auth/identity")

    if resp and resp.body then
        local _, json_data = json.parse(resp.body)
        tenant = json_data.tenant or nil
        databases = json_data.databases or nil
        output["tenant"] = tenant
        output["databases"] = databases
    end

    if tenant ~= nil and databases ~= nil then
        resp = http.get(host, port, "/api/v2/tenants/" .. tenant .. "/databases/" .. databases[1] .. "/collections")

        if resp.status == 200 and resp.body ~= "[]" then
            local s, json_data = json.parse(resp.body)
            if s then
                output["collections"] = json_data
            end
        else
            output["collections"] = "not found or empty"
        end
    end

    return output
end
