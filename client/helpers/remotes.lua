---@diagnostic disable: undefined-global, undefined-field, trailing-space

local security = require("helpers.security")
local PROTOCOL = "HiveStorage"
local RESPONSE_TIMEOUT = 5

local function validSecret(secret)
	return type(secret) == "string"
		and #secret >= 32
		and secret ~= "REPLACE-WITH-A-LONG-RANDOM-SECRET"
end

assert(type(security.serverId) == "number"
	and security.serverId > 0
	and security.serverId == math.floor(security.serverId),
	"Set the HiveStorage server computer ID in client/helpers/security.lua.")
assert(validSecret(security.sharedSecret),
	"Set the sharedSecret in client/helpers/security.lua to match the server.")

local function findWirelessModem()
	return peripheral.find("modem", function(_, modem)
		return modem.isWireless()
	end)
end

local modem = findWirelessModem()
assert(modem, "Could not find a wireless modem.")
local modemName = peripheral.getName(modem)

local function request(command, arguments)
	rednet.open(modemName)
	rednet.send(security.serverId, {
		command = command,
		auth = security.sharedSecret,
		arguments = arguments
	}, PROTOCOL)

	local timeout = os.startTimer(RESPONSE_TIMEOUT)
	while true do
		local event, sender, message = os.pullEvent()
		if event == "rednet_message"
			and sender == security.serverId
			and type(message) == "table"
			and message.command == "success"
			and message.auth == security.sharedSecret
			and type(message.arguments) == "table"
			and message.arguments.successful == command then
			rednet.close(modemName)
			return message.arguments.returnValue
		elseif event == "timer" and sender == timeout then
			rednet.close(modemName)
			error("HiveStorage server did not respond. Check the server ID, allowlist, and shared secret.")
		end
	end
end

local function getItems()
	local items = request("getStock")
	if type(items) ~= "table" then
		error("HiveStorage returned an invalid stock list.")
	end
	return items
end

local function emptyPocket()
	request("emptyPocket")
end

local function requestItem(item, amount)
	assert(type(item) == "table" and type(item.name) == "string",
		"Cannot request an item without a valid item name.")
	if amount ~= nil then
		assert(type(amount) == "number"
			and amount == amount
			and amount ~= math.huge
			and amount == math.floor(amount)
			and amount >= 1
			and amount <= 4096,
			"Requested amount must be a whole number between 1 and 4096.")
	end

	request("pocketRequest", {
		item = item.name,
		amount = amount
	})
end

return {
	getItems = getItems,
	emptyPocket = emptyPocket,
	requestItem = requestItem
}
