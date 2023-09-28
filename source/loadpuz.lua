
local pd <const> = playdate
local pdfile <const> = pd.file

local function cksumRegion(data, start, len, cksum)
    for i = 1, len do
        cksum = cksum & 0xffff
        if cksum & 0x0001 == 1 then
            cksum = (cksum >> 1) + 0x8000
        else
            cksum = cksum >> 1
        end

        cksum += string.unpack("b", data, start + i - 1)
    end

    return cksum
end

local zeroByte <const> = string.pack("b", 0)

local function calcCheckSum(fileData, puz)
    local cksum = cksumRegion(fileData, 0x35, puz.width * puz.height * 2, 0)
    if #puz.title > 0 then
        cksum = cksumRegion(puz.title, 1, #puz.title, cksum)
    end
    cksum = cksumRegion(zeroByte, 1, 1, cksum)

    if #puz.author > 0 then
        cksum = cksumRegion(puz.author, 1, #puz.author, cksum)
    end
    cksum = cksumRegion(zeroByte, 1, 1, cksum)

    if #puz.copyright > 0 then
        cksum = cksumRegion(puz.copyright, 1, #puz.copyright, cksum)
    end
    cksum = cksumRegion(zeroByte, 1, 1, cksum)

    if #puz.notes > 0 then
        cksum = cksumRegion(puz.notes, 1, #puz.notes, cksum)
    end
    cksum = cksumRegion(zeroByte, 1, 1, cksum)

    for i = 1, puz.numclues do
        cksum = cksumRegion(puz.clues[i], 1, #puz.clues[i], cksum)
    end

    return cksum
end

local function fromRowCol(row, col)
    return row * 1000 + col
end

local function toRowCol(rowcol)
    return rowcol // 1000, rowcol % 1000
end

function loadPuzzleFile(name)
    local file, err = pdfile.open(name)
    if file == nil then
        return nil, err
    end

    local fileSize = pdfile.getSize(name)
    local fileData = file:read(fileSize)
    local puz = {}
    puz.chksum = string.unpack("<I2", fileData, 1)
    puz.version = string.unpack("z", fileData, 25)
    puz.width = string.unpack("I1", fileData, 45)
    puz.height = string.unpack("I1", fileData, 46)
    puz.numclues = string.unpack("<I2", fileData, 47)

    puz.solution = {}
    puz.grid = {}
    local solutionRow = {}
    local gridRow = {}
    local pos = 53
    for i = 1, puz.height do
        for j = 1, puz.width do
            solutionRow[j], pos = string.unpack("c1", fileData, pos)
            if solutionRow[j] == '.' then
                gridRow[j] = '.'
            else
                gridRow[j] = ' '
            end
        end

        puz.solution[i] = solutionRow
        puz.grid[i] = gridRow
        solutionRow, gridRow = {}, {}
    end

    pos += puz.width * puz.height
    puz.title, pos = string.unpack("z", fileData, pos)
    puz.author, pos = string.unpack("z", fileData, pos)
    puz.copyright, pos = string.unpack("z", fileData, pos)

    puz.clues = {}
    for i = 1, puz.numclues do
        puz.clues[i], pos = string.unpack("z", fileData, pos)
    end

    puz.notes, pos = string.unpack("z", fileData, pos)

    local acrossClue, downClue = {}, {}
    local clueNum = 1
    local clueUsed = false
    for i = 1, puz.height do
        for j = 1, puz.width do
            if needsAcrossNumber(puz, i, j) then
                acrossClue[#acrossClue + 1] = { clueNum, fromRowCol(i, j) }
                clueUsed = true
            end

            if needsDownNumber(puz, i, j) then
                downClue[#downClue + 1] = { clueNum, fromRowCol(i, j) }
                clueUsed = true
            end

            if clueUsed then
                clueNum += 1
                clueUsed = false
            end
        end
    end

    for i = 1, #acrossClue do
        table.insert(acrossClue[i], i)
    end

    for i = 1, #downClue do
        table.insert(downClue[i], i + #acrossClue)
    end

    puz.acrossClue = acrossClue
    puz.downClue = downClue

    local cksum = calcCheckSum(fileData, puz)

    file:close()
    return puz, nil
end

function loadPuzzleInfo(name)
    local file, err = pdfile.open(name)
    if file == nil then
        return nil, err
    end

    local fileSize = pdfile.getSize(name)
    local fileData = file:read(fileSize)
    local puz = {}
    puz.chksum = string.unpack("<I2", fileData, 1)
    puz.version = string.unpack("z", fileData, 25)
    puz.width = string.unpack("I1", fileData, 45)
    puz.height = string.unpack("I1", fileData, 46)

    local pos = 53 + puz.width * puz.height * 2
    puz.title, pos = string.unpack("z", fileData, pos)
    puz.author, pos = string.unpack("z", fileData, pos)
    puz.copyright, pos = string.unpack("z", fileData, pos)
    file:close()
    return puz, nil
end

function getClueNumber(puz, row, col)       -- returns clue number or nil for none
    local rowcol = fromRowCol(row, col)
    for i = 1, #puz.acrossClue do
        if rowcol == puz.acrossClue[i][2] then
            return puz.acrossClue[i][1]
        end
    end

    for i = 1, #puz.downClue do
        if rowcol == puz.downClue[i][2] then
            return puz.downClue[i][1]
        end
    end

    return nil
end

function needsAcrossNumber(puz, row, col)
    return puz.grid[row][col] ~= '.'
            and (col == 1 or puz.grid[row][col - 1] == '.')
            and col + 1 < puz.width
            and puz.grid[row][col + 1] ~= '.'
end

function needsDownNumber(puz, row, col)
    return puz.grid[row][col] ~= '.'
            and (row == 1 or puz.grid[row - 1][col] == '.')
            and row + 1 < puz.height
            and puz.grid[row + 1][col] ~= '.'
end

