#!/usr/bin/env python3
"""Record aggregate runner resource usage without process arguments or app data."""

import datetime
import json
import os
from pathlib import Path
import subprocess
import sys
import time

root = Path(sys.argv[1])
with (root / "FinAI-RunnerSamples.jsonl").open("a", buffering=1) as output:
    while True:
        phase_file = root / "FinAI-Phase.txt"
        cpu = subprocess.run(
            ["ps", "-A", "-o", "pcpu="], capture_output=True, text=True, timeout=10
        )
        memory = subprocess.run(
            ["vm_stat"], capture_output=True, text=True, timeout=10
        )
        sample = {
            "time": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            "phase": phase_file.read_text().strip() if phase_file.exists() else "setup",
            "load_average": os.getloadavg(),
            "total_process_cpu_percent": sum(float(value) for value in cpu.stdout.split()),
            "memory_pages": memory.stdout,
        }
        output.write(json.dumps(sample) + "\n")
        time.sleep(15)
