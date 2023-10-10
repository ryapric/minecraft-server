# Minecraft Server Deployment Tools

Deploy your very own Minecraft server(s) to play with friends, across multiple
targets, with just a few commands!

Note that this user guide is targeted towards those deploying everything from a
UNIX-alike system, like macOS or GNU/Linux operating systems. You specific
results may vary if using Windows and *not* using the Windows Subsystem for
Linux (WSL).

***NOTE: Java server support is experimental***.

***[ IN PROGRESS FROM HERE ]***

## How to use

Deployments are expected to be managed through the `Makefile` -- not the least
because the default server versions are specified at the top of that file.

### Deployment targets available

The following table shows what deployment targets are available for use, as well
as how to use them.

| Target   | How to run
| :-----   | :---------
| Docker   | `make docker [ var=value ]`
| Vagrant  | `make vagrant [ var=value ]`
| AWS      | See the `terraform/aws` subdirectory

Most targets support the Makefile variables `bedrock_version`, `java_version`,
`edition`, and `world_data_dir`. The Makefile sets defaults if not provided, but
they can be overridden by setting them at call-time via e.g. `make docker
edition=java` etc.

| Variable name     | Default          | Definition
| :---------------- | :--------------- | :---------
| `edition`         | `bedrock`        | Which edition of the server to run, i.e. `bedrock` or `java`.
| `world_data_dir`  | `./data/default` | Which local directory to use for world data. This allows for localy storing different world data but having the desired one mounted to a single place in a running container.
| `bedrock_version` | See `Makefile`   | Desired version of the Bedrock server. Specified as `MAJOR.MINOR.PATCH`.
| `java_version`    | See `Makefile`   | Desired version of the Java server. Specified as `MAJOR.MINOR`, *without* a `PATCH`.

If something happens where you need to manually stop the server(s) using the
***local*** targets (Docker, Vagrant, etc), run:

    make stop

## How to update

1. Change any relevant values in your config file
1. Run `make <deploy_target>` from the repo top-level
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
