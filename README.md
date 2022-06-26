# notion-backup-ocaml

A minimal OCaml program to backup your entire [Notion](https://notion.so) workspace, inspired by [`5hay/notionbackup`](https://github.com/5hay/notionbackup).

This project satisfies two goals of mine: (1) automate the backup of my Notion workspace (which is over 2000 pages) and (2) play around with my favorite programming language, OCaml.

```bash
> cd ~/notion-backup-ocaml && dune exec notion-backup-ocaml
Pages exported: 2017
Export created, downloading: https://s3.us-west-2.amazonaws.com/...
Download complete: ../notion_backup.zip%
```

## Usage

_Note: you'll need a basic OCaml toolset installed, including [Dune](https://dune.build/), a build system for OCaml. Installation instructions can be found at [ocaml.org](https://ocaml.org/docs/up-and-running)._

### Clone the repository

```bash
git clone https://github.com/dylanirlbeck/notion-backup-ocaml.git
```

### Set environment variables

Next, you'll need to create and set some environment variables. For this script to execute successfully, it'll need access to two environment
variables. You can set these in Bash/Zsh profile (i.e. `export NOTION_TOKEN_V2=<token_v2>`):

1. `NOTION_TOKEN_V2`: The `token_v2` cookies that Notion uses for
   authentication. The easiest way (that I've found) to obtain this token is to
   navigate to your [Notion workspace](https://notion.so) and open the browser's developer tools. Listed in the cookies for the website is an entry with the key `token_v2`
   the value for this key is your token. ([This article](https://www.redgregory.com/notion/2020/6/15/9zuzav95gwzwewdu1dspweqbv481s5) walks through the steps to do so.)
2. `NOTION_SPACE_ID`: The ID of the "root" page from which to perform the
   backup. The script will recursively backup all pages including and below this
   root. To obtain this ID, the easiest way is to head back to the Network tab
   in the browser developer tools after loading Notion. Look for any API request (to
   `https://www.notion.so/api/v3`) and the payload of the request
   should contain the `spaceId`. For example, I found the my space ID
   inside of a `getPageVisits` request.

### Build and execute

Once you've set the requisite environment variables, you should build and run the executable. (Dune provides a nice shortcut for this:
`dune exec`.)

```bash
cd notion-backup-ocaml

# Build _and_ execute in one command.
dune exec notion-backup-ocaml

# Alternatively, build and then execute.
dune build
./_build/default/bin/backup.exe
```

If everything was set up correctly, you should see a ZIP file show up in the
parent directory of `notion-backup-ocaml` with the name `notion-backup.zip`.

## Automating your Notion backup with `launchd` (macOS-only)

Using [`launchd`](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html),
a built-in MacOS utility with Cron-like functionality, I'm
able to automatically run this script to run once a day. There are a few steps
necessary to set up this automation.

### Write a shell script to be run by a launch agent

Under `/Library/Scripts`, create a bash/zsh script with the following naming
convention (suggested, but not strictly required):
`/Library/Scripts/org.<user>.notion-backup.sh`.

```bash
#!/bin/zsh

# Load shell profile, but the NOTION_TOKEN_V2 and NOTION_SPACE_ID environment variables
# in particular.
source /Users/<user>/.zshrc

# Execute the script.
./Users/<user>/notion-backup-ocaml/_build/default/bin/backup.exe
```

### Create a configuration file for your agent

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <!-- The label should be the same as the filename without the extension -->
    <string>org.<user>.notion-backup</string>
    <!-- Specify how to run your program here -->
    <key>Program</key>
    <string>/Library/Scripts/org.dylan.notion-backup.sh</string>
    <!-- Run once a day at 9:00AM-->
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>9</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>/tmp/org.<user>.notion-backup.stdout</string>
    <key>StandardErrorPath</key>
    <string>/tmp/org.<user>.notion-backup.stderr</string>
</dict>
</plist>
```

### Use `launchctl` to register the agent

Now that we have an executable script and agent configuration, we can register
the agent using `launchctl`.

```bash
> launchctl load /Library/LaunchAgents/org.<user>.notion-backup.plist

# Test that our agent was loaded.
> launchtl list | grep notion.backup
-	0	org.<user>.notion-backup

# Manually test that our executable works.
> launchctl start org.<user>.backup
```

If your launch agent is not producing the intended results, you can always inspect the
logs with `cat /tmp/org.<user>.notion-backup.stderr`.

## Sources

I couldn't have wrote this program without several fantastic references:

- [Automated Notion backups](https://artur-en.medium.com/automated-notion-backups-f6af4edc298d) by Artur Burtsev. My OCaml script is specifically based on [his Python implementation](https://gitlab.com/aburtsev/notion-backup-script/-/raw/master/.gitlab-ci.yml).
- [Schedule jobs in MacOSX (a guide to launchd)](https://killtheyak.com/schedule-jobs-launchd/).
- [Automated your Notion backups](https://blog.shayan.sx/automate-your-notion-backups.html).
