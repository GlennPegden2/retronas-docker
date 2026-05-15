This fork is to combine the ethernet networking over docker work I did for RetroNetSec and apply it to RetroNas so it can become a true dockerised version. This is a non-function Work-In-Progress

![logo](dist/retronas-logo.png)
# RetroNAS

## Project Information
* [Status](https://github.com/retronas/retronas/wiki/Status)
* [About](https://github.com/retronas/retronas/wiki/About)
* [HowTo](https://github.com/retronas/retronas/wiki)
* [Contributing](https://github.com/retronas/retronas/wiki/Contributing)
* [Thanks and Credits](https://github.com/retronas/retronas/wiki/Credits)

## WARNINGS
* [SECURITY](https://github.com/retronas/retronas/wiki/SECURITY-WARNING)
* [FILENAMES](https://github.com/retronas/retronas/wiki/Filenames)

## Community
* [Guides](https://github.com/retronas/retronas/wiki/Guides)
* [Coverage](https://github.com/retronas/retronas/wiki/Coverage)
* [Other Projects](https://github.com/retronas/retronas/wiki/Other-projects-and-sites)

## Docker (local build)

Build:

```bash
docker build -t retronas-docker .
```

Run interactive UI:

```bash
docker run --rm -it \
	--name retronas \
	--privileged \
	--network host \
	-v retronas_data:/data/retronas \
	-v retronas_etc:/opt/retronas/etc \
	-v retronas_log:/opt/retronas/log \
	-v retronas_cache:/opt/retronas/cache \
	retronas-docker
```

Use Docker Compose (equivalent setup):

```bash
docker compose up --build
```

Use Docker Compose development profile (safer defaults, no privileged host integration):

```bash
docker compose --profile dev up --build
```

The dev profile is intended for menu/script testing and other non-host-affecting workflows.

Stop and remove container (keep named volumes):

```bash
docker compose down
```

Stop and remove the development profile container:

```bash
docker compose --profile dev down
```

### Docker limitations and caveats

RetroNAS includes a lot of host-level management (systemd units, network services, firewalling, and kernel-oriented tasks). In a normal container, many of these actions are restricted or unsupported.

Features that are likely to fail or behave unexpectedly unless the container is run with very elevated privileges and host integration:

* systemd service lifecycle and journal operations (`ansible.builtin.systemd`, `ansible.builtin.service`, `journalctl`)
* host networking presets/services (for example `dnsmasq`, `dhcpcd`, `hostapd`, `NetworkManager`, `firewalld`)
* kernel/device level actions (for example `modprobe nbd`, FUSE and some mount/device workflows)
* host-focused control planes (for example cockpit integrations)

This image is best treated as a portable RetroNAS administration shell, with host-affecting modules executed only when the container has the required privileges and access.
ALSO docker only supports TCP/IP network, we need to implement the virtual ethernet networking over ssh from RetroNetSec.