#!/usr/bin/env bash
set -euo pipefail

# Defaults
MARKET="se-sv"
ORIGIN="ARN"
DESTINATIONS="HND"
PASSENGERS="2"
DIRECT="false"
AVAILABILITY="true"
SELECTED_MONTH=""         # For API: YYYYMM
FILTER_MONTH=""           # For local filter: accepts YYYYMM/YYY-MM/YYYY-M
FILTER_MONTH_DASH=""      # YYYY-MM for jq filtering

LIST_MODE=""              # outbound|inbound|both
MIN_SEATS=""
JQ_FILTER=""
JQ_ARGS=()

SAVE_FILE=""
URL_OVERRIDE=""
VERBOSE=false
EXTRA_HEADERS=()

usage() {
  cat <<'USAGE'
Usage: fetch_sas_awards_v2.sh [options]

Fetch and parse SAS award-finder JSON.

Options:
  -m, --market STR           Market locale (default: se-sv)
  -o, --origin CODE          Origin airport (default: ARN)
  -D, --destinations CODE    Destination(s) comma-separated (default: HND)
  -p, --passengers N         Passenger count (default: 2)
      --direct BOOL          Only direct flights true/false (default: false)
      --availability BOOL    Only availability true/false (default: true)
  -M, --month YYYYMM         Server-side selectedMonth for API (YYYYMM)
  -F, --filter-month YM      Client-side filter month (YYYYMM or YYYY-MM)
  -L, --list MODE            One of: outbound, inbound, both (TSV output)
      --min-seats N          Filter list rows by total seats >= N
  -q, --jq FILTER            Custom jq filter (overrides list mode if set)
  -H, --header HDR           Extra header for curl (repeatable)
  -s, --save FILE            Save raw JSON to file
  -u, --url URL              Override full request URL (advanced)
  -v, --verbose              Print URL and active options
  -h, --help                 Show this help

Examples:
  # Both directions, September 2026
  ./scripts/fetch_sas_awards_v2.sh -o ARN -D HND -L both -F 202609

  # Outbound, min 2 seats, September 2026
  ./scripts/fetch_sas_awards_v2.sh -L outbound -F 2026-09 --min-seats 2

Notes:
  - API selectedMonth expects YYYYMM. Client filter accepts YYYYMM or YYYY-MM.
  - List modes require jq. Without jq, raw JSON is printed.
USAGE
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--market) MARKET="${2:-}"; shift 2;;
    -o|--origin) ORIGIN="${2:-}"; shift 2;;
    -D|--destinations) DESTINATIONS="${2:-}"; shift 2;;
    -p|--passengers) PASSENGERS="${2:-}"; shift 2;;
    --direct) DIRECT="${2:-}"; shift 2;;
    --availability) AVAILABILITY="${2:-}"; shift 2;;
    -M|--month) SELECTED_MONTH="${2:-}"; shift 2;;
    -F|--filter-month) FILTER_MONTH="${2:-}"; shift 2;;
    -L|--list) LIST_MODE="${2:-}"; shift 2;;
    --min-seats) MIN_SEATS="${2:-}"; shift 2;;
    -q|--jq) JQ_FILTER="${2:-}"; shift 2;;
    -H|--header) EXTRA_HEADERS+=(-H "${2:-}"); shift 2;;
    -s|--save) SAVE_FILE="${2:-}"; shift 2;;
    -u|--url) URL_OVERRIDE="${2:-}"; shift 2;;
    -v|--verbose) VERBOSE=true; shift;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown option: $1" >&2; usage; exit 2;;
  esac
done

