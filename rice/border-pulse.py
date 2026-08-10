#!/usr/bin/env python3
"""Briefly widen a window's border right after it gains focus, then
revert — a quick pulse so a focus change is easy to spot at a glance."""

import threading
import time

import i3ipc

PULSE_WIDTH = 4
NORMAL_WIDTH = 2
PULSE_SECONDS = 0.12


def revert(con_id):
    time.sleep(PULSE_SECONDS)
    try:
        i3ipc.Connection().command(f'[con_id="{con_id}"] border pixel {NORMAL_WIDTH}')
    except Exception:
        pass


def on_focus(i3, event):
    con = event.container
    if con.window is None:
        return
    i3.command(f'[con_id="{con.id}"] border pixel {PULSE_WIDTH}')
    threading.Thread(target=revert, args=(con.id,), daemon=True).start()


i3 = i3ipc.Connection()
i3.on(i3ipc.Event.WINDOW_FOCUS, on_focus)
i3.main()
