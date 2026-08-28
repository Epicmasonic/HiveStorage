---@diagnostic disable: undefined-global, undefined-field, trailing-space

local monitor = peripheral.find("monitor")
shell.run("monitor",peripheral.getName(monitor),"hiveStorage/server.lua")