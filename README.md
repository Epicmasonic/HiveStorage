# HiveStorage

A ComputerCraft storage interface using Create peripherals and Rednet.

## Security setup

HiveStorage now requires both a shared secret and an allowlisted computer ID. The server rejects requests from computers that are not explicitly authorized. The `emptyPocket` administrative command has a separate admin allowlist.

1. On the server computer, edit `server/security.lua`.
   - Replace `sharedSecret` with a long, randomly generated secret (at least 32 characters).
   - Add each permitted client computer ID to `authorizedClients`, for example `[12] = true`.
   - Add only trusted administrator computer IDs to `authorizedAdmins`. Admins must also appear in `authorizedClients`.
2. On each client computer, edit `client/helpers/security.lua`.
   - Set `serverId` to the server computer's ComputerCraft ID.
   - Set `sharedSecret` to exactly the same value as the server.
3. Keep the secret private. Do not commit your real configuration values to a public repository.

Example server allowlists:

```lua
authorizedClients = {
    [12] = true,
    [13] = true
},
authorizedAdmins = {
    [12] = true
}
```

## What the checks do

- Requests are sent directly to the configured server ID instead of broadcast.
- The server checks the Rednet source computer ID and shared secret before processing commands. The user-supplied `sender` field is not treated as an identity.
- Only admin-allowlisted clients can run `emptyPocket`.
- Item requests contain only an item name and optional amount. The server resolves item metadata from its own stock rather than trusting client-supplied metadata.
- Amounts must be whole numbers from 1 to 4096.
- Clients accept responses only from the configured server ID and with the shared secret.

## Limitations

Rednet does not provide encryption or cryptographic message authentication. A shared secret sent over the air can potentially be observed by someone monitoring the wireless network; computer-ID allowlisting is an additional access-control layer, not a substitute for encrypted transport. Use this on a trusted network, keep client computers physically secure, and rotate the secret if a client is compromised.

The configuration files in this repository contain placeholders and intentionally fail closed until configured.
