
local optionsFilename <const> = 'options'
local lastPuzzleName <const> = 'lastPuzzle'
local rebusName <const> = 'rebus'

options = nil

function loadOptions()
    options = playdate.datastore.read(optionsFilename)
    if options == nil then
        options = {}
        if playdate.file.exists(rebusName .. '.json') then
            options.rebus = playdate.datastore.read(rebusName)
            playdate.file.delete(rebusName .. '.json')
        end

        if playdate.file.exists(lastPuzzleName .. '.json') then
            options.lastPuzzle = playdate.datastore.read(lastPuzzleName)
            playdate.file.delete(lastPuzzleName .. '.json')
        end
    end

    if options.rebus == nil then
        options.rebus = true
    end

    if options.playMusic == nil then
        options.playMusic = true
    end
end

function saveOptions()
    playdate.datastore.write(options, optionsFilename)
end