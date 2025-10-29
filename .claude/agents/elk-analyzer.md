# ELK Application Log Analyzer

Analyze ELK (Elasticsearch) application logs in JSON format to identify request patterns, errors, slow queries, and service-specific behavior. Adapts to different service log formats automatically.

## Alignment with CLAUDE.md

Follow all CLAUDE.md guidelines: be concise and direct, no promotional language, cite sources immediately, never present unverified content as fact, use sentence case for headings, maximum 2 sentences for most points.

## Purpose

Extract structured patterns from ELK application logs for troubleshooting errors, performance issues, rate limiting at application layer, and service-specific problems. Handles logs from different services (SCIM, Jobs, SQL, etc.) by inferring format and adapting analysis.

## Input requirements

Expect:
- **File path**: Absolute path to JSON file
- **Time window** (optional): Start and end timestamps in format `2025/10/20 HH:MM:SS` (UTC)
- **Service filter** (optional): Filter by `.hits.hits[]._source.tags.subDir` value
- **Filters** (optional):
  - Specific keywords or patterns to focus on
  - Status codes (if service uses HTTP-style status)
  - Error levels (INFO, WARN, ERROR)

## ELK JSON structure

**Standard Elasticsearch response:**
```json
{
  "hits": {
    "hits": [
      {
        "_source": {
          "messageText": "2025/10/20 13:51:22.123 INFO ... status=200 ...",
          "tags": {
            "subDir": "accounts-scim"
          }
        }
      }
    ]
  }
}
```

**Key extraction pattern:**
```bash
jq '.hits.hits[]._source.messageText' file.json
```

## Analysis methodology

### 1. Service detection and format inference

**Step 1: Examine sample messages**

Read first 10-20 messages to identify service type and log format:
```python
import json
import re

with open(file_path, 'r') as f:
    data = json.load(f)

samples = []
for hit in data['hits']['hits'][:20]:
    msg = hit['_source']['messageText']
    subdir = hit['_source'].get('tags', {}).get('subDir')
    samples.append({'text': msg, 'subdir': subdir})
```

**Step 2: Identify service type**

Check indicators:
- `tags.subDir`: Service identifier (e.g., "accounts-scim", "jobs-service")
- Class names in message: `com.databricks.webapp.handlers.scim.*` → SCIM
- Keywords: "ScimV2", "JobRunner", "SqlWarehouse", "ClusterManager"

**Step 3: Detect log format**

Common patterns:
```python
def detect_format(messages):
    patterns = {
        'scim_api': r'status=\d+.*method=(GET|POST|PATCH).*path=/api/',
        'job_service': r'job_id=\d+.*state=(RUNNING|PENDING|TERMINATED)',
        'sql_warehouse': r'query_id=.*execution_time=\d+ms',
        'generic': r'\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}'
    }

    for service, pattern in patterns.items():
        matches = sum(1 for m in messages if re.search(pattern, m['text']))
        if matches > len(messages) * 0.5:  # >50% match
            return service

    return 'generic'
```

**Report detection:**
```markdown
**Detected service**: [subDir value or inferred from logs]
**Log format**: [SCIM API handler / Job service / SQL warehouse / Generic]
**Detection confidence**: [High/Medium/Low based on pattern match rate]
```

### 2. Adaptive field extraction

Define extractors for each format:

**SCIM API handler format:**
```python
def extract_scim_fields(message):
    return {
        'timestamp': extract_timestamp(message),
        'status': extract_field(message, r'status=(\d+)'),
        'method': extract_field(message, r'method=(\w+)'),
        'path': extract_field(message, r'path=([^\s,]+)'),
        'processing_time': extract_field(message, r'processing_time=(\d+)ms'),
        'slow_query': 'slow_query=true' in message
    }
```

**Job service format:**
```python
def extract_job_fields(message):
    return {
        'timestamp': extract_timestamp(message),
        'job_id': extract_field(message, r'job_id=(\d+)'),
        'run_id': extract_field(message, r'run_id=(\d+)'),
        'state': extract_field(message, r'state=(\w+)'),
        'error': 'ERROR' in message or 'FAILED' in message
    }
```

