#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'
require 'ri_cal'
require 'appscript'

things = Appscript.app.by_name('Things')
# someday = things.lists['Someday']

RiCal.parse(STDIN).each do |cal|
  cal_name = cal.x_wr_calname.first unless cal.x_wr_calname.empty?
  if cal_name
    destination_name = "RTM_#{cal_name}"
    begin
      destination = things.areas[destination_name].get
      # destination = things.projects[destination_name].get
    rescue
      destination = things.make new: :area, with_properties: { name: destination_name }
      # destination = things.make new: :project, with_properties: { name: destination_name }
    end
  end

  cal.todos.each do |rtm_todo|
    print %("#{rtm_todo.summary}")
    print " [due: #{rtm_todo.due}]" if rtm_todo.due
    if rtm_todo.completed
      print " [completed: #{rtm_todo.completed}]"
      # Uncomment this line to skip importing completed todo
      # puts " => SKIP"; next
    end
    puts

    rtm_attrs, rtm_notes = rtm_todo.description.split(/\n\n/, 2)

    tags = []
    notes = []
    rtm_attrs.strip.split("\n").each do |attr_line|
      case attr_line
      when /^Tags: (.*)/
        tags += $1.split(',').map { |t| t.strip.capitalize } unless $1 == 'none'
      when /^Time estimate: (.*)/
        notes << attr_line unless $1 == 'none'
      when /^Location: (.*)/
        notes << attr_line unless $1 == 'none'
      else
        notes << attr_line
      end
    end
    notes << rtm_notes if rtm_notes && !rtm_notes.empty?

    priority = case rtm_todo.priority
               when 1 then 'High'
               when 2 then 'Medium'
               when 3 then 'Low'
               end
    tags << priority if priority

    # Add a tag to filter to-dos after import
    tags << (cal_name ? "RTM_#{cal_name}" : 'RTM')

    todo = things.make(new: :to_do, at: destination,
                       with_properties: {
                         name: rtm_todo.summary
                       })

    todo.tag_names.set tags.join(", ") if tags.size > 0
    todo.notes.set notes.join("\n") if notes.size > 0

    if rtm_todo.due
      due_date = rtm_todo.due
      if due_date.is_a? DateTime
        # There is timezone mismatch issue if we consider time part of the value,
        # but this is ignorable since only date part is effective for due in Things.
        due_date = due_date.to_date
      end
      todo.due_date.set due_date
    end

    if rtm_todo.completed
      # .to_time is required to handle timezone correctly
      todo.completion_date.set rtm_todo.completed.to_time
    # else
      # things.move todo, :to => someday
    end

    # For DTSTART, we need to PLUS utc_offset:
    # If the creation time of the todo in RTM is "2012-09-06 23:00:00 +09:00"
    # - icalendar output by RTM  => DTSTART;TZID=Asia/Tokyo;VALUE=DATE-TIME:20120906T140000
    # - parsed value by RiCal    => #<DateTime: 2012-09-06T14:00:00+09:00> (wrong)
    creation_date = rtm_todo.dtstart.to_time
    todo.creation_date.set creation_date + creation_date.utc_offset

    todo.modification_date.set rtm_todo.last_modified.to_time
  end
end
