# Teleport Development Environment

This helps you run a local Teleport environment locally at https://go.teleport, with trusted local certificates.

It sets up a single Teleport service that runs the Auth and Proxy services, as well as a container to run Webpack so you
can build both Teleport and the Web code at the same time.

File changes for the Teleport repo are sync'd and then [air](https://github.com/cosmtrek/air) watches for any changes to
your local Teleport repo, and will rebuild and relaunch Teleport when you change a `.go` or `.yaml` file.

This uses caching for both Go and Webpack, so although the first initial run will take a few minutes, subsequent runs
of `make start` will build both Teleport and the frontend and have them up and running in <5s.

This should work on all backend versions of Teleport, and webapps from v10 onwards.

## Setup

### Directory Setup

This assumes you have your local directory structure setup something like:

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

You don't have to have the enterprise submodules cloned if you do not want to build the enterprise version.

### mkcert

You'll need [mkcert](https://github.com/FiloSottile/mkcert), which is a quick and easy way to create local, trusted
certificates.

If you're on macOS, you can install `mkcert` via

```bash
brew install mkcert
```

You should then run

```bash
mkcert -install
```

Finally, to setup the certificates we need, run:

```bash
make cert
```

### Docker

You'll also need Docker running.

For an Apple Silicon Mac, I've found that enabling the new virtualization framework and therefore enabling VirtioFS
accelerated directory sharing has yielded a very fast environment.

### DNS resolution

You'll need `go.teleport` to resolve to `0.0.0.0`. If you're using a service like NextDNS, it's easy to do this in their
control panel.

If you aren't, you can `sudo vim /etc/hosts` and add:

```
0.0.0.0 go.teleport
```