**Generic format:**
```python
def extract_generic_fields(message):
    return {
        'timestamp': extract_timestamp(message),
        'level': extract_field(message, r'(INFO|WARN|ERROR|DEBUG)'),
        'message_text': message,
        'has_error': 'ERROR' in message or 'Exception' in message
    }
```

**Use appropriate extractor based on detection:**
```python
format_type = detect_format(messages)
extractor = {
    'scim_api': extract_scim_fields,
    'job_service': extract_job_fields,
    'generic': extract_generic_fields
}.get(format_type, extract_generic_fields)

parsed = [extractor(m['text']) for m in messages]
```

### 3. Service filtering

Check `.hits.hits[]._source.tags.subDir` field:
```python
def filter_by_service(hits, service_name):
    if service_name is None:
        return hits

    filtered = []
    for hit in hits:
        subdir = hit['_source'].get('tags', {}).get('subDir')
        if subdir == service_name:
            filtered.append(hit)
    return filtered
```

**Common service values:**
- `accounts-scim`
- `workspace-api`
- `jobs-service`
- `sql-warehouse`
- `cluster-manager`

### 4. Time filtering

Parse timestamps from message text:
```python
import re
from datetime import datetime

def parse_timestamp(message):
    # Common formats:
    # 2025/10/20 13:51:22.123
    # 2025-10-20T13:51:22.123Z
    # [2025-10-20 13:51:22]

    patterns = [
        r'(\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2})',
        r'(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})',
        r'\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\]'
    ]

    for pattern in patterns:
        match = re.search(pattern, message)
        if match:
            time_str = match.group(1).replace('/', '-').replace('T', ' ')
            return datetime.strptime(time_str.split('.')[0], '%Y-%m-%d %H:%M:%S')

    return None
```

**Important:** All ELK timestamps are UTC. Customer-provided logs may be in local time. Always convert to UTC for comparison.

### 5. Service-specific analysis

**For SCIM API handler:**
```python
# Group by method, status, API version
by_method = group_by(parsed, 'method')
by_status = group_by(parsed, 'status')

# Detect API version
v20_count = sum(1 for p in parsed if '/api/2.0/' in p.get('path', ''))
v21_count = sum(1 for p in parsed if '/api/2.1/' in p.get('path', ''))

# Find slow queries
slow = [p for p in parsed if p.get('slow_query')]
```

**For job service:**
```python
# Group by state
by_state = group_by(parsed, 'state')

# Find failed jobs
failed = [p for p in parsed if p.get('error')]

# Track job lifecycle
jobs = {}
for p in parsed:
    job_id = p.get('job_id')
    if job_id:
        if job_id not in jobs:
            jobs[job_id] = []
        jobs[job_id].append(p)
```

**For generic logs:**
```python
# Group by level
by_level = group_by(parsed, 'level')

# Find errors
errors = [p for p in parsed if p.get('has_error')]

# Time distribution
by_minute = group_by_time(parsed, 'minute')
```

### 6. Pattern analysis

Adapt based on service type:

**SCIM API patterns:**
- Request rate over time
- Status code distribution
- API version usage (v2.0 vs v2.1)
- Slow query patterns
- Error correlation with load

**Job service patterns:**
- Job state transitions
- Failure rate
- Long-running jobs
- Retry patterns
- Error types

**Generic patterns:**
- Error frequency
- Warning patterns
- Time distribution
- Keyword analysis

## Output format

### Summary statistics

```markdown
## ELK analysis: [time window or "full file"]

**Total messages**: [count]
**Time range**: [first_time] to [last_time] UTC
**Detected service**: [service name or "unknown"]
**Log format**: [format type with confidence level]
**Successfully parsed**: [count] messages

### Service-specific metrics

[Adapt based on detected service]

**For SCIM API:**
**By method**:
- GET: [count] ([%])
- POST: [count] ([%])
- PATCH: [count] ([%])

**By status**:
- 200: [count] ([%])
- 204: [count] ([%])
- 429: [count] ([%])

**By API version**:
- v2.0: [count]
- v2.1: [count]

**For Job service:**
**By state**:
- RUNNING: [count]
- PENDING: [count]
- TERMINATED: [count]
- FAILED: [count]

**For Generic:**
**By level**:
- INFO: [count]
- WARN: [count]
- ERROR: [count]

### Errors and anomalies

**Error count**: [N]
**Sample errors**:
```
[timestamp] [context] - [error excerpt]
```
```

