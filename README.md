Minecraft Bedrock Server Deployment Tools
=========================================

Deploy your very own Minecraft Bedrock server(s) to play with friends, with just
a few commands!

Structure & Design
------------------

This repo currently contains a lot of wrapper code for deploying a Bedrock
server to the AWS cloud platform, with much of the fancy automation tailored for
that. But, the tooling that gets wrapped is ultimately usable on any platform
you want -- including a server in your own home! Read on to learn more, but note
that the following will focus on those heavier abstractions.

The tools used in this repo were chosen to minimize complexity while still
providing a large feature set. That being said, this is still a relatively
complex toolkit. There is a large amount of shell code, a Python renderer script
& the YAML config file(s) that feeds it, Ansible configuration management files,
AWS CloudFormation infracode, and more -- all held together & orchestrated by a
Makefile.

The key elements of how this all works can be traced to two points: that
Makefile, and the top-level `render-all.py` script.

- GNU Make allows for complex collections of commands to be organized under
  single *targets*, and is often easier to write & use than writing your own
  CLI. It's also really old & really stable.

- The `render-all.py` script takes values from a configuration file, and renders
  template files in the tree using those values. Much of the paramterization in
  this codebase depends not on the individual tools' variable-processing engines
  (of which they all have an option for), but on Python's `jinja2` library,
  which this script uses. I intend this to make development maintenance easier,
  as it relegates a lot of the dynamism lift to a single tool, and indeed a
  single configuration file (which defaults to a top-level file named
  `config.yaml`). By putting values in that config file, the script will
  traverse the tree, read a template file (all of which have the term "`_jinja`"
  in them), and spits back out a file filled with the relevant values. It's
  pretty slick, if I do say so myself. I'm also working on a more general
  version, which you can find over at [its own
  repo](https://github.com/ryapric/ghostwriter).

For the included cloud platform infracode, I chose to go with [AWS
CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/Welcome.html)
(CFN). Despite its sometimes-glaring warts, using an alternative like Terraform
means managing another external tool with its own quirks and maintenance, and
I'd rather keep the actual deployment tooling as close to the source as
possible. Plus, the Makefile and `render-all.py` files makes most of the CFN
headaches much easier to deal with.

For actually deploying/configuring/managing the Bedrock server application, I
chose to go with Ansible. Ansible has some well-earned complaints against it for
production use, but for the specific use case of deploying a video game server
for fun, and its familiar SSH-driven interface, it was a pretty easy choice to
make.

There was also another piece of software that I needed for my own use, since I
play on PS4, which is a tool called [Phantom](https://github.com/jhead/phantom).
Phantom is a proxy server that tricks your PS4/XBox into thinking your Bedrock
server is running on LAN, when it really isn't. This is required because the
current version of the PS4/XBox clients don't support remote server connections
yet out of the box. Not everyone needs to use this, just those that play on one
of those home consoles. Note that the Nintendo Switch version requires a
different trick to connect to a remote server, which is out of the scope of this
toolset (but not too difficult to get working, all things considered).

With the design decisions now covered, the layout of the repo is as follows:

- `ansible/` has all the Ansible-related tooling, with a subfolder for each
  piece of deployed software (currently the Bedrock server, and the Phantom
  proxy).
- `aws-cloudformation/` has any CloudFormation Stacks (as `.yaml` files) needed
  to manage the infrastructure for the Bedrock server. Currently, the only one
  in there is `BedrockServer_jinja.yaml`, which is rendered by `render-all.py`.
- `tests/` will maybe one day have infra and server tests that I started working
  on, but is currently not used.
- `config-example.yaml` is what you should rename to whatever you want
  (`config.yaml` is the default expected), and has helpful instructions for what
  to put in there. This is the central hub for all your disparate configuration
  information for all the included tooling.
- `render-all.py` is the renderer that takes those configs, and puts them in all
  the right places. It currently relies on its Make target `render-all` to build
  the template file list, since it only takes a single file name as a CLI arg.
- `requirements.txt` is the `pip` requirements file that you will use to get
  Python dependencies for *your own machine*, the one running this codebase (and
  NOT the actual Bedrock server).

How to Use
----------

Note that this user guide is targeted towards those deploying everything from a
UNIX-alike system, like macOS or GNU/Linux operating systems. You specific
results may vary if using Windows and *not* using the Windows Subsystem for
Linux.

***IN PROGRESS FROM HERE***

***Prerequisites:***

- Deployment of software/configuration management:
    - GNU Make
    - Python 3
    - Python 3's package manager, `pip3`
        - Once you have `pip` installed, run `pip3 install -r requirements.txt`.
          Note that you may also need to pass the `--user` flag if on a
          Debian-based system.
    - An `ssh` client

- Infrastructure/hosting:
    - An AWS account
    - An AWS EC2 Key Pair (CloudFormation can't create/manage these for you,
      unlike Terraform, but whatever)
    - An IAM User or assumable Role (User is easier, if it's just for this use
      case)
    - Appropriate IAM permissions for your User/Role to manage the lifecycle of
      the CFN resources

1. Change any relevant values in your config file
1. Run `make deploy` from the repo top-level
1. ???
1. Profit

For setting server Operators ("admins"), you have to wait for people to connect
to the server to find their XUIDs to put in your config file. Once you have
them, add them to your config file, and re-run the deployment (`make deploy`).

Multiple servers
----------------

There's maybe a few reasons why you might want to be able to deploy multiple
Bedrock servers to the same relative environment (my own reason for adding the
functionality was to set another one up for a charity event).

To use this repo to manage multiple servers, you just need to pass in a Make
variable called `CONFIG` when you run the targets, pointing to the associated
config file:

    make target CONFIG=path/to/your/config.yaml

(Note again, though, that omitting this variable will default to the top-level
`config.yaml`)

Various values generated in cloud resources will take on the `server_name` that
you provide in your config file, where you fill in the other details for your
`server.properties` file generation.

Developer Notes
---------------

- xyz
