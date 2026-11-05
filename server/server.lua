---@diagnostic disable: undefined-global, undefined-field, trailing-space

term.clear()
term.setCursorPos(1, 1)

---------------------------------------------------
--                     Setup                     --
---------------------------------------------------

local function findActualModem()
    return peripheral.find("modem", function(_, modem)
        return modem.isWireless() -- Check this modem is wireless.
    end)
end

local stock = peripheral.find("Create_StockTicker")
local pocket = peripheral.find("Create_Packager")
local inventory = peripheral.find("inventoryManager")

local modem = findActualModem()
local modemName = peripheral.getName(modem)
rednet.open(modemName)

---------------------------------------------------
--               Helper functions                --
---------------------------------------------------

--- Prints out a message with a timestamp
--- @param message string The message to print
--- @param sender string Who is sending the message (for debugging)
--- @param fristTime boolean?
local function log(message, sender, fristTime)
    if not fristTime then
        print("\n")
    end
    term.setTextColor(colors.gray)
    print(sender.." ("..textutils.formatTime(os.time()).." Day "..os.day()..")")
    term.setTextColor(colors.white)
    write(message)
end

---------------------------------------------------
--                Handle requests                --
---------------------------------------------------

local function ping(sender, id)
    rednet.send(
        id,
        {
            sender = "Server",
            command = "success",
            arguments = {
                successful = "ping"
            }
        },
        "HiveStorage"
    )
    log("Got pinged", sender)
end

local pocketRequests = {}

local function emptyPocket(sender)
    pocketRequests[#pocketRequests + 1] = {
        command = "emptyPocket",
        sender = sender
    }
end

local function runEmptyPocket(sender)
    if inventory then
        for i = 9, 35 do
            inventory.removeItemFromPlayer("Up", {fromSlot = i})
        end
    end
    
    pocket.setAddress("(GroovyProto) Storage")
    repeat
        pocket.makePackage()
    until next(pocket.list()) == nil
    log("Emptied your inventory", sender)
end

local function pocketRequest(sender, item, amount)
    pocketRequests[#pocketRequests + 1] = {
        command = "pocketRequest",
        sender = sender,
        item = item,
        amount = amount or item.maxCount
    }
end

local function processPocketRequests()
    while true do
        local request = table.remove(pocketRequests, 1)
        if not request then
            sleep(0.1)
        elseif request.command == "emptyPocket" then
            runEmptyPocket(request.sender)
        else
            local item = request.item
            local count = stock.requestFiltered("(GroovyProto) Inventory", {
                _requestCount = request.amount,
                name = item.name,
                displayName = item.displayName
            })

            log("Sent "..count.." copies of "..item.displayName.." to your inventory", request.sender)

            if inventory and count > 0 then
                while true do
                    local foundCount = 0
                    for _, foundItem in ipairs(pocket.list()) do
                        if foundItem.name == item.name then
                            foundCount = foundCount + foundItem.count
                        end
                    end

                    if foundCount >= count then
                        break
                    end
                    sleep(1)
                end
                inventory.addItemToPlayer("Up", {name = item.name, count = count})
            end
        end
    end
end

---------------------------------------------------
--       The stuff that will actually run        --
---------------------------------------------------

local function listenForRequests()
    while true do
        local id, message = rednet.receive("HiveStorage")
        message.sender = message["sender"] or ("computer ID "..textutils.serialize(id))
        if message.command == "ping" then
            ping(message.sender, id)
        elseif message.command == "emptyPocket" then
            emptyPocket(message.sender)
        elseif message.command == "pocketRequest" then
            pocketRequest(message.sender, message.arguments.item, message.arguments.amount)
        elseif message.command == "getStock" then
            rednet.send(
                id,
                {
                    sender = "Server",
                    command = "success",
                    arguments = {
                        successful = "getStock",
                        returnValue = stock.stock(true)
                    }
                },
                "HiveStorage"
            )
            log("Checked storage", message.sender)
        else
            log("Got something weird:\n"..textutils.serialize(message), "Computer ID "..id)
        end
    end
end

log("Started running", "Server", true)
 -- I'm not super sure what a `xpcall` is but Copilot said to use it so that the modem will actually close when the program breaks. -- It looks a lot like a try catch?
local ok, errorMessage = xpcall(
    function()
        parallel.waitForAll(listenForRequests, processPocketRequests)
    end,
    debug.traceback
)

rednet.close(modemName)

if not ok then
    term.clear()
    term.setCursorPos(1,1)
    
    term.setTextColor(colors.gray)
    print("Something went wrong! :(")
    term.setTextColor(colors.white)
    print(errorMessage)
end
