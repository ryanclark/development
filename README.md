# Teleport Development Environment

This helps you run a local Teleport environment locally at https://go.teleport, with trusted local certificates.

It sets up a single Teleport service that runs the Auth and Proxy services, as well as a container to run Webpack so you can build both Teleport and the Web code at the same time.

File changes for the Teleport repo are sync'd and then [air](https://github.com/cosmtrek/air) watches for any changes to your local Teleport repo, and will rebuild and relaunch Teleport when you change a `.go` or `.yaml` file.

## Setup

This assumes you have your local directory structure setup something like (with the enterprise submodules initialised and updated for both `teleport` and `webapps`):


### Directory Setup

```
~/go/src/github.com/gravitational
└── teleport
│   └── api
│   │   │ go.mod
│   │   │ etc...
│   │
│   └── e
│       └── lib
│       └── tool
│       └── etc...
│   │
│   └── lib
│   │
│   └── tool
│   │
│   │ go.mod
│   │ etc...
│
└── webapps
│   │ packages
│   └── teleport
│   │   └── src
│   │       │ package.json
│   │       │ etc...
│   │
│   └── webapps.e
│   │   └── teleport
│   │       └── src
│   │           │ package.json
│   │           │ etc...
│   │
│   │ package.json
```

You should clone this directory so it's next to `teleport` and `webapps`.

```
~/go/src/github.com/gravitational
└── development
│   └── frontend
│   │   │ Dockerfile
│   │
│   └── teleport
│       │ Dockerfile
│   │
│   │ docker-compose.yml
│   │ etc...
│
└── teleport
│   └── api
│   │   │ go.mod
│   │   │ etc...
│   │
│   └── e
│       └── lib
│       └── tool
│       └── etc...
│   │
│   └── lib
│   │
│   └── tool
│   │
│   │ go.mod
│   │ etc...
│
└── webapps
│   │ packages
│   └── teleport
│   │   └── src
│   │       │ package.json
│   │       │ etc...
│   │
│   └── webapps.e
│   │   └── teleport
│   │       └── src
│   │           │ package.json
│   │           │ etc...
│   │
│   │ package.json
```

### mkcert

You'll need [mkcert](https://github.com/FiloSottile/mkcert), which is a quick and easy way to create local, trusted certificates.

If you're on macOS, you can install `mkcert` via

```bash
brew install mkcert
```

You should then trun
```bash
mkcert -install
```

Finally, to setup the certificates we need, run:

```bash
make cert
```

### Docker

You'll also need Docker running.

For an Apple Silicon Mac, I've found that enabling the new virtualization framework and therefore enabling VirtioFS accelerated directory sharing has yielded a very fast environment.

### DNS resolution

You'll need `go.teleport` to resolve to `0.0.0.0`. If you're using a service like NextDNS, it's easy to do this in their control panel.

If you aren't, you can `sudo vim /etc/hosts` and add:

```
0.0.0.0 go.teleport
```

If you wish to use a domain other than `go.teleport`, do a search and replace of any instance of `go.teleport` with the domain you pick. This is because the Docker container's hostname and name need to match, so Teleport realises it's running normally (as the proxy address and host address aren't different), and doesn't try to launch you into an app and put you in an infinite redirect loop when you try to go to the web UI.

## Running

To start, run:

```bash
make start
```

This will build the Docker containers if it's your first time running the command, and just start Teleport quickly if you've already ran the command before and have stopped running Teleport since.

The Teleport container has `tctl` built as part of the build process. This speeds up the build of Teleport by air when the container launches (as most of the Go packages have been downloaded and there's a populated Go cache), as well as provides `tctl` to be able to create the initial first user.

Once Teleport has finished initializing, you can run:

```bash
make setup
```

Which will create the initial admin user for you.

### Commands

#### Opening a shell

You can open an interactive shell to either the frontend or Teleport via:

```
make teleport-shell
make frontend-shell
```

#### yarn

As there's a few Docker volume overrides on the webapps `node_modules` (to avoid your local `node_modules` from being sync'd in, so the Linux built `node_modules` persist), if you run any `yarn` command locally you'll also need to run it inside the frontend container.

To run the equivalent of `yarn install` inside the container, you can run:

```
make yarn install
```

#### tctl

`tctl` lives inside the Teleport container, so to run the equivalent of `tctl get users`, you can run:

```bash
make tctl get users
```

### Other info

#### Config File

The config file for Teleport is in `teleport/teleport.yaml`. This is volume mounted into the container, so if Teleport is meant to react to a config change whilst running, you'll see this behavior.

If you need to change the config that requires a restart of Teleport, just stop your `make start` and re-run it.

#### Teleport License

This builds the Enterprise version of both Teleport and Webapps. It pulls in the enterprise license will full features by default, but if you wish to change it to any of the [other license types](https://github.com/gravitational/teleport.e/tree/master/fixtures), you can just change the file name that's mounted in `docker-compose.yml`.

#### Rebuilding the Docker image

If you need to rebuild `tctl` or rebuild the Docker images for whatever reason, you can run

```bash
make build
```

To completely wipe your workspace, run:

```bash
make clean
```

Which will remove all containers and volumes created by Docker.
