# notion-backup-ocaml

A small OCaml program to automate the backup of your entire Notion workspace. Inspired by `5hay/notionbackup` ([source](https://github.com/5hay/notionbackup)).

This project satisfies two goals: (1) automate the backup of my Notion workspace, where my digital presence largely lives and (2) play around with my favorite programming language, OCaml.

## Using `launchd` to schedule this backup once a day

Using `launchd`, a built-in MacOS utility with Cron-like functionality, I've set
up this script to run once a day. (I used [this article](https://killtheyak.com/schedule-jobs-launchd/) for inspiration as I was setting this script up.)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <!-- The label should be the same as the filename without the extension -->
    <string>org.dylan.notion-backup</string>
    <!-- Specify how to run your program here -->
    <key>ProgramArguments</key>
    <array>
        <string>dune</string>
        <string>exec</string>
        <string>notion-backup-ocaml</string>
    </array>
    <!-- Run once a day at 9:00AM-->
    <key>StartCalendarInterval</key>
    <dict>
	<key>Hour</key>
	<integer>9</integer>
        <key>Minute</key>
	<integer>0</integer>
    </dict>
</dict>
</plist>
```