# Normalize client filter month to YYYY-MM and map to API if needed
if [[ -n "$FILTER_MONTH" ]]; then
  if [[ "$FILTER_MONTH" =~ ^([0-9]{4})([0-9]{2})$ ]]; then
    year="${BASH_REMATCH[1]}"; mon="${BASH_REMATCH[2]}"
  elif [[ "$FILTER_MONTH" =~ ^([0-9]{4})-([0-9]{1,2})$ ]]; then
    year="${BASH_REMATCH[1]}"; mon="${BASH_REMATCH[2]}"; printf -v mon "%02d" $((10#$mon))
  else
    echo "Invalid --filter-month. Use YYYYMM or YYYY-MM." >&2; exit 2
  fi
  FILTER_MONTH_DASH="$year-$mon"
  if [[ -z "$SELECTED_MONTH" ]]; then
    SELECTED_MONTH="$year$mon"
  fi
fi

# Build URL
if [[ -n "$URL_OVERRIDE" ]]; then
  URL="$URL_OVERRIDE"
else
  base="https://future.flysas.com/bff/award-finder/destinations/v1"
  URL="$base?market=${MARKET}&origin=${ORIGIN}&destinations=${DESTINATIONS}&passengers=${PASSENGERS}&direct=${DIRECT}&availability=${AVAILABILITY}"
  if [[ -n "$SELECTED_MONTH" ]]; then
    URL+="&selectedMonth=${SELECTED_MONTH}"
  fi
fi

# If list mode and custom jq both passed, prefer custom jq
if [[ -n "$LIST_MODE" && -n "$JQ_FILTER" ]]; then
  echo "Note: custom jq filter provided; ignoring list mode." >&2
  LIST_MODE=""
fi

# If list mode, prepare jq
if [[ -n "$LIST_MODE" ]]; then
  if ! command -v jq >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
    echo "List modes require jq or python3; install one or omit --list." >&2; exit 1
  fi
  seat_select=""
  if [[ -n "$MIN_SEATS" ]]; then
    JQ_ARGS+=(--argjson min "$MIN_SEATS")
    seat_select=' | select((.availableSeatsTotal // 0) >= $min)'
  fi
  month_select=""
  if [[ -n "$FILTER_MONTH_DASH" ]]; then
    JQ_ARGS+=(--arg ym "$FILTER_MONTH_DASH")
    month_select=' | select(((.date // "") | startswith($ym)))'
  fi
  case "$LIST_MODE" in
    outbound)
      JQ_FILTER=".[] | .availability.outbound[]${seat_select}${month_select} | [.date, (.availableSeatsTotal // 0), (.AG // 0), (.AP // 0)] | @tsv";;
    inbound)
      JQ_FILTER=".[] | .availability.inbound[]${seat_select}${month_select} | [.date, (.availableSeatsTotal // 0), (.AG // 0), (.AP // 0)] | @tsv";;
    both)
      JQ_FILTER=".[] | (.availability.outbound[] | . + {direction: \"outbound\"}), (.availability.inbound[] | . + {direction: \"inbound\"})${seat_select}${month_select} | [.direction, .date, (.availableSeatsTotal // 0), (.AG // 0), (.AP // 0)] | @tsv";;
    *) echo "Invalid --list value: $LIST_MODE (use outbound|inbound|both)" >&2; exit 2;;
  esac
fi

