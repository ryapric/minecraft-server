Minecraft Server Deployment Tools
=================================

Deploy your very own Minecraft server(s) to play with friends, with just a few
commands!

Structure & Design
------------------

TODO

How to Use
----------

Note that this user guide is targeted towards those deploying everything from a
UNIX-alike system, like macOS or GNU/Linux operating systems. You specific
results may vary if using Windows and *not* using the Windows Subsystem for
Linux (WSL).

***[ IN PROGRESS FROM HERE ]***

TODO

***Prerequisites:***

* Deployment of software/configuration management:
  * Terraform
  * An `ssh` client

* Infrastructure/hosting:
  * AWS:
    * An AWS account
    * An IAM User or assumable Role (User is easier, if it's just for this use
      case)
    * Appropriate IAM permissions for your User/Role to manage the lifecycle of
      the AWS resources

1. Change any relevant values in your config file
1. Run `make deploy` from the repo top-level
1. ???
1. Profit

For setting server Operators ("admins"), you have to wait for people to connect
to the server to find their XUIDs to put in your config file. Once you have
them, add them to your `server-cfg/*/permissions.json` file(s), and re-run the
deployment steps.

Developer Notes
---------------

TBD.

Roadmap
-------

* Java to also deploy a [GeyserMC](https://geysermc.org/) server to translate
  packets from Bedrock clients
