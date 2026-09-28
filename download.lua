---@diagnostic disable: undefined-global, undefined-field, trailing-space

local function findWirelessModem()
	return peripheral.find("modem", function(_, modem)
		return modem.isWireless()
	end)
end

local serverFiles = {
	"server.lua"
}
local clientFiles = {
	"client.lua",
	"helpers/dataHandling.lua",
	"helpers/remotes.lua",
	"helpers/ui.lua",
	"helpers/pages/collection.lua"
}

print("Do you want to instead the [S]erver, the [C]lient or [B]oth? (S/C/B)\n")

local wantsServer = false
local wantsClient = false
local warned = false
while true do
	local _, key = os.pullEvent("key")
	if key == keys.s then
		wantsServer = true
		
		if not findWirelessModem() then
			warned = true
			print("Warning: I couldn't find any attached wireless modems. You'll need one before you can use the code!")
		end
		if not peripheral.find("Create_StockTicker") then
			warned = true
			print("Warning: I couldn't find any attached Stock Tickers. You'll need one before you can use the code!")
		end
		if not peripheral.find("Create_Packager") then
			warned = true
			print("Warning: I couldn't find any attached Packagers. While you can still use the code without one, you will not be able to use all the features. (Most notably, you won't be able to send items back into storage.)")
		end
		
		break
	elseif key == keys.c then
		wantsClient = true
		
		if not findWirelessModem() then
			warned = true
			print("Warning: I couldn't find any attached wireless modems. You'll need one before you can use the code!")
		end
		
		break
	elseif key == keys.b then
		wantsServer = true
		wantsClient = true
		break
	end
end

if warned then
	print("Press any key to continue...")
	os.pullEvent("key")
end

fs.delete("hiveStorage")
if wantsServer then
	local basePath = "hiveStorage"
	if wantsClient then basePath = basePath.."/server" end
	
	for _, file in ipairs(serverFiles) do
		shell.run("wget https://github.com/Epicmasonic/HiveStorage/raw/main/server/"..file.." "..basePath.."/"..file)
	end
end

if wantsClient then
	local basePath = "hiveStorage"
	if wantsServer then basePath = basePath.."/client" end
	
	for _, file in ipairs(clientFiles) do
		shell.run("wget https://github.com/Epicmasonic/HiveStorage/raw/main/client/"..file.." "..basePath.."/"..file)
	end
end