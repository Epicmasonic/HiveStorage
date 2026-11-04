-- HiveStorage server security configuration.
-- Edit these values on the server computer. Never publish your real key.
return {
	-- Use the SAME randomly generated secret in client/helpers/security.lua.
	-- Replace this placeholder with at least 32 characters.
	sharedSecret = "REPLACE-WITH-A-LONG-RANDOM-SECRET",

	-- Computer IDs allowed to view stock and request items.
	-- Example: [12] = true,
	authorizedClients = {},

	-- Computer IDs allowed to run administrative actions such as emptyPocket.
	-- Admins should also be listed in authorizedClients.
	authorizedAdmins = {}
}
