
local pd <const> = playdate

local config = nil
local configName <const> = 'config'

local function buildPuzzlePath(folder, namePattern, puzDate)
    local fileName = formatDateTime(puzDate, namePattern)
    local year = formatDateTime(puzDate, '@year@')
    local month = formatDateTime(puzDate, '@month@')
    local filePath = 'puzzles' .. '/' .. folder .. "/" .. year .. '/' .. month .. "/" .. fileName
    return filePath
end

local function puzzleExists(folder, namePattern, puzDate)
    local filePath = buildPuzzlePath(folder, namePattern, puzDate)
    return pd.file.exists(filePath)
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
        fileName = 'wsj@year@@month@@day@.puz',
        url = 'https://herbach.dnsalias.com/wsj/wsj@year@@month@@day@.puz',
        folder = 'download/wsj',
        dayOfWeek = {true, true, true, true, true, true, false}
    },
    {
        active = true,
        fileName = 'uc@year@@month@@day@.puz',
        url = 'https://herbach.dnsalias.com/uc/uc@year@@month@@day@.puz',
        folder = 'download/uc',
        dayOfWeek = {true, true, true, true, true, true, true}
    },
    {
        active = true,
        fileName = 'wp@year@@month@@day@.puz',
        url = 'https://herbach.dnsalias.com/WaPo/wp@year@@month@@day@.puz',
        folder = 'download/wp',
        dayOfWeek = {false, false, false, false, false, false, true}
    },
    {
        active = true,
        fileName = 'ucs@year@@month@@day@.puz',
        url = 'https://herbach.dnsalias.com/uc/ucs@year@@month@@day@.puz',
        folder = 'download/uc',
        dayOfWeek = {false, false, false, false, false, false, true}
    },
    {
        active = true,
        fileName = 'jz@year@@month@@day@.puz',
        url = 'https://herbach.dnsalias.com/Jonesin/jz@year@@month@@day@.puz',
        folder = 'download/jz',
        dayOfWeek = {false, false, false, true, false, false, false}
    }
}

function loadNetworkConfig()
    if not pd.file.exists(configName .. '.json') then
        pd.datastore.write(urlConfig, configName, true)
    end

    local config = pd.datastore.read(configName)
end

function netTest()
    loadNetworkConfig()
    exists = puzzleExists("puzzles", "puzzle_@year@-@month@-@day@.txt", pd.getTime())
end