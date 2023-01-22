# Minecraft Server Deployment Tools

Deploy your very own Minecraft server(s) to play with friends, across multiple
targets, with just a few commands!

Note that this user guide is targeted towards those deploying everything from a
UNIX-alike system, like macOS or GNU/Linux operating systems. You specific
results may vary if using Windows and *not* using the Windows Subsystem for
Linux (WSL).

***[ IN PROGRESS FROM HERE ]***

## How to use

Deployments are expected to be managed through the `Makefile` -- not the least
because the server versions are specified at the top of that file.

Some of the following targets allow/expect an `<edition>` argument, where
`<edition>` is one of "`bedrock`" or "`java`"

### Deployment targets available

The following table shows what deployment targets are available for use, as well
as how to use them.

| Target   | How to run
| :-----   | :---------
| Docker   | `make docker edition=<edition>`
| Vagrant  | `make vagrant edition=<edition> # (no edition will run a separate VM for both at once)`
| AWS      | See the `terraform/aws` subdirectory

If something happens where you need to manually stop the server(s) using the
***local*** targets (Docker, Vagrant, etc), run:

    make stop

## How to update

1. Change any relevant values in your config file
1. Run `make deploy` from the repo top-level
1. ???
1. Profit

For setting server Operators ("admins"), you have to wait for people to connect
to the server to find their XUIDs to put in your config file. Once you have
them, add them to your `server-cfg/*/permissions.json` file(s), and re-run the
deployment steps.

## Developer Notes

TBD.

## Roadmap

* Java to also deploy a [GeyserMC](https://geysermc.org/) server to translate
  packets from Bedrock clients