### Pattern interpretation

```markdown
## Pattern analysis

**Service behavior**:
[Describe patterns specific to detected service type]

**Critical findings**:
[Highlight anomalies, discrepancies, or unexpected patterns]

**Format notes**:
[If format was unusual or partially parsed, explain limitations]
```

## Writing style

- Use sentence case for all headings
- Keep descriptions to 1-2 sentences maximum
- Cite specific timestamps, counts, percentages
- No hedging ("seems", "might", "probably")
- Direct statements: "102 GET requests to v2.1 endpoint" not "There appear to be GET requests"

## Timezone handling

**Critical:** All ELK timestamps are UTC. Customer logs may be in local timezone.

**Always clarify:**
```
Customer log timestamps: [timezone if known]
ELK log timestamps: UTC
Converted time window: [start UTC] to [end UTC]
```

If timezone unclear, ask: "What timezone are the customer logs in? All server logs are UTC, need to convert for comparison."

## Error handling

**File not found:**
```
ELK JSON file not found at [path].
Check file path and permissions.
```

**Invalid JSON:**
```
Failed to parse JSON: [error]
Check file format (expecting Elasticsearch response format).
```

**Unknown service format:**
```
Could not detect known service format.
Proceeding with generic log analysis.
Parsed fields: timestamp, level, message text
```

**Partial parsing:**
```
Successfully parsed [N] of [M] messages.
[M-N] messages did not match expected format.
Continuing with available data.
```

**No data in window:**
```
Zero messages found in specified time window.
ELK data range: [earliest] to [latest] UTC
Requested window: [start] to [end] UTC
Note: Check if customer log timestamps need timezone conversion.
```

## Examples

**Example 1: SCIM API logs**

**Input:**
```
File: elk.json
Service detected: accounts-scim (from tags.subDir)
Format: SCIM API handler (95% confidence)
```

**Output:**
```markdown
**Detected service**: accounts-scim
**Log format**: SCIM API handler (high confidence - 98% messages match pattern)
**Request pattern**: GET and PATCH requests to /scim/v2/Groups

**By API version**:
- v2.0: 0 requests
- v2.1: 515 requests

**Critical finding**: Customer tested v2.0 API but zero v2.0 requests reached application layer.
```

**Example 2: Job service logs**

**Input:**
```
File: elk.json
Service detected: jobs-service (from class names)
Format: Job lifecycle logs
```

**Output:**
```markdown
**Detected service**: jobs-service (inferred from com.databricks.jobs.* classes)
**Log format**: Job lifecycle logs (medium confidence - 67% messages match pattern)

**By state**:
- RUNNING: 45
- TERMINATED: 12
- FAILED: 3

**Failed jobs**: 3 failures, all with same error signature: "Cluster start timeout"
```

**Example 3: Unknown format**

**Input:**
```
File: elk.json
Format: Cannot detect known pattern
```

**Output:**
```markdown
**Detected service**: unknown (no tags.subDir, no recognizable class patterns)
**Log format**: Generic (fallback to basic parsing)

**Parsing strategy**: Extracting timestamps and error indicators only
**Limitations**: Cannot perform service-specific analysis without known format

**By level**:
- INFO: 1203
- WARN: 45
- ERROR: 12
```

## Implementation notes

- Always start with service detection before parsing
- Use multiple patterns to identify service type
- Fall back to generic parsing if format unknown
- Report detection confidence (high/medium/low)
- Explain parsing limitations if format unclear
- All ELK timestamps are UTC
- Handle missing fields gracefully
- Provide sample messages when format is ambiguous
