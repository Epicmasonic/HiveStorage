-- HiveStorage client security configuration.
-- Set this on each client computer. Never publish your real key.
return {
	-- The computer ID of the HiveStorage server.
	serverId = 0,

	-- Must exactly match server/security.lua.
	sharedSecret = "REPLACE-WITH-A-LONG-RANDOM-SECRET"
}