# Verbose
if $VERBOSE; then
  echo "GET $URL" >&2
  if ((${#EXTRA_HEADERS[@]})); then printf 'With headers: %q\n' "${EXTRA_HEADERS[@]}" >&2; fi
  if [[ -n "$JQ_FILTER" ]]; then echo "jq filter: $JQ_FILTER" >&2; fi
fi

# Curl command; add basic browser-like headers to reduce 400s
curl_cmd=(curl -fsSL --compressed \
  -H 'Accept: application/json' \
  -H 'Origin: https://www.flysas.com' \
  -H 'Referer: https://www.flysas.com/' \
  -H 'Accept-Language: en-US,en;q=0.8,sv;q=0.6' \
  -A 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36')
curl_cmd+=("${EXTRA_HEADERS[@]}")
curl_cmd+=("$URL")

# Execute and render
if [[ -n "$SAVE_FILE" ]]; then
  if [[ -n "$JQ_FILTER" ]] && command -v jq >/dev/null 2>&1; then
    "${curl_cmd[@]}" | tee "$SAVE_FILE" | jq -r "${JQ_ARGS[@]}" "$JQ_FILTER"
  elif [[ -n "$LIST_MODE" ]] && ! command -v jq >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
    LIST_MODE="$LIST_MODE" YM="$FILTER_MONTH_DASH" MIN_SEATS="${MIN_SEATS:-0}" \
      "${curl_cmd[@]}" | tee "$SAVE_FILE" | python3 - <<'PY'
import os, sys, json
data = json.load(sys.stdin)
mode = os.environ.get('LIST_MODE') or ''
ym = os.environ.get('YM') or ''
try:
    min_seats = int(os.environ.get('MIN_SEATS') or 0)
except Exception:
    min_seats = 0

def emit(dir_key, tag=False):
    arr = []
    if isinstance(data, list) and data:
        arr = data[0].get('availability', {}).get(dir_key, [])
    for x in arr:
        date = x.get('date', '')
        if ym and not date.startswith(ym):
            continue
        seats = int(x.get('availableSeatsTotal', 0) or 0)
        if seats < min_seats:
            continue
        AG = int(x.get('AG', 0) or 0)
        AP = int(x.get('AP', 0) or 0)
        if tag:
            print(f"{dir_key}\t{date}\t{seats}\t{AG}\t{AP}")
        else:
            print(f"{date}\t{seats}\t{AG}\t{AP}")

if mode == 'outbound':
    emit('outbound', tag=False)
elif mode == 'inbound':
    emit('inbound', tag=False)
elif mode == 'both':
    emit('outbound', tag=True)
    emit('inbound', tag=True)
else:
    # No list mode: pretty print
    print(json.dumps(data, indent=2))
PY
  elif command -v jq >/dev/null 2>&1; then
    "${curl_cmd[@]}" | tee "$SAVE_FILE" | jq
  elif command -v python3 >/dev/null 2>&1; then
    "${curl_cmd[@]}" | tee "$SAVE_FILE" | python3 -m json.tool
  else
    "${curl_cmd[@]}" | tee "$SAVE_FILE"
  fi
else
  if [[ -n "$JQ_FILTER" ]] && command -v jq >/dev/null 2>&1; then
    "${curl_cmd[@]}" | jq -r "${JQ_ARGS[@]}" "$JQ_FILTER"
  elif [[ -n "$LIST_MODE" ]] && ! command -v jq >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
    LIST_MODE="$LIST_MODE" YM="$FILTER_MONTH_DASH" MIN_SEATS="${MIN_SEATS:-0}" \
      "${curl_cmd[@]}" | python3 - <<'PY'
import os, sys, json
data = json.load(sys.stdin)
mode = os.environ.get('LIST_MODE') or ''
ym = os.environ.get('YM') or ''
try:
    min_seats = int(os.environ.get('MIN_SEATS') or 0)
except Exception:
    min_seats = 0

def emit(dir_key, tag=False):
    arr = []
    if isinstance(data, list) and data:
        arr = data[0].get('availability', {}).get(dir_key, [])
    for x in arr:
        date = x.get('date', '')
        if ym and not date.startswith(ym):
            continue
        seats = int(x.get('availableSeatsTotal', 0) or 0)
        if seats < min_seats:
            continue
        AG = int(x.get('AG', 0) or 0)
        AP = int(x.get('AP', 0) or 0)
        if tag:
            print(f"{dir_key}\t{date}\t{seats}\t{AG}\t{AP}")
        else:
            print(f"{date}\t{seats}\t{AG}\t{AP}")

if mode == 'outbound':
    emit('outbound', tag=False)
elif mode == 'inbound':
    emit('inbound', tag=False)
elif mode == 'both':
    emit('outbound', tag=True)
    emit('inbound', tag=True)
else:
    # No list mode: pretty print
    print(json.dumps(data, indent=2))
PY
  elif command -v jq >/dev/null 2>&1; then
    "${curl_cmd[@]}" | jq
  elif command -v python3 >/dev/null 2>&1; then
    "${curl_cmd[@]}" | python3 -m json.tool
  else
    "${curl_cmd[@]}"
  fi
fi
