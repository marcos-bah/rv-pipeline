# Cadence Genus(TM) Synthesis Solution, Version 22.17-s071_1, built Sep 12 2024 12:37:05

# Date: Thu Jan 15 20:11:12 2026
# Host: localhost.localdomain (x86_64 w/Linux 4.18.0-513.5.1.el8_9.x86_64) (20cores*28cpus*1physical cpu*Intel(R) Core(TM) i7-14700 33792KB)
# OS:   Rocky Linux release 8.10 (Green Obsidian)

source run_synthesis.tcl
genus -f run_synthesis.tcl 2>&1 | head -200
exit