If you wish to use a domain other than `go.teleport`, do a search and replace of any instance of `go.teleport` with the
domain you pick. This is because the Docker container's hostname and name need to match, so Teleport realises it's
running normally (as the proxy address and host address aren't different), and doesn't try to launch you into an app and
put you in an infinite redirect loop when you try to go to the web UI.

## Running

To start, run:

```bash
make start
```

This will build the Docker containers if it's your first time running the command, and just start Teleport quickly if
you've already ran the command before and have stopped running Teleport since.

The containers will run in detached mode, so you won't have any logs immediately available to you in the console.

The Teleport container has `tctl` built as part of the build process. This speeds up the build of Teleport by air when
the container launches (as most of the Go packages have been downloaded and there's a populated Go cache), as well as
provides `tctl` to be able to create the initial first user.

Once Teleport has finished initializing, you can run:

```bash
make setup
```

Which will create the initial admin user for you.

### Logs

To get and follow the logs from the frontend or the logs from Teleport, you can run

```bash
make frontend-logs
make teleport-logs
```

To get any other logs you can run

```bash
make logs servicename # or
make logs -- -f servicename # -- is needed when passing in flags (such as -f for follow)
```

### Stopping

To stop the running Docker contains, run:

```bash
make stop
```

### Swapping between Teleport versions

As this lives next to your `teleport` and `webapps` directories, you can just checkout whatever branch you need to work
on in either repo.

#### teleport

When changing the major version of `teleport`, you should re-run `make build`. This is because `tctl` is built to live
inside the container, as is `teleport` if you're using static services that don't live reload.

`tctl` and `teleport` change quite a bit between major versions, so a rebuild ensures these binaries are on the same
major version that the live reloading services are on.

#### webapps

When changing the major version of `webapps`, you should make sure you run `yarn` inside `webapps` before
re-running `make start`. There shouldn't be any need to run `make build`.

### Building Enterprise

To build the enterprise version of `tctl`, `teleport` and the frontend, create a file called `.e`.

You'll want to run `make build` first before re-running `make start` when swapping between enterprise and OSS.

> You can choose not to run a build to just swap the frontend between OSS and Enterprise, but a rebuild is needed for
> the `tctl` and `teleport` binaries inside the containers.
>
> If you're using live-reload defined services, you may not need to rebuild as the presence of the `.e` file tells air
> to build either the OSS or Enterprise. The `tctl` binary in the container will still be incorrect, however.
>
> If you're using static defined services, you will need to rebuild.

### Commands

#### Opening a shell

You can open an interactive shell to either the frontend or Teleport via:

```
make teleport-shell
make frontend-shell
```

#### tctl

`tctl` lives inside the Teleport container, so to run the equivalent of `tctl get users`, you can run:

```bash
make tctl get users
```

### Adding another Teleport service

In the `docker-compose.yml`, you'll see there are two types of Teleport services running, and they're defined a little
differently.

#### Services that rebuild on code changes

If you want to rebuild Teleport on every file change, you'll want to copy how the Auth Service (`go.teleport`) is setup,
like this:

```yaml
  service-name:
    container_name: service-name
    build:
      dockerfile: development/teleport/Dockerfile
      context: ..
      target: live-reload
    volumes:
      - ../teleport:/app/:rw,delegated
      - /app/build
      - ./data/cache/service-name/go-pkg:/go/pkg/mod:rw,delegated
      - ./data/cache/service-name/go:/root/.cache/go-build,delegated
      - ./data/service-name:/var/lib/teleport
      - ./teleport/.air.toml:/app/.air.toml
      - ./service-name/teleport.yaml:/etc/teleport.yaml
```

And create a folder called `<service-name>` with a `teleport.yaml` inside, configured how you need it to be. You might
find it useful to add a static token to `teleport/teleport.yaml`, so the Teleport service can instantly join the Auth
Service.

The key things in this config are the `target` being `live-reload` - this uses the `Dockerfile` up until it's
built `tctl`, and then `air` will run which will build Teleport, start it, and rebuild it and restart it on file
changes.

#### Services that do not need to rebuild on code changes

If you're only working the Auth Service code, it would be a bit annoying if you were running an SSH agent and that also
kept rebuilding, even though you're not editing the code.

To setup a service in this way, copy the configuration for the `node` service in `docker-compose.yml`.

```yaml
  service-name:
    container_name: service-name
    build:
      dockerfile: development/teleport/Dockerfile
      context: ..
      target: static
    volumes:
      - /app/build
      - ./data/service-name:/var/lib/teleport
      - ./service-name/teleport.yaml:/etc/teleport.yaml
```

The `target` that's specified is now `static`, which will build `tctl`, skip past `air`, build `teleport` and the
run `teleport start -d`. This means you now have a static instance which won't respond to code changes.

You'll still need to create a folder for `<service-name>` with a `teleport.yaml` file like mentioned above.

### Other info

#### Only running Teleport, not Webpack too

You can go into "solo" mode, where Webpack isn't running alongside Teleport and instead you're just getting the
webassets built into the Teleport binary.

To do this, create a file called `.solo`. The presence of this file will result in `docker-compose.solo.yml` being the
compose file (so all `make` targets will still work with the different file) and you'll be running Teleport without
Webpack in front.

When swapping between solo mode and normal, you just need to re-run `make start`. There's nothing that needs to be
rebuilt.

#### Config File

The config file for Teleport is in `teleport/teleport.yaml`. This is volume mounted into the container, so if Teleport
is meant to react to a config change whilst running, you'll see this behavior.

If you need to change the config that requires a restart of Teleport, just stop your `make start` and re-run it.

#### Teleport License

When enterprise is enabled, this builds the Enterprise version of both Teleport and Webapps. It pulls in the enterprise
license will full features by default, but if you wish to change it to any of
the [other license types](https://github.com/gravitational/teleport.e/tree/master/fixtures), you can just change the
file name that's mounted in `docker-compose.yml`.

#### Rebuilding the Docker image

If you need to rebuild `tctl` or rebuild the Docker images for whatever reason, you can run

```bash
make build
```

You'll then need to re-run `make start`.

To completely wipe your workspace, run:

```bash
make clean
```

Which will remove all containers and volumes created by Docker.

#### Make commands reference

You can also run `make help` to get a list of the available Make targets.

**Controlling container lifecycle**

- `make start` - starts (and builds, if not present) the Docker containers in detached mode
- `make start-attach` - starts (and builds, if not present) the Docker containers and attaches to the output of them
- `make stop` - stops all containers

**Building & cleaning**

- `make build` - builds/rebuilds the Docker images
- `make clean` - removes all Docker containers and volumes
- `make down` - removes all Docker containers

**Setup**

- `make cert` - creates the self-signed certificate for `go.teleport` and `*.teleport` with `mkcert`
- `make setup` - sets up the default admin user via an alias
  to `make tctl users add admin --roles=editor,access --logins=root,ubuntu,ec2-user`

**Commands**

- `make frontend-logs` - alias for `make logs -- -f frontend`
- `make frontend-shell` - open an interactive shell inside the frontend container
- `make logs <command>` - runs `docker compose logs <command>`
- `make tctl <command>` - runs `tctl` inside the Teleport container
- `make teleport-logs` - alias for `make logs -- -f go.teleport`
- `make teleport-shell` - open an interactive shell inside the Teleport container
