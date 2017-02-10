# Welcome to UIT Moodle Reminder
**UIT Moodle Reminder** is a web-application that can notify you the deadlines on Moodle system for **UITers**. This reminder helps you organize your time better. Let's spend your time for going on a date :&#41;.

# How to use
1. Visit  [this link](http://umr.foxfizz.com/)
2. Enter your Moodle account
3. Enjoy!

#### Messenger CLI
`Usage: ff <command> [<args>] —options`

Command                  | Description
------------------------ | ------------------------
`ff help`                | List all common commands
`ff activate <token>`    | Activate the account for the first time <br/>_Eg:_ `ff activate ThIs#iS$A^VeRy&lOnG*ToKeN`
`ff whoami`              | Get Moodle account information that is associated to current Messenger account
`ff next`                | Show next deadline
`ff list`                | List all deadlines
`ff show <index>`        | Show complete infomation deadline `index` (`index` is depend on `ff list`) <br/>_Eg:_ `ff show 1`
`ff unsubscribe <index>` | Stop getting notifications of deadline `index` in the future <br/>_Eg:_ `ff unsubscribe 1`
`ff destroy`             | Destroy account **with** confirmation
`ff destroy --confirm`   | Destroy account **without** confirmation

# Contributing
I encourage you to contribute to **UIT Moodle Reminder**! Please follow the instruction below:

1. Fork it (https://github.com/fongfan999/uit_moodle_reminder/fork)
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request
