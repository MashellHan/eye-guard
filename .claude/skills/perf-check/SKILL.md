---
name: perf-check
description: Sample EyeGuard runtime performance (RSS/CPU/threads/FDs) for 10 seconds and write CSV summary. Use to verify performance after a change or as a one-off health check.
user-invocable: true
allowed-tools: Bash
argument-hint: [output-dir]
---

采样 EyeGuard 运行时性能 10 秒，写入 CSV + 计算汇总。

!`OUT="${1:-.agent_workspace/perf-checks/$(date +%Y%m%d-%H%M%S)}"; mkdir -p "$OUT"; PID=$(pgrep -f "EyeGuard.app/Contents/MacOS/EyeGuard"); if [ -z "$PID" ]; then echo "EyeGuard not running. Launch first."; exit 1; fi; echo "Sampling PID=$PID for 10s..."; echo "ts,rss_kb,pcpu,threads,fds" > "$OUT/raw.csv"; for i in {1..10}; do printf "%s,%s,%s,%s,%s\n" "$(date +%s)" "$(ps -o rss= -p $PID 2>/dev/null | tr -d ' ')" "$(ps -o pcpu= -p $PID 2>/dev/null | tr -d ' ')" "$(ps -M -p $PID 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')" "$(lsof -p $PID 2>/dev/null | wc -l | tr -d ' ')" >> "$OUT/raw.csv"; sleep 1; done; echo; echo "=== Raw samples ==="; cat "$OUT/raw.csv"; echo; echo "=== Summary ==="; awk -F, 'NR>1 {rss+=$2; cpu+=$3; thr+=$4; fd+=$5; n++; if ($2>rss_max) rss_max=$2; if ($3>cpu_max) cpu_max=$3} END {printf "rss_avg_mb=%.1f rss_max_mb=%.1f cpu_avg=%.2f cpu_max=%.2f thr_avg=%.0f fd_avg=%.0f\n", rss/n/1024, rss_max/1024, cpu/n, cpu_max, thr/n, fd/n}' "$OUT/raw.csv" | tee "$OUT/summary.txt"; echo; echo "=== Thresholds (test-matrix.md) ==="; echo "RSS < 100 MB | CPU < 3% (idle)"`
