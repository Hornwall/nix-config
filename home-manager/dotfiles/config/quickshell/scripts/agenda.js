#!/usr/bin/env -S gjs -m

import Gio from "gi://Gio";
import GLib from "gi://GLib";
import system from "system";

const [sinceArg, untilArg] = ARGV;
const since = Number(sinceArg);
const until = Number(untilArg);

if (!Number.isFinite(since) || !Number.isFinite(until) || until <= since) {
    printerr("usage: agenda.js SINCE_UNIX UNTIL_UNIX");
    system.exit(2);
}

const interfaceXml = `
<node>
  <interface name="org.gnome.Shell.CalendarServer">
    <method name="SetTimeRange">
      <arg type="x" name="since" direction="in"/>
      <arg type="x" name="until" direction="in"/>
      <arg type="b" name="force_reload" direction="in"/>
    </method>
    <signal name="EventsAddedOrUpdated">
      <arg type="a(ssxxa{sv})" name="events"/>
    </signal>
    <signal name="EventsRemoved">
      <arg type="as" name="ids"/>
    </signal>
  </interface>
</node>`;

const CalendarProxy = Gio.DBusProxy.makeProxyWrapper(interfaceXml);
const loop = GLib.MainLoop.new(null, false);
const events = new Map();
let failed = false;

const proxy = new CalendarProxy(
    Gio.DBus.session,
    "org.gnome.Shell.CalendarServer",
    "/org/gnome/Shell/CalendarServer",
    (calendar, error) => {
        if (error) {
            printerr(error.message);
            failed = true;
            loop.quit();
            return;
        }

        calendar.connectSignal("EventsAddedOrUpdated", (_proxy, _sender, [appointments]) => {
            for (const [id, summary, start, end] of appointments) {
                events.set(id, {
                    id,
                    summary: summary || "Untitled event",
                    start: Number(start),
                    end: Number(end),
                });
            }
        });

        calendar.connectSignal("EventsRemoved", (_proxy, _sender, [ids]) => {
            for (const id of ids)
                events.delete(id);
        });

        calendar.SetTimeRangeRemote(since, until, true, (_result, callError) => {
            if (callError) {
                printerr(callError.message);
                failed = true;
                loop.quit();
            }
        });

        // EDS emits one or more batches as its calendar clients answer. Allow
        // enough time for remote-backed calendars while keeping the popup quick.
        GLib.timeout_add(GLib.PRIORITY_DEFAULT, 2500, () => {
            loop.quit();
            return GLib.SOURCE_REMOVE;
        });
    }
);

loop.run();

if (failed)
    system.exit(1);

const result = [...events.values()]
    .filter(event => event.start < until && event.end > since)
    .sort((left, right) => left.start - right.start || left.end - right.end);

print(JSON.stringify(result));
