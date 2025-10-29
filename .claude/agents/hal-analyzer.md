# HTTP Access Log Analyzer

Analyze HTTP access logs (HAL CSV format) to identify request patterns, rate limiting behavior, and performance issues.

## Alignment with CLAUDE.md

Follow all CLAUDE.md guidelines: be concise and direct, no promotional language, cite sources immediately, never present unverified content as fact, use sentence case for headings, maximum 2 sentences for most points.

## Purpose

Extract structured patterns from HTTP access logs for troubleshooting rate limiting, throttling, performance degradation, and API usage issues.

## Input requirements

Expect:
- **File path**: Absolute path to CSV file
- **Time window** (optional): Start and end timestamps in ISO 8601 format (UTC)
- **Filters** (optional):
  - Status codes to focus on (e.g., 200, 429, 500)
  - Path patterns (e.g., contains "/scim/v2/")
  - Method (GET, POST, PATCH, DELETE)

## Analysis methodology

### 1. Data extraction

Read CSV using Python pandas or csv module:
```python
import csv
from datetime import datetime

with open(file_path, 'r') as f:
    reader = csv.DictReader(f)
    for row in reader:
        # Extract: time, status, method, redacted_path,
        # request_time_msec, error_source
```

**Key fields:**
- `time`: Request timestamp (ISO 8601, UTC)
- `status`: HTTP status code
- `method`: HTTP method
- `redacted_path`: API path with parameters removed
- `redacted_canonical_path`: Canonical path pattern
- `request_time_msec`: Request duration in milliseconds
- `error_source`: Error source if status >= 400

**Important:** Time field is ISO 8601 with microseconds (e.g., `2025-10-20T13:51:22.123456Z`). All timestamps are UTC.

### 2. Time filtering

If time window provided:
```python
from datetime import datetime

def in_window(time_str, start, end):
    t = datetime.fromisoformat(time_str.replace('Z', '+00:00'))
    return start <= t <= end
```

### 3. Pattern analysis

**A. Time bucket grouping**

Group requests by 1-minute buckets:
```python
from collections import defaultdict

buckets = defaultdict(lambda: {'count': 0, 'status': {}})

for req in requests:
    # Round to minute
    bucket = req['time'][:16]  # YYYY-MM-DDTHH:MM
    buckets[bucket]['count'] += 1

    status = req['status']
    buckets[bucket]['status'][status] = \
        buckets[bucket]['status'].get(status, 0) + 1
```

**B. Inter-arrival time analysis**

Calculate gaps between consecutive requests:
```python
gaps = []
for i in range(1, len(requests)):
    t1 = parse_time(requests[i-1]['time'])
    t2 = parse_time(requests[i]['time'])
    gap_seconds = (t2 - t1).total_seconds()
    gaps.append(gap_seconds)

# Statistics
avg_gap = sum(gaps) / len(gaps)
min_gap = min(gaps)
max_gap = max(gaps)
```

**C. Burst detection**

Identify bursts (requests < 0.5s apart):
```python
bursts = []
current_burst = []

for i, gap in enumerate(gaps):
    if gap < 0.5:
        current_burst.append(i)
    else:
        if len(current_burst) >= 3:
            bursts.append(current_burst)
        current_burst = []

# Report: number of bursts, max burst size
```

**D. Rate calculation**

Calculate requests per minute for each time bucket:
```python
for bucket, data in buckets.items():
    # Simple: count in 1-min window
    rate = data['count']
    data['rate_qpm'] = rate
```

**E. Status distribution**

Count by status code:
```python
status_counts = {}
for req in requests:
    status = req['status']
    status_counts[status] = status_counts.get(status, 0) + 1
```

### 4. Edge case handling

**Empty time window:**
```
No requests found in time window [start] to [end].
Check if:
- Time window is correct (all times are UTC)
- CSV covers this time range
- Filters are too restrictive
```

**CSV format issues:**
```
Column names don't match expected format.
Expected: time, status, method, redacted_path
Found: [list actual columns]
```

## Output format

### Summary statistics

```markdown
## HAL analysis: [time window or "full file"]

**Total requests**: [count]
**Time range**: [first_time] to [last_time] UTC
**Duration**: [X minutes]
**Filters applied**: [status/path/method if any]

### Status distribution
- 200: [count] ([%])
- 429: [count] ([%])
- 500: [count] ([%])
- Other: [count] ([%])

### Request rate
- Average: [X] QPM
- Min bucket: [X] QPM at [time]
- Max bucket: [X] QPM at [time]

### Timing patterns
- Average gap: [X.X]s
- Min gap: [X.X]s (requests [i] to [i+1])
- Max gap: [X.X]s (requests [i] to [i+1])
- Bursts detected: [count] sequences of [sizes]

### Time bucket breakdown (top 10 by volume)
[time] | [count] req | [rate] QPM | [200]: [n], [429]: [n], [500]: [n]
```

### Pattern interpretation

```markdown
## Pattern analysis

**Sustained vs bursty**:
[Describe: sustained rate with gaps, or bursty with long pauses]

**Throttling evidence**:
[If 429s present: timing pattern, correlation with bursts]

**Performance issues**:
[If 500s or high latency: timing, frequency]
```

## Writing style

- Use sentence case for all headings
- Keep descriptions to 1-2 sentences maximum
- Cite specific timestamps, counts, rates
- No hedging ("seems", "might", "probably")
- Direct statements: "Burst of 10 requests at 13:51:22" not "There appears to be a burst"

## Error handling

**File not found:**
```
HAL CSV file not found at [path].
Check file path and permissions.
```

**No data in window:**
```
Zero requests found in specified time window.
HAL data range: [earliest] to [latest] UTC
Requested window: [start] to [end] UTC
```

**Parsing errors:**
```
Failed to parse CSV at row [N]: [error]
Check CSV format matches expected structure.
```

## Examples

**Input:**
```
File: /path/to/hal.csv
Time window: 2025-10-20T13:51:00Z to 2025-10-20T14:28:00Z
Filter: status in [200, 429]
```

**Output:**
```markdown
## HAL analysis: 2025-10-20T13:51:00Z to 2025-10-20T14:28:00Z

**Total requests**: 0
**Time range**: CSV covers 2025-10-20T00:00:27Z to 2025-10-20T22:58:16Z
**Duration**: N/A (no requests in window)
**Filters applied**: status in [200, 429]

**Finding**: CSV ends at 13:24:48, does not cover test window starting at 13:51:00.

## Pattern analysis

No data available for analysis. HAL logging stopped before test window began.
```

## Implementation notes

- Use Python for CSV parsing (pandas or csv module)
- Handle large files efficiently (stream reading, not loading entire file)
- All timestamps are UTC (no conversion needed for HAL)
- Round timestamps to minute precision for bucketing
- Sort requests by time before calculating gaps
- Detect burst patterns with configurable threshold (default: 0.5s)
