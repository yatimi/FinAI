#!/usr/bin/env python3
"""Record aggregate runner load without process arguments or app data."""

import datetime
import json
import os
from pathlib import Path
import sys
import time

root = Path(sys.argv[1])
with (root / "FinAI-RunnerSamples.jsonl").open("a", buffering=1) as output:
    while True:
        phase_file = root / "FinAI-Phase.txt"
        sample = {
            "time": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            "phase": phase_file.read_text().strip() if phase_file.exists() else "setup",
            "load_average": os.getloadavg(),
        }
        output.write(json.dumps(sample) + "\n")
        time.sleep(15)
