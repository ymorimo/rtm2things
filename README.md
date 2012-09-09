A script to transfer tasks from [Remember the Milk](http://www.rememberthemilk.com/) (RTM) to [Things](http://culturedcode.com/things/).

Requires Ruby 1.9.3.

## Usage

The script loads RTM tasks in iCalendar format from STDIN. RTM provides the
'webcal://' links list by list. (Found on upper-right area of the list page.)
You can get the iCalendar file by copying the webcal:// link, and replacing
webcal:// with https://. The URL will look like
`"https://www.rememberthemilk.com/icalendar/USERNAME/9999999/?tok=zzzzz"`

In terminal, run the following steps:

    % cd path/to/rtm2things
    % gem install bundler
    % bundle install --path vendor/bundle
    % curl '<iCalendar URL>' | ./rtm2things.rb

Repeat the last line for your RTM lists to import.

## Skipping completed tasks

With this script the completed tasks on RTM will also be imported. If you don't
need to care about completed tasks on RTM, you can delete them after import from
"Logbook" list on Things.

If you know you can ignore whole completed tasks before import, editing the
script will run the migration faster. Open the script with an editor and
uncomment one line of code to skip them before run.

    # puts " => SKIP"; next

## Areas and Tags

Migration from a RTM list will create a new "Area of Responsibility" in Things,
named with the name of the list prefixed with "RTM\_" and the tasks will be
filed into the Area. For example if you grab the iCalendar link of "Inbox" list
on RTM, the Area "RTM\_Inbox" will be created in Things.

In addition the imported tasks will be also tagged with "RTM\_#{listname}" to
notice easily that the task is imported from RTM after import.

Creating areas and tagging while import have helped me reorganize tasks in
Things way, but you may feel it is unwanted. If so, please refile the tasks to
other Lists/Areas/Projects and/or remove the tags after import. You could also
simply remove them from the Area (which is done by selecting tasks and run
"Items" > "Remove from Project/Area" from the menu).
