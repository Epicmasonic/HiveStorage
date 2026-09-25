---@diagnostic disable: undefined-global, undefined-field, trailing-space

local function findWirelessModem()
	return peripheral.find("modem", function(_, modem)
		return modem.isWireless()
	end)
end

local modemName = peripheral.getName(findWirelessModem())

local myName
if os.getComputerLabel() then
	myName = os.getComputerLabel()
else
	myName = "Computer ID "..textutils.serialize(os.getComputerID())
end

local function getItems()
	rednet.open(modemName)
	rednet.broadcast(
		{
			sender = myName,
			command = "getStock"
		},
		"HiveStorage"
	)
	
	local message
	repeat
		_, message = rednet.receive("HiveStorage")
	until message and message.arguments.successful == "getStock"
	rednet.close()
	
	return message.arguments.returnValue
end

local function emptyPocket()
	rednet.open(modemName)
	rednet.broadcast(
		{
			sender = myName,
			command = "emptyPocket"
		},
		"HiveStorage"
	)
	rednet.close()
end

local function requestItem(item)
	rednet.open(modemName)
	rednet.broadcast(
		{
			sender = myName,
			command = "pocketRequest",
			arguments = {
				item = item
			}
		},
		"HiveStorage"
	)
	rednet.close()
end

return {
	getItems = getItems,
	emptyPocket = emptyPocket,
	requestItem = requestItem
}