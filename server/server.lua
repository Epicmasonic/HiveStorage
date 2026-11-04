---@diagnostic disable: undefined-global, undefined-field, trailing-space

term.clear()
term.setCursorPos(1, 1)

---------------------------------------------------
--                     Setup                     --
---------------------------------------------------

local security = require("security")
local PROTOCOL = "HiveStorage"
local MAX_REQUEST_AMOUNT = 4096

local function validSecret(secret)
	return type(secret) == "string"
		and #secret >= 32
		and secret ~= "REPLACE-WITH-A-LONG-RANDOM-SECRET"
end

assert(validSecret(security.sharedSecret), "Configure a unique sharedSecret of at least 32 characters in server/security.lua.")

local function validIdList(list)
	assert(type(list) == "table", "Client ID allowlists must be tables.")
	for id, allowed in pairs(list) do
		assert(type(id) == "number" and id > 0 and id == math.floor(id) and allowed == true,
			"Allowlist entries must be [computerId] = true.")
	end
end

validIdList(security.authorizedClients)
validIdList(security.authorizedAdmins)

for id in pairs(security.authorizedAdmins) do
	assert(security.authorizedClients[id] == true, "Every admin must also be an authorized client.")
end

local function findActualModem()
	return peripheral.find("modem", function(_, modem)
		return modem.isWireless()
	end)
end

local stock = peripheral.find("Create_StockTicker")
local pocket = peripheral.find("Create_Packager")
local modem = findActualModem()
assert(stock, "Could not find a Create Stock Ticker.")
assert(pocket, "Could not find a Create Packager.")
assert(modem, "Could not find a wireless modem.")

local modemName = peripheral.getName(modem)
rednet.open(modemName)

---------------------------------------------------
--               Helper functions                --
---------------------------------------------------

--- Prints out a message with a timestamp.
local function log(message, sender)
	print("\n")
	term.setTextColor(colors.gray)
	print(sender .. " (" .. textutils.formatTime(os.time()) .. " Day " .. os.day() .. ")")
	term.setTextColor(colors.white)
	write(message)
end

local function sendSuccess(id, successful, returnValue)
	rednet.send(id, {
		sender = "Server",
		command = "success",
		auth = security.sharedSecret,
		arguments = {
			successful = successful,
			returnValue = returnValue
		}
	}, PROTOCOL)
end

local function findStockItem(name)
	for _, item in ipairs(stock.stock(true)) do
		if item.name == name then
			return item
		end
	end
	return nil
end

---------------------------------------------------
--                Handle requests                --
---------------------------------------------------

local function emptyPocket(sender)
	pocket.setAddress("Storage")
	repeat
		pocket.makePackage()
	until next(pocket.list()) == nil
	log("Emptied the pocket", sender)
end

local function pocketRequest(sender, arguments)
	if type(arguments) ~= "table" then
		return
	end

	local requestedName = arguments.item
	if type(requestedName) ~= "string" or #requestedName == 0 or #requestedName > 256 then
		return
	end

	-- Never trust item metadata supplied by a client. Resolve the item against
	-- the server's own stock and use that canonical record.
	local item = findStockItem(requestedName)
	if not item then
		log("Rejected a request for an item that is not in stock", sender)
		return
	end

	local amount = arguments.amount
	if amount == nil then
		amount = item.maxCount or 1
	end
	if type(amount) ~= "number"
		or amount ~= amount
		or amount == math.huge
		or amount == -math.huge
		or amount ~= math.floor(amount)
		or amount < 1
		or amount > MAX_REQUEST_AMOUNT then
		log("Rejected an invalid item request amount", sender)
		return
	end

	local count = stock.requestFiltered("Pocket", {
		_requestCount = amount,
		name = item.name,
		displayName = item.displayName
	})

	log("Sent " .. tostring(count) .. " copies of " .. item.displayName .. " to the pocket", sender)
end

local function handleRequest(id, message)
	local sender = "Computer ID " .. tostring(id)

	-- Rednet payloads are untrusted input. Validate every layer before use.
	if type(message) ~= "table" then
		log("Rejected a malformed message", sender)
		return
	end
	if security.authorizedClients[id] ~= true then
		log("Rejected a request from an unauthorized computer", sender)
		return
	end
	if message.auth ~= security.sharedSecret then
		log("Rejected a request with an invalid authentication key", sender)
		return
	end
	if type(message.command) ~= "string" then
		log("Rejected a message without a valid command", sender)
		return
	end

	if message.command == "ping" then
		sendSuccess(id, "ping")
		log("Got pinged", sender)
	elseif message.command == "getStock" then
		sendSuccess(id, "getStock", stock.stock(true))
		log("Checked storage", sender)
	elseif message.command == "pocketRequest" then
		pocketRequest(sender, message.arguments)
		sendSuccess(id, "pocketRequest")
	elseif message.command == "emptyPocket" then
		if security.authorizedAdmins[id] ~= true then
			log("Rejected an administrative request from a non-admin client", sender)
			return
		end
		emptyPocket(sender)
		sendSuccess(id, "emptyPocket")
	else
		log("Rejected an unknown command", sender)
	end
end

---------------------------------------------------
--       The stuff that will actually run        --
---------------------------------------------------

local function listenForRequests()
	while true do
		local id, message = rednet.receive(PROTOCOL)
		handleRequest(id, message)
	end
end

log("Started running", "Server")
local ok, errorMessage = xpcall(listenForRequests, debug.traceback)

rednet.close(modemName)

if not ok then
	term.clear()
	term.setCursorPos(1, 1)

	term.setTextColor(colors.gray)
	print("Something went wrong! :(")
	term.setTextColor(colors.white)
	print(errorMessage)
end
