import fcntl
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path


def run(*args):
    result = subprocess.run(
        args, capture_output=True, text=True, timeout=15, check=False
    )
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or "Display command failed")
    return result.stdout


def brightness_bus(output):
    runtime = Path(
        os.environ.get("XDG_RUNTIME_DIR", str(Path.home() / ".cache" / "quickshell"))
    )
    runtime.mkdir(parents=True, exist_ok=True)
    cache = runtime / f"quickshell-ddc-{output}.json"
    try:
        bus = json.loads(cache.read_text())["bus"]
        if isinstance(bus, int) and bus >= 0:
            return bus, cache
    except (OSError, ValueError, KeyError):
        pass
    bus = None
    for line in run("ddcutil", "detect", "--brief").splitlines():
        match = re.search(r"I2C bus:.*?/dev/i2c-(\d+)", line)
        if match:
            bus = int(match[1])
        match = re.search(r"DRM connector:\s+(?:card\d+-)?(\S+)", line)
        if match:
            if match[1] == output and bus is not None:
                cache.write_text(json.dumps({"bus": bus}))
                return bus, cache
            bus = None
    raise RuntimeError("Brightness control is unavailable for this display")


def brightness(output, value=None):
    bus, cache = brightness_bus(output)
    try:
        response = run("ddcutil", "--bus", str(bus), "getvcp", "10", "--brief")
        match = re.search(r"VCP\s+10\s+C\s+(\d+)\s+(\d+)", response, re.IGNORECASE)
        if not match or int(match[2]) <= 0:
            raise RuntimeError("Brightness control is unavailable for this display")
        current, maximum = map(int, match.groups())
        if value is not None:
            percent = int(value)
            if not 1 <= percent <= 100:
                raise ValueError("Brightness must be between 1 and 100")
            raw = max(1, round(percent * maximum / 100))
            run("ddcutil", "--bus", str(bus), "setvcp", "10", str(raw))
            return percent
        return max(1, min(100, round(current * 100 / maximum)))
    except Exception:
        cache.unlink(missing_ok=True)
        raise


def set_scale(output, value):
    if value not in {"1", "1.25", "1.6", "2", "3", "4"}:
        raise ValueError("Unsupported scale preset")
    config = (
        Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))) / "mango"
    )
    config.mkdir(parents=True, exist_ok=True)
    path = config / "displays.conf"
    with (config / ".displays.lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        lines = path.read_text().splitlines() if path.exists() else []
        prefix = f"monitorrule=name:^{output}$,scale:"
        lines = [line for line in lines if not line.startswith(prefix)]
        lines.append(prefix + value)
        descriptor, temporary = tempfile.mkstemp(prefix=".displays-", dir=config)
        try:
            with os.fdopen(descriptor, "w") as file:
                file.write("\n".join(lines) + "\n")
            run("wlr-randr", "--output", output, "--scale", value)
            os.replace(temporary, path)
        finally:
            Path(temporary).unlink(missing_ok=True)


def main():
    if len(sys.argv) not in {3, 4}:
        raise ValueError("Expected a command, output, and optional value")
    command, output = sys.argv[1:3]
    if not re.fullmatch(r"[A-Za-z0-9_-]+", output):
        raise ValueError("Invalid display name")
    if command == "brightness-read" and len(sys.argv) == 3:
        try:
            print(json.dumps({"brightness": brightness(output)}))
        except (RuntimeError, OSError, subprocess.TimeoutExpired):
            print(json.dumps({"brightness": None}))
    elif command == "brightness" and len(sys.argv) == 4:
        brightness(output, sys.argv[3])
    elif command == "scale" and len(sys.argv) == 4:
        set_scale(output, sys.argv[3])
    else:
        raise ValueError("Unknown display command")


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, ValueError, OSError, subprocess.TimeoutExpired) as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
