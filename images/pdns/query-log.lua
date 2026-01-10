-- Custom query logging for PowerDNS Recursor

local qtypes = {
    [1] = "A",
    [2] = "NS",
    [5] = "CNAME",
    [6] = "SOA",
    [12] = "PTR",
    [15] = "MX",
    [16] = "TXT",
    [28] = "AAAA",
    [33] = "SRV",
    [255] = "ANY"
}

local rcodes = {
    [0] = "NOERROR",
    [1] = "FORMERR",
    [2] = "SERVFAIL",
    [3] = "NXDOMAIN",
    [4] = "NOTIMP",
    [5] = "REFUSED"
}

-- Load PTR cache from pre-generated file
local ptrCache = {}
local cacheFile = loadfile("/etc/powerdns/ptr-cache.lua")
if cacheFile then
    ptrCache = cacheFile() or {}
end

function getQTypeName(qtype)
    return qtypes[qtype] or tostring(qtype)
end

function getRCodeName(rcode)
    return rcodes[rcode] or tostring(rcode)
end

function isReverseLookup(qname)
    return qname:match("%.in%-addr%.arpa%.$") ~= nil
end

function postresolve(dq)

    local remoteIP = dq.remoteaddr:toString()
    local qname = dq.qname:toString()
    local qtype = getQTypeName(dq.qtype)
    local rcode = getRCodeName(dq.rcode)
    -- Get hostname from pre-loaded cache
    local hostname = ptrCache[remoteIP] or remoteIP


    -- Skip logging for reverse lookups
    --if isReverseLookup(qname) then
      --  return false
    --end

    local records = dq:getRecords()
    local answers = {}
    local ttl = " "
    local answer = " "


    for _, rec in ipairs(records) do
        if rec.place == 1 then
            answer = rec:getContent()
            ttl = rec.ttl
        end
        pdnslog(string.format('%-9s (%16s) %-26s\t%5s\tIN\t%4s\t%s$',rcode, hostname,  qname, ttl, qtype, answer), pdns.loglevels.Error)
    end
    
    return false
end
