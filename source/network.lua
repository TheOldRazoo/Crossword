
local pd <const> = playdate

local config = nil
local configName <const> = 'config'
local log = {}

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

local function puzzleExists(folder, namePattern, puzDate)
    local filePath = buildPuzzlePath(folder, namePattern, puzDate)
    return pd.file.exists(filePath)
end

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
            local rc = http:get(url)
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
                local file = pd.file.open(filePath, playdate.file.kFileWrite)
                if file then
                    file:write(data)
                    file:close()
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
        print("Puzzle already exists: " .. filePath)
    end
end

function checkPuzzleDownload(puzDate)
    log = {}
    if not puzDate then
        puzDate = pd.getTime()
    end
    for i, entry in ipairs(config) do
        if entry.active and entry.dayOfWeek[puzDate.weekday] then
            downoadPuzzle(entry, puzDate)
        end
    end

    return log
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

function loadNetworkConfig()
    if not pd.file.exists(configName .. '.json') then
        pd.datastore.write(urlConfig, configName, true)
    end

    config = pd.datastore.read(configName)
end

function netTest()
    loadNetworkConfig()
    checkPuzzleDownload()
    exists = puzzleExists("puzzles", "puzzle_@year@-@month@-@day@.txt", pd.getTime())
end