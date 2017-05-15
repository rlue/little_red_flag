📬 Little Red Flag
==================

### Sync IMAP mail to your machine. Automatically, instantly, all the time.

Requires [isync][isync].

**isync** (`mbsync`) is a command-line tool for synchronizing IMAP and local Maildir mailboxes. It’s faster and stabler than the next most popular alternative (OfflineIMAP), but still must be invoked manually. **Little Red Flag** keeps an eye on your mailboxes and runs the appropriate `mbsync` command anytime changes occur, **whether locally or remotely**. It also detects the presence of `mu` / `notmuch` mail indexers, and re-indexes after each sync.

Local changes are monitored using [listen][listen]; remote changes are monitored with IMAP IDLE. (In fact, it would be ideal if isync implemented this functionality itself, but according to the project maintainer, such plans are [vague and indefinitely postponed][postponed]. If I knew the first thing about C, I’d have taken a stab at improving isync myself; this utility is the next best thing I knew how to make.)

Installation
------------

```bash
$ gem install little_red_flag
```

Usage
-----

For best results, run Little Red Flag on login. Call `littleredflag` with same arguments you would use for mbsync:

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

Config
------

Little Red Flag does not accept a configuration dotfile. It extracts the relevant settings from the `.mbsyncrc` file.

License
-------

The MIT License (MIT)

Copyright © 2017 Ryan Lue

[isync]: http://isync.sourceforge.net/
[listen]: https://github.com/guard/listen
[postponed]: https://sourceforge.net/p/isync/feature-requests/8/#173f
