#!/usr/bin/env python3
import os, time, subprocess, struct, fcntl
from pathlib import Path

# --- I2C low-level (no external libs) ---
I2C_DEV = "/dev/i2c-1"
I2C_SLAVE = 0x0703  # from linux/i2c-dev.h

class I2CBus:
    def __init__(self, dev=I2C_DEV):
        self.fd = None
        self.dev = dev
        self._addr = None
        self._open()

    def _open(self):
        try:
            self.fd = os.open(self.dev, os.O_RDWR)
        except Exception:
            self.fd = None  # fall back to i2cset
    def set_addr(self, addr):
        if self.fd is None:
            self._addr = addr
            return
        if addr != self._addr:
            fcntl.ioctl(self.fd, I2C_SLAVE, addr)
            self._addr = addr
    def write_byte(self, addr, value):
        if self.fd is not None:
            self.set_addr(addr)
            os.write(self.fd, struct.pack("B", value & 0xFF))
    def close(self):
        if self.fd is not None:
            os.close(self.fd)
            self.fd = None

BUS = I2CBus()

CTRL_ADDR = 0x24
DIGIT_ADDRS = [0x34, 0x35, 0x36, 0x37]

# 7-seg LUT
DATA = [
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
    0x00,0x82,0x21,0x00,0x00,0x00,0x00,0x02,0x39,0x0F,0x00,0x00,0x40,0x00,0x00,0x00,
    0x3F,0x06,0x5B,0x4F,0x66,0x6D,0x7D,0x07,0x7F,0x6F,0x00,0x00,0x00,0x48,0x00,0x53,
    0x00,0x77,0x7C,0x39,0x5E,0x79,0x71,0x6F,0x76,0x06,0x1E,0x00,0x38,0x00,0x54,0x3F,
    0x73,0x67,0x50,0x6D,0x78,0x3E,0x00,0x00,0x00,0x6E,0x00,0x39,0x00,0x0F,0x00,0x08,
    0x63,0x5F,0x7C,0x58,0x5E,0x7B,0x71,0x6F,0x74,0x02,0x1E,0x00,0x06,0x00,0x54,0x5C,
    0x73,0x67,0x50,0x6D,0x78,0x1C,0x00,0x00,0x00,0x6E,0x00,0x39,0x30,0x0F,0x00,0x00
]
if len(DATA) < 128:
    DATA.extend([0x00] * (128 - len(DATA)))

def seg(ch: str) -> int:
    return DATA[ord(ch)] if ch and 0 <= ord(ch) < len(DATA) else 0x00

# --- Efficient display pipeline ---
def disp_line(s: str, step_sleep=0.35):
    """Scroll one line across 4 digits with minimal writes."""
    # Precompute segment codes (pad 3 spaces to fully scroll off)
    buf = [seg(c) for c in (s + "   ")]
    if not buf:
        # clear first digit (compat with original)
        BUS.write_byte(DIGIT_ADDRS[0], 0x00)
        return

    # enable/update once per line
    BUS.write_byte(CTRL_ADDR, 0x01)

    # initial window
    w0 = [0x00, 0x00, 0x00, 0x00]
    n = len(buf)
    for i in range(n):
        w = buf[i:i+4] + [0x00] * max(0, 4 - (n - i))
        # Only write digits that changed vs previous window
        for addr, prev, cur in zip(DIGIT_ADDRS, w0, w):
            if prev != cur:
                BUS.write_byte(addr, cur)
        w0 = w
        time.sleep(step_sleep)

def ensure_template(path: Path):
    if not path.exists():
        path.write_text("   IP=${IP} RES=${CPU} ${RAM}\n", encoding="utf-8")

# --- Low-cost system stats ---
_prev_total = None
_prev_idle  = None
def _read_cpu():
    with open("/proc/stat","r",encoding="utf-8") as f:
        parts = f.readline().split()
    vals = list(map(int, parts[1:8])) + [0]  # up to softirq + safe pad
    user,nice,system,idle,iowait,irq,softirq = vals[:7]
    total = user+nice+system+idle+iowait+irq+softirq
    idle_only = idle  # match top: don't add iowait
    return total, idle_only

def get_cpu_percent():
    global _prev_total, _prev_idle
    try:
        t,i = _read_cpu()
        if _prev_total is None:
            _prev_total, _prev_idle = t, i
            return 0
        dt, di = t-_prev_total, i-_prev_idle
        _prev_total, _prev_idle = t, i
        if dt <= 0: return 0
        usage = (dt - di) * 100.0 / dt
        if usage < 0: usage = 0.0
        if usage > 100: usage = 100.0
        return int(round(usage))
    except Exception:
        return 0

def get_ram_percent():
    try:
        mt=ma=None
        with open("/proc/meminfo","r",encoding="utf-8") as f:
            for line in f:
                if line.startswith("MemTotal:"):     mt = int(line.split()[1])
                elif line.startswith("MemAvailable:"): ma = int(line.split()[1])
                if mt and ma is not None: break
        if mt and ma is not None:
            return int(round((mt-ma)*100.0/mt))
    except: pass
    return 0

def get_ip():
    try:
        out = subprocess.check_output(["hostname","-I"], text=True).strip()
        return (out.split() or ["0.0.0.0"])[0]
    except Exception:
        return "0.0.0.0"

def main():
    template_path = Path("/tmp/screen")
    ensure_template(template_path)

    # Prime CPU delta so first reading isn't 0
    _ = get_cpu_percent()
    time.sleep(0.25)

    while True:
        os.environ["IP"]  = get_ip()
        os.environ["RAM"] = str(get_ram_percent())
        os.environ["CPU"] = str(get_cpu_percent())

        expanded = os.path.expandvars(template_path.read_text(encoding="utf-8"))
        for line in expanded.splitlines():
            disp_line(line, step_sleep=0.15)  # tweak to 0.5 for even less CPU
            time.sleep(0.4)                   # small pause between lines

if __name__ == "__main__":
    try:
        main()
    finally:
        try: BUS.close()
        except: pass
