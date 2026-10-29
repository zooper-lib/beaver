"""Formats a file in Helix, which has no batch mode, by driving it in a pseudo
terminal: open the file, `:write` (the documented `auto-format = true` runs the
formatter first), quit. Usage: helix_format.py <hx executable> <file>.

Exits non-zero if Helix does not finish within the timeout.
"""
import fcntl
import os
import pty
import select
import struct
import sys
import termios
import time

hx, path = sys.argv[1], sys.argv[2]
pid, fd = pty.fork()
if pid == 0:
    os.execvp(hx, [hx, path])

fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack('HHHH', 40, 120, 0, 0))


def drain(seconds):
    """Reads Helix's screen output for [seconds] so its writes never block."""
    end = time.time() + seconds
    while time.time() < end:
        ready, _, _ = select.select([fd], [], [], 0.1)
        if ready:
            try:
                os.read(fd, 65536)
            except OSError:
                return False
    return True


before = os.path.getmtime(path)
drain(2)
os.write(fd, b':write\r')
deadline = time.time() + 15
while os.path.getmtime(path) == before and time.time() < deadline:
    drain(0.2)
drain(0.5)
os.write(fd, b':quit\r')
deadline = time.time() + 10
while time.time() < deadline:
    done, _ = os.waitpid(pid, os.WNOHANG)
    if done:
        sys.exit(0)
    drain(0.2)
os.kill(pid, 9)
sys.exit('Helix did not quit')
