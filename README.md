# Teleport Development Environment

This helps you run a local Teleport environment locally at https://go.teleport, with trusted local certificates.

It sets up a single Teleport service that runs the Auth and Proxy services, as well as a container to run Webpack so you can build both Teleport and the Web code at the same time.

File changes for the Teleport repo are sync'd and then [air](https://github.com/cosmtrek/air) watches for any changes to your local Teleport repo, and will rebuild and relaunch Teleport when you change a `.go` or `.yaml` file.

This uses caching for both Go and Webpack, so although the first initial run will take a few minutes, subsequent runs of `make start` will build both Teleport and the frontend and have them up and running in <5s.

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

### Building Enterprise

To build the enterprise version of `tctl`, `teleport` and the frontend, create a file called `.e`. 

You'll want to run `make build` instead of `make start` when swapping between enterprise and OSS.

### Commands

#### Opening a shell

You can open an interactive shell to either the frontend or Teleport via:

```
make teleport-shell
make frontend-shell
```

#### yarn

As there's a few Docker volume overrides on the webapps `node_modules` (to avoid your local `node_modules` from being sync'd in, so the Linux built `node_modules` persist), if you run any `yarn` command locally you'll also need to run it inside the frontend container.

To run the equivalent of `yarn` inside the container, you can run:

```
make yarn
```

When we build the Docker image, to be as fast as possible we run `yarn install --ignore-scripts`. This prevents all the Electron stuff being installed, which we don't need to build Teleport.

By default, if you run `make yarn` with no arguments after, it'll append `--ignore-scripts` to avoid it failing (Python does not exist in the container, so `node-pty` doesn't build). If you run `make yarn install`, you should instead run `make yarn install --ignore-scripts`. `--ignore-scripts` can't be appended to every operation, as there are some `yarn` commands that do not allow for that flag to be set. 

#### tctl

`tctl` lives inside the Teleport container, so to run the equivalent of `tctl get users`, you can run:

```bash
make tctl get users
```

### Adding another Teleport service

In the `docker-compose.yml`, you'll see there are two types of Teleport services running, and they're defined a little differently.

#### Services that rebuild on code changes

If you want to rebuild Teleport on every file change, you'll want to copy how the Auth Service (`go.teleport`) is setup, like this:

```yaml
  service-name:
    container_name: service-name
    build:
      dockerfile: development/teleport/Dockerfile
      context: ..
      target: live-reload
    volumes:
      - ../teleport:/app
      - /app/build
      - /go/pkg/mod
      - /root/.cache/go-build
      - ./data/service-name:/var/lib/teleport
      - ./teleport/.air.toml:/app/.air.toml
      - ./service-name/teleport.yaml:/etc/teleport.yaml
```

And create a folder called `<service-name>` with a `teleport.yaml` inside, configured how you need it to be. You might find it useful to add a static token to `teleport/teleport.yaml`, so the Teleport service can instantly join the Auth Service.

The key things in this config are the `target` being `live-reload` - this uses the `Dockerfile` up until it's built `tctl`, and then `air` will run which will build Teleport, start it, and rebuild it and restart it on file changes.

#### Services that do not need to rebuild on code changes

If you're only working the Auth Service code, it would be a bit annoying if you were running an SSH agent and that also kept rebuilding, even though you're not editing the code.

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

The `target` that's specified is now `static`, which will build `tctl`, skip past `air`, build `teleport` and the run `teleport start -d`. This means you now have a static instance which won't respond to code changes.

You'll still need to create a folder for `<service-name>` with a `teleport.yaml` file like mentioned above.

### Other info

#### Only running Teleport, not Webpack too

You can go into "solo" mode, where Webpack isn't running alongside Teleport and instead you're just getting the webassets built into the Teleport binary.

To do this, create a file called `.solo`. The presence of this file will result in `docker-compose.solo.yml` being the compose file (so all `make` targets will still work with the different file) and you'll be running Teleport without Webpack in front.

When swapping between solo mode and normal, you just need to re-run `make start`. There's nothing that needs to be rebuilt.

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
