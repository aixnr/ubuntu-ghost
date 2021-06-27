# Ghost Install Script

**Table of Contents**

1. [Experimental, with Docker](#experimental-with-docker)
2. [Running on LXD](#running-on-lxd)
3. [Running a MySQL Server](#running-a-mysql-server)
4. [Installing Ghost](#installing-ghost)
5. [Setting Up Reverse Proxy Manually](#setting-up-reverse-proxy-manually)

## Experimental, With Docker

**!! Note !!** Experimental and does not work really well.

```bash
# Build
docker build --tag ghost .

# Run
docker run --rm \
  --mount type=bind,source="$(pwd)",target=/www \
  ghost ghost install local --dir /www
```

This whole thing does not quite work the way I wanted it to be, but I discovered a few interesting things along the way. In particular, some nice tricks regarding Docker.

Instead of using `Dockerfile` exclusively to install and configure packages, I delegated the installation directives to a dedicated `bash` install script, see `install_script.sh`. The script is modular, each distinct step is encapsulated within a function, so a user can include or exclude a part of the installation process easily. Another benefit is that I would reduce the number of layers, and potentially reducing the final size of the container image.

Part of playing around with `gosu` (because `ghost` CLI does not work well with `root` user), I used a `bash` script `entrypoint.sh` as the PID 1.

```bash
#!/usr/bin/env bash
set -e

if [[ "$1" = "ghost" ]]; then
  exec gosu node "$@"
fi

exec "$@"
```

This is a neat trick; if `bash` argument `$1` is `ghost`, it will run `gosu node`, de-escalating the privilege down to user `node` instead of running it as `root`. This translates into running the container with `docker run <container-name> ghost` to invoke `ghost` CLI. The added benefit is that it makes the container image flexible, where `docker run -it <container-name> /bin/bash` still gives a user access to `bash` shell inside of the container.

## Running on LXD

The `install_script.sh` is intended to run on a freshly-spun VPS. For testing, it runs well on LXD (Ubuntu `focal`) as well. Simply copy the whole script, run `cat > install.sh`, paste the content of the script into the terminal, and hit `ctrl` + `d`, then run `bash install.sh` to start the installation process. After that, create a new empty folder, assign the right permission, `cd` into it, then run the installation by issuing `ghost install`.

## Running a MySQL server

A MySQL server is run within the `lxc` container for simplicity.

Taken from Ghost [official installation guide](https://ghost.org/docs/install/ubuntu/).

```bash
# To set a password, run
sudo mysql

# Now update your user with this command
# Replace 'password' with your password, but keep the quote marks!
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password';

# Then exit MySQL
quit
```

Change `password` with something else.

## Installing Ghost

```bash
su node && cd && mkdir ghost_site && cd ghost_site
ghost install
```

## Setting Up Reverse Proxy Manually

**!! Note !!** This is the minimal reverse-proxy configuration.

During the `ghost` installation, keep the default `localhost:2368` url as this would automatically skip the `nginx` with SSL setup. I prefer to set up my own reverse-proxy.

```nginx
server {
  listen 8080;
  location / {
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header Host $http_host;
    proxy_pass http://127.0.0.1:2368;
  }

  client_max_body_size 50m;
}
```

Change the `listen` port; `8080` here is for testing.

Place this file at `/etc/nginx/sites-available/ghost.conf`, then run `sudo ln -s` to place it inside `/etc/nginx/sites-enabled/ghost.conf`. Remember to expose the port on the `lxc` container and run the `nginx` on the host (not on the container).

Additionally, edit the `url` field in the `config.production.json` to use the front-facing URL, since its default value is `http://localhost:2368`.
