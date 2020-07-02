This project is broken and has been abandoned.
==============================================

If you are looking for an alternative
(_i.e.,_ a daemon / background service to monitor your inbox
and trigger an IMAP sync utility whenever new mail arrives),
try [gnubiff](http://gnubiff.sourceforge.net/).

Gnubiff’s _intended purpose_ is to provide a GUI widget
that lives in the corner of your screen
and shows a preview of new emails as they come in.
However, you can run it in **headless mode**
and configure it to run whatever command you want
when a new incoming message has been detected
(_e.g.,_ `mbsync -a`).

You’ll have to launch it in GUI mode at least once
to add your IMAP credentials,
and then manually edit the config file
to tell it how to fetch your mail:

```xml
<!-- ~/.gnubiffrc -->

<configuration-file>
  <general>
    <parameter name="newmail_command" value="pgrep mbsync >/dev/null || mbsync --verbose --all > /home/rlue/log/mbsync.log" />
  </general>
</configuration-file>
```

> **Note:**
> If your mail fetching utility invokes a password manager like [pass][]
> to avoid storing passwords in plain text,
> you might have to set some environment variables
> at the start of the `newmail_command` above, like:
>
> ```sh
> value="export GNUPGHOME='/home/rlue/.config/gnupg'; export PASSWORD_STORE_DIR='/home/rlue/.config/pass'; pgrep ..."
> ```

Then, you can set it up and launch it as a systemd service:

```service
# ~/.local/share/systemd/user/gnubiff.service

[Unit]
Description=Gnubiff Headless Email Fetcher
After=network.target

[Service]
ExecStart=/usr/bin/gnubiff --noconfigure --nogui
Restart=on-failure

[Install]
WantedBy=default.target
```

```sh
$ systemctl --user enable gnubiff
$ systemctl --user start gnubiff
```

📬 Little Red Flag
==================

### Sync IMAP mail to your machine. Automatically, instantly, all the time.

Requires [isync][isync].

**isync** (`mbsync`) is a command-line tool for synchronizing IMAP and local Maildir mailboxes. It’s faster and stabler than the next most popular alternative (OfflineIMAP), but still must be invoked manually. **Little Red Flag** keeps an eye on your mailboxes and runs the appropriate `mbsync` command anytime changes occur, **whether locally or remotely**. It also detects the presence of `mu` / `notmuch` mail indexers, and re-indexes after each sync.

Little Red Flag is smart: it only syncs once it’s confirmed that the specified IMAP server is reachable. Remote changes are monitored with IMAP IDLE, and dropped connections are renewed within 60 seconds. 

(In fact, it would be ideal if isync implemented this functionality itself, but according to the project maintainer, such plans are [vague and indefinitely postponed][postponed]. If I knew the first thing about C, I’d have taken a stab at improving isync myself; this utility is the next best thing I knew how to make.)

Installation
------------

```bash
$ gem install little_red_flag
```

Usage
-----

Call `littleredflag` with same arguments you would use for mbsync:

```bash
$ littleredflag -a
```

listens for changes on all remote IMAP folders. Specify one or more channels/groups (as defined in your `.mbsyncrc`) to watch all IMAP folders contained in them.

You may find it convenient to define a group for all mailboxes you wish to monitor:

```
# ~/.mbsyncrc
Group inboxes
Channel gmail-inbox
Channel gmail-drafts
Channel gmail-sent
Channel gmail-starred
```

Then:

```bash
$ littleredflag inboxes
```

Locally, Little Red Flag watches paths specified in `MaildirStore` sections of your `.mbsyncrc`, and thus will detect local changes in _any_ mail folder.

**Synchronizations are performed only on mail folders where changes are detected.** If you’re only monitoring your INBOX, receiving new mail to it will not cause any other folders to sync. (This behavior can be reversed with the `-g` command line option.)

### In `.bash_profile`

For best results, run Little Red Flag on login.

One way to do that is to add it to your `.bash_profile`. The following script will launch Little Red Flag idempotently (that is, it will only launch if there is no other instance of Little Red Flag running that was originated by this same script):

```bash
mkdir -p "$HOME/tmp"
PIDFILE="$HOME/tmp/littleredflag.pid"

if [ -e "${PIDFILE}" ] && (ps -u $(whoami) -opid= |
                           grep "$(cat ${PIDFILE})" &> /dev/null); then
  :
else
  littleredflag > "$HOME/tmp/littleredflag.log" 2>&1 &

  echo $! > "${PIDFILE}"
  chmod 644 "${PIDFILE}"
fi
```

Config
------

Little Red Flag does not accept a configuration dotfile. It extracts the relevant settings from the `~/.mbsyncrc` file, and detects mu and notmuch on the basis of their respective dotfiles, as well.

Currently, Little Red Flag only looks for these dotfiles in their default location. Future versions may support a command line option to specify config file locations.

License
-------

The MIT License (MIT)

Copyright © 2017 Ryan Lue

[pass]: https://www.passwordstore.org/
[isync]: http://isync.sourceforge.net/
[listen]: https://github.com/guard/listen
[postponed]: https://sourceforge.net/p/isync/feature-requests/8/#173f
