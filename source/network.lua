
local pd <const> = playdate

local config = {}
local configName <const> = 'config'
local log = {}
local downloadCount = 0

-- Format the date and time for the puzzle file name.
-- The date is passed in as a playdate time object.
local function buildPuzzlePath(folder, namePattern, puzDate, makePath)
    local fileName = formatDateTime(puzDate, namePattern)
    local year = formatDateTime(puzDate, '@year@')
    local month = formatDateTime(puzDate, '@month@')
    local filePath = 'puzzles' .. '/' .. folder .. "/" .. year .. '/' .. month
    if makePath then
        pd.file.mkdir(filePath)
    end
    filePath = filePath .. '/' .. fileName
    return filePath
end

-- Parse an HTTP URL and return the component parts.
function parseUrl(url)
    local protocol = string.match(url, "^(%w+)://")
    local host = string.match(url, "://([^/]+)")
    local path = string.match(url, "://[^/]+(/.*)")
    local port, useSSL
    if protocol == "http" then
        port = 80
        useSSL = false
    elseif protocol == "https" then
        port = 443
        useSSL = true
    end

    return port, useSSL, host, path
end

-- Download a puzzle file if it doesn't already exist.
function downoadPuzzle(entry, puzDate)
    local fileName = formatDateTime(puzDate, entry.fileName)
    local year = formatDateTime(puzDate, '@year@')
    local month = formatDateTime(puzDate, '@month@')
    local filePath = buildPuzzlePath(entry.folder, fileName, puzDate)

    if not pd.file.exists(filePath) then
        local url = formatDateTime(puzDate, entry.url)
        local port, useSSL, host, path = parseUrl(url)
        local http = pd.network.http.new(host, port, useSSL, 'Download Crosswords')
        if http then
            http:setReadTimeout(20)
            local headers = {}
            if entry.headers then
                for s in string.gmatch(entry.headers, '([^^]+)') do
                    table.insert(headers, s)
                end
            end
            local rc = http:get(url, headers)
            if rc then
                local statusCode = http:getResponseStatus()
                while statusCode == 0 do
                    coroutine.yield()
                    statusCode = http:getResponseStatus()
                end
                print("HTTP status code: " .. statusCode)
                if statusCode ~= 200 then
                    local msg = "Failed to download puzzle " .. fileName .. ": " .. statusCode
                    print(msg)
                    table.insert(log, msg)
                    return
                end
                local bytesRead, bytesTotal = http:getProgress()
                print("Download progress: " .. bytesRead .. "/" .. bytesTotal)
                local data = http:read(bytesTotal)
                local filePath = buildPuzzlePath(entry.folder, fileName, puzDate, true)
                if data and #data == bytesTotal then
                    print("Download complete: " .. fileName)
                else
                    local reason = ''
                    if statusCode == 200 then
                        reason = ' (timeout)'
                    end
                    local msg = "Failed to download puzzle " .. fileName .. ": " .. statusCode .. reason
                    print(msg)
                    table.insert(log, msg)
                    return
                end
                local file = pd.file.open(filePath, playdate.file.kFileWrite)
                if file then
                    file:write(data)
                    file:close()
                    downloadCount = downloadCount + 1
                    local msg = "Puzzle downloaded and saved: " .. fileName
                    print(msg)
                    table.insert(log, msg)
                    return
                end
                local msg = 'Unable to open: ' .. filePath
                print(msg)
                table.insert(log, msg)
                return
            end
        else
            print("Failed to create HTTP object")
            return
        end
        print("Downloading puzzle from: " .. url)
    else
        local msg = "Puzzle already exists: " .. fileName
        print(msg)
        table.insert(log, msg)
    end
end

-- Select active puzzle entries from the current configuratiob and
-- attempt to download them.
-- If puzDate is not provided, the current date will be used.
-- The function returns a log of the download attempts.
-- The log is a table of strings, each string is a message about the
function checkPuzzleDownload(puzDate)
    log = {}
    downloadCount = 0
    if not puzDate then
        puzDate = pd.getTime()
    end
    for i, entry in ipairs(config) do
        if entry.active and entry.dayOfWeek[puzDate.weekday] then
            downoadPuzzle(entry, puzDate)
        end
    end

    return downloadCount, log
end

-- URL configuration table entry formet.
--    active: if true the entry will be used to attempt a puzzle download.
--    fileName: the name the downloaded puzzle should be stored under.
--    url: the URL to download the puzzle from.
--    folder: the folder to store the downloaded puzzle in.
--    dayOfWeek: the days of the week to attempt puzzle download.  dayOfWeek[1] is Monday.
local urlConfig <const> = {
    {
        active = true,
        fileName = 'wsj@year2@@month@@day@.puz',
        url = 'https://herbach.dnsalias.com/wsj/wsj@year2@@month@@day@.puz',
        folder = 'download/wsj',
        dayOfWeek = {true, true, true, true, true, true, false}
    },
    {
        active = true,
        fileName = 'uc@year2@@month@@day@.puz',
        url = 'https://herbach.dnsalias.com/uc/uc@year2@@month@@day@.puz',
        folder = 'download/uc',
        dayOfWeek = {true, true, true, true, true, true, true}
    },
    {
        active = true,
        fileName = 'wp@year2@@month@@day@.puz',
        url = 'https://herbach.dnsalias.com/WaPo/wp@year2@@month@@day@.puz',
        folder = 'download/wp',
        dayOfWeek = {false, false, false, false, false, false, true}
    },
    {
        active = true,
        fileName = 'ucs@year2@@month@@day@.puz',
        url = 'https://herbach.dnsalias.com/uc/ucs@year2@@month@@day@.puz',
        folder = 'download/uc',
        dayOfWeek = {false, false, false, false, false, false, true}
    },
    {
        active = true,
        fileName = 'jz@year2@@month@@day@.puz',
        url = 'https://herbach.dnsalias.com/Jonesin/jz@year2@@month@@day@.puz',
        folder = 'download/jz',
        dayOfWeek = {false, false, false, true, false, false, false}
    }
}

-- Load the network configuration.
function loadNetworkConfig()
    if not pd.file.exists(configName .. '.json') then
        pd.datastore.write(urlConfig, configName, true)
    end

    local loadedConfig = pd.datastore.read(configName)
    if loadedConfig then
        config = loadedConfig
    else
        config = urlConfig
    end
end
