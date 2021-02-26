# Valheim Dedicated Server Scripts
This repo contains scripts and service files that I use to run a set of private Valheim servers.  
The game is in an early-release alpha state and sees frequent updates. Since we also depend on quality-of-life modifications like Valheim Plus, which also sees a rapid development schedule (one that must meet and often exceed Valheim's), I find myself maintaining the server in some way on a daily basis.  
  
Some of this stuff will be unique to my setup, but over time I will rewrite scripts to be more system-agnostic.  
I don't think I can account for the privilege constraints one might have via a hosting provider, so that will remain out of scope for my development efforts, at least for the time being. You're free to share what you can and cannot do on the issue tracker and I'll see what I can do to account for that, though.  
  
Last but not least, I hope this helps and makes your life easier.  

## Scripts
Functional areas covered are:
* Downloading the Valheim dedicated server
* Updating the dedicated server
* Installing Valheim Plus
* Configuring Valheim Plus
* Running and stopping the dedicated server in a graceful/reliable way.
* Cleaning up logging
* Backing up Valheim worlds

### installer-updater.sh
This is an interactive script that currently can:
* Obtain the latest release assets of Valheim Plus (upon your choosing)
* Extract/install a specified release file
* Back up the `valheim_plus.cfg` file

I am mulling over some additional features:
* Download and/or re-download the Valheim dedicated server itself
* Merge `valheim_plus.cfg` file changes upon new releases/configs being released
* Gracefully or automatically handle updates to Valheim itself and/or Valheim Plus.

### backup.sh
This script is copied from an excellent docker container, normally executed by supervisord. For now, since this is running natively and not within an ephemeral container session, I've made some amendments to this script.

It now will not backup, or rotate backups, if a Valheim server process was not detected. This is to prevent them from rotating out if the game service/servers have been off for a long time. If you were running the docker container, this wouldn't be an issue; if the container (realistically the game server) is stopped, the script isn't running on a schedule.

There is a service unit for this script, and it maintains its own timer. It is not run via cron.  
It can be run manually or on-demand.  
It currently expects environment variables or direct modification of the script itself.  

This service will undergo a total rewrite - mainly to be more of my own making, but I may go a route of making it more interactive and handle restores as well.

### start-{world-name}.sh
Typically all mods for Valheim depend on unstripped Unity Engine libraries. These are included with BepInEx, a loader for such libraries.  
The dedicated server itself is launched via shell script, which loads these libraries, then the game server itself.  
Since the included scripts are typically overwritten with/by defaults upon updating/reinstalling BepInEx, instructions suggest copying the files and calling those, as they would be permanent.

For completeness, I've included our start files. You can use these as an example, if desired.  
Also note that these are based on the previous release line of BepInEx. It has since had its own proper Linux server release, which I imagine to be even easier to use. The start scripts will likely see a rewrite soon.

## Systemd Service Files
I've included our service files, in case they are desired. Of all the suggestions I've seen online, I think these sould work best. But to explain how they work and what they do:  
`User=valheim` - Service account being used to run the service (best to not run stuff as root, if you don't have to).  
`WorkingDirectory=/opt/valheim-server/server` - Set the working directory or path of the server. This is because the BepInEx loader uses local paths (`pwd`).  
`ExecStart=/opt/valheim-server/scripts/start-testkitchen.sh` - This is the actual script called. Note that this resides outside of the server files directory, so it persists on update/reinstall/deletion.  
`Restart=on-failure` - Restart the service if it fails. So far hasn't been an issue.  
`KillSignal=SIGINT` - Killing Valheim incorrectly can result in corrupted world saves. This is the safe way to stop the service.  
`StandardOutput=syslog` - Optional. I log to the local syslogger. It's chatty, but rsyslog (or syslog-ng) on the system will take care of rotation. Furthermore, I ship logging to a centralized syslog server, for retention, analytics and general convenience.  
`StandardError=syslog`  
`SyslogIdentifier=valheim-server-testkitchen` - The service itself will tag its events accordingly. It's helpful, as you can filter for it.  

If you don't go the syslog route (maybe your provider doesn't want that, or you're using a container and aren't shipping syslogging there, etc), then you can always log to a file:  
`StandardOutput=file:/path/log.ext`  
`StandardError=file:/path/log.ext`  
Note that this will not rotate by default (you may need to set up logrotate), but it's nice that you can easily direct logging to a persistent/mapped volume.
Finally this assumes you're using a version of systemd that can log to file. Ubuntu 17.10 might be the first of those.

## Applicable Server Notes
The dedicated server instances are running in an ESXi VM on Ubuntu Server 20.10. It's currently over-specced with 6 vCPUs, 8GB of RAM, 200GB of storage for /opt
We for now base our server files in /opt/valheim-server:
- The `./server` directory is the content root of the application downloaded from Steam.
- The `./config` directory is the persistent data we want to preserve when running the valheim dedicated server, defined in the initialization script as arguments `-savedir "/opt/valheim-server/config"`
- The `./scripts` directory contains the service scripts but generally these can go anywhere (ensure you update the systemd service units, accordingly).
- The `./backups` directory contains world backups.

If/when we move to contianers, it's super simple to just map the directories above and continue. We've moved on and off containers easily and for now run "native" due to simplicity with modding. Containers are predominantly moving to directly support BepInEx and such, but I think that whole space needs a bit more time before we move back to them. For instance, I need to see how they handle game and mod/library updates, backups, signals, mappings and modding capabilities, etc.

We depend on docker for steamcmd (for one, it's no longer in Ubuntu 20.10 repos, seemingly), mostly so we don't have to crap up the system with custom repos and dependencies. When run in scripts, it's also set up to be ephemeral and delete itself upon completing.

We also run a webserver on docker to share a basic info/landing page and serve out specific files right from the game's server files (`valheim_plus.cfg`). This ensured people had access to the current exact config, as we do mod+config enforcement. Though as of Valheim Plus 0.9, configs are actually pushed to the client upon connecting. Still, best install the config during each update, in case you go in solo play mode (you'd load the default config, which is not desirable since our server uses an increased item stack limit; you'd lose everything above the default limit once you load into your solo world).

Lastly, off the top of my head, dependencies for now would be satisfied with:
`apt-get install docker.io wget curl libc6-dev unzip zip tar` (for Ubuntu - use your intuition for package management on other distros).

## Our Valheim Plus Config
Finally, our config is shared for reference, but also as a launching point for our small community to submit change suggestions and such.
Admittedly I'm new to git, so it's another way of getting a feel for owning a repo and taking contributions. :P
