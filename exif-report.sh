#!/usr/bin/env bash
# Usage: ./exif-report.sh <image-file>
# Requires: exiftool, python3, coreutils (md5sum/sha256sum/realpath/basename), awk

set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <image-file>"
  exit 1
fi

FILE="$1"

if [ ! -f "$FILE" ]; then
  echo "File not found: $FILE"
  exit 1
fi

MISSING_DEPS=()
for dep in exiftool python3 awk md5sum sha256sum realpath basename; do
  if ! command -v "$dep" &>/dev/null; then
    MISSING_DEPS+=("$dep")
  fi
done

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
  echo "Error: Missing required dependencies: ${MISSING_DEPS[*]}"
  echo "Please install them using your system package manager (see README.md)."
  exit 1
fi

BOLD="\033[1m"
DIM="\033[2m"
ITALIC="\033[3m"
UNDERLINE="\033[4m"
RESET="\033[0m"

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
CYAN="\033[36m"
WHITE="\033[37m"

BRIGHT_RED="\033[91m"
BRIGHT_GREEN="\033[92m"
BRIGHT_YELLOW="\033[93m"
BRIGHT_BLUE="\033[94m"
BRIGHT_MAGENTA="\033[95m"
BRIGHT_CYAN="\033[96m"
BRIGHT_WHITE="\033[97m"
GRAY="\033[90m"

get() { exiftool -s3 -"$1" -- "$FILE" 2>/dev/null || true; }

FILENAME=$(basename -- "$FILE")
FULLPATH=$(realpath -- "$FILE" 2>/dev/null || echo "$FILE")

MAKE=$(get Make)
MODEL=$(get Model)
LENS=$(get LensModel)
[ -z "$LENS" ] && LENS=$(get FocalLength)

EXPPROG=$(get ExposureProgram)
SHUTTER=$(get ShutterSpeed)
APERTURE=$(get Aperture)
ISO=$(get ISO)
FLASH=$(get Flash)

DATE_RAW=$(get DateTimeOriginal)
[ -z "$DATE_RAW" ] && DATE_RAW=$(get CreateDate)

LAT=$(get GPSLatitude)
LON=$(get GPSLongitude)
LAT_DEC=$(get GPSLatitude#)
LON_DEC=$(get GPSLongitude#)
ALT=$(get GPSAltitude)
DIRECTION=$(get GPSImgDirection)

WIDTH=$(get ImageWidth)
HEIGHT=$(get ImageHeight)
FILESIZE=$(get FileSize)
FILETYPE=$(get FileType)
MIMETYPE=$(get MIMEType)

COLORSPACE=$(get ColorSpace)
ICC=$(get ProfileDescription)

MD5=$(md5sum -- "$FILE" | awk '{print $1}')
SHA256=$(sha256sum -- "$FILE" | awk '{print $1}')

MP=""
ASPECT=""
if [ -n "$WIDTH" ] && [ -n "$HEIGHT" ]; then
  READING=$(python3 -c "
import math
try:
    w = int('$WIDTH')
    h = int('$HEIGHT')
    gcd = math.gcd(w, h) if w > 0 and h > 0 else 1
    mp = f'{w * h / 1000000:.1f}'
    print(f'{mp} {w // gcd}:{h // gcd}')
except Exception:
    pass
" 2>/dev/null || true)
  if [ -n "$READING" ]; then
    MP=$(echo "$READING" | awk '{print $1}')
    ASPECT=$(echo "$READING" | awk '{print $2}')
  fi
fi

TIME_AGO=""
if [ -n "$DATE_RAW" ]; then
  EPOCH_THEN=$(date -d "$(echo "$DATE_RAW" | sed 's/^\([0-9]*\):\([0-9]*\):\([0-9]*\)/\1-\2-\3/')" +%s 2>/dev/null || true)
  EPOCH_NOW=$(date +%s)
  if [ -n "$EPOCH_THEN" ] && [ "$EPOCH_NOW" -ge "$EPOCH_THEN" ]; then
    DIFF=$((EPOCH_NOW - EPOCH_THEN))
    YEARS=$((DIFF / 31536000))
    REM=$((DIFF % 31536000))
    MONTHS=$((REM / 2628000))
    REM=$((REM % 2628000))
    DAYS=$((REM / 86400))
    REM=$((REM % 86400))
    HOURS=$((REM / 3600))
    REM=$((REM % 3600))
    MINUTES=$((REM / 60))
    SECONDS=$((REM % 60))
    
    if [ "$YEARS" -gt 0 ]; then
      TIME_AGO="${YEARS} year$([ "$YEARS" -gt 1 ] && echo "s"), ${MONTHS} month$([ "$MONTHS" -gt 1 ] && echo "s"), ${DAYS} day$([ "$DAYS" -gt 1 ] && echo "s") ago"
    elif [ "$MONTHS" -gt 0 ]; then
      TIME_AGO="${MONTHS} month$([ "$MONTHS" -gt 1 ] && echo "s"), ${DAYS} day$([ "$DAYS" -gt 1 ] && echo "s"), ${HOURS} hour$([ "$HOURS" -gt 1 ] && echo "s") ago"
    elif [ "$DAYS" -gt 0 ]; then
      TIME_AGO="${DAYS} day$([ "$DAYS" -gt 1 ] && echo "s"), ${HOURS} hour$([ "$HOURS" -gt 1 ] && echo "s"), ${MINUTES} min$([ "$MINUTES" -gt 1 ] && echo "s") ago"
    elif [ "$HOURS" -gt 0 ]; then
      TIME_AGO="${HOURS} hour$([ "$HOURS" -gt 1 ] && echo "s"), ${MINUTES} min$([ "$MINUTES" -gt 1 ] && echo "s") ago"
    elif [ "$MINUTES" -gt 0 ]; then
      TIME_AGO="${MINUTES} min$([ "$MINUTES" -gt 1 ] && echo "s"), ${SECONDS} sec$([ "$SECONDS" -gt 1 ] && echo "s") ago"
    else
      TIME_AGO="${SECONDS} seconds ago"
    fi
  fi
fi

field() {
  local label="$1"
  local value="$2"
  printf "  ${CYAN}%-16s${RESET} : ${BRIGHT_WHITE}%s${RESET}\n" "$label" "$value"
}

field_dim() {
  local label="$1"
  local value="$2"
  printf "  ${CYAN}%-16s${RESET} : ${DIM}%s${RESET}\n" "$label" "$value"
}

section_header() {
  local title="$1"
  printf "\n${BOLD}${BRIGHT_CYAN}── %s ──${RESET}\n" "$title"
}

echo
echo -e "${BOLD}${BRIGHT_BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${BRIGHT_BLUE}║${RESET}                            ${BOLD}${BRIGHT_WHITE}EXIF METADATA REPORT${RESET}                              ${BOLD}${BRIGHT_BLUE}║${RESET}"
echo -e "${BOLD}${BRIGHT_BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${RESET}"

section_header "FILE INFORMATION"
field "Target file" "$FILENAME"
field "Full path" "$FULLPATH"
if [ -n "$FILETYPE" ]; then
  field "File type" "${FILETYPE} ${MIMETYPE:+(${MIMETYPE})}"
fi
[ -n "$FILESIZE" ] && field "File size" "$FILESIZE"
if [ -n "$WIDTH" ] && [ -n "$HEIGHT" ]; then
  DIM_INFO="${WIDTH} × ${HEIGHT}"
  [ -n "$MP" ] && [ -n "$ASPECT" ] && DIM_INFO="${DIM_INFO} (${MP} MP, aspect ratio ${ASPECT})"
  field "Dimensions" "$DIM_INFO"
fi
printf "  ${CYAN}%-16s${RESET} : ${GRAY}%s${RESET}\n" "MD5" "$MD5"
printf "  ${CYAN}%-16s${RESET} : ${GRAY}%s${RESET}\n" "SHA256" "$SHA256"

section_header "CAMERA & HARDWARE"
CAMERA_NAME=""
[ -n "$MAKE" ] && CAMERA_NAME="$MAKE"
if [ -n "$MODEL" ]; then
  if [ -n "$CAMERA_NAME" ] && [[ "$MODEL" != "$MAKE"* ]]; then
    CAMERA_NAME="$CAMERA_NAME $MODEL"
  else
    CAMERA_NAME="$MODEL"
  fi
fi
if [ -n "$CAMERA_NAME" ]; then
  field "Camera" "$CAMERA_NAME"
else
  field_dim "Camera" "Not specified"
fi

if [ -n "$LENS" ]; then
  field "Lens" "$LENS"
else
  field_dim "Lens" "Not specified"
fi

section_header "EXPOSURE & SETTINGS"
EXP_SETTINGS=()
[ -n "$SHUTTER" ] && EXP_SETTINGS+=("${SHUTTER}s")
[ -n "$APERTURE" ] && EXP_SETTINGS+=("f/${APERTURE}")
[ -n "$ISO" ] && EXP_SETTINGS+=("ISO ${ISO}")

EXP_STR=""
if [ ${#EXP_SETTINGS[@]} -gt 0 ]; then
  printf -v EXP_STR "%s, " "${EXP_SETTINGS[@]}"
  EXP_STR="${EXP_STR%, }"
  [ -n "$EXPPROG" ] && EXP_STR="${EXP_STR} (${EXPPROG})"
elif [ -n "$EXPPROG" ]; then
  EXP_STR="$EXPPROG"
fi

if [ -n "$EXP_STR" ]; then
  field "Exposure" "$EXP_STR"
else
  field_dim "Exposure" "Not recorded"
fi

if [ -n "$FLASH" ]; then
  field "Flash" "$FLASH"
else
  field_dim "Flash" "Not recorded"
fi

section_header "DATE & TIMESTAMP"
if [ -n "$DATE_RAW" ]; then
  field "Date/Time" "$DATE_RAW"
  [ -n "$TIME_AGO" ] && printf "  %-16s   ${BRIGHT_MAGENTA}(%s)${RESET}\n" "" "$TIME_AGO"
else
  field_dim "Date/Time" "Not recorded"
fi

section_header "GEOLOCATION (GPS)"
if [ -n "$LAT_DEC" ] && [ -n "$LON_DEC" ]; then
  field "Coordinates" "$LAT, $LON"
  printf "  %-16s   ${BRIGHT_YELLOW}(%s, %s)${RESET}\n" "" "$LAT_DEC" "$LON_DEC"
  [ -n "$ALT" ] && field "Altitude" "$ALT"
  [ -n "$DIRECTION" ] && field "Camera Direction" "$DIRECTION"
  echo
  printf "  ${BOLD}${WHITE}%s${RESET}\n" "Map Links:"
  printf "    ${BRIGHT_GREEN}*${RESET} ${DIM}%-12s${RESET} : ${UNDERLINE}${BRIGHT_CYAN}https://www.google.com/maps?q=%s,%s${RESET}\n" "Google" "$LAT_DEC" "$LON_DEC"
  printf "    ${BRIGHT_GREEN}*${RESET} ${DIM}%-12s${RESET} : ${UNDERLINE}${BRIGHT_CYAN}https://www.openstreetmap.org/?mlat=%s&mlon=%s&zoom=17${RESET}\n" "OSM" "$LAT_DEC" "$LON_DEC"
  printf "    ${BRIGHT_GREEN}*${RESET} ${DIM}%-12s${RESET} : ${UNDERLINE}${BRIGHT_CYAN}https://www.bing.com/maps?cp=%s~%s&lvl=17${RESET}\n" "Bing" "$LAT_DEC" "$LON_DEC"
  printf "    ${BRIGHT_GREEN}*${RESET} ${DIM}%-12s${RESET} : ${UNDERLINE}${BRIGHT_CYAN}https://wikimapia.org/#lang=en&lat=%s&lon=%s&z=17${RESET}\n" "Wikimapia" "$LAT_DEC" "$LON_DEC"
  printf "    ${BRIGHT_GREEN}*${RESET} ${DIM}%-12s${RESET} : ${UNDERLINE}${BRIGHT_CYAN}https://www.google.com/maps?layer=c&cbll=%s,%s${RESET}\n" "StreetView" "$LAT_DEC" "$LON_DEC"
else
  field_dim "Location" "No GPS coordinates embedded"
fi

section_header "COLOR & PROFILE"
if [ -n "$COLORSPACE" ]; then
  field "Color Space" "$COLORSPACE"
else
  field_dim "Color Space" "Not specified"
fi

if [ -n "$ICC" ]; then
  field "ICC Profile" "$ICC"
else
  field_dim "ICC Profile" "None"
fi

echo
echo -e "${BOLD}${BRIGHT_BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${BRIGHT_BLUE}║${RESET}                   ${BOLD}${BRIGHT_WHITE}FULL RAW METADATA (BY CATEGORY)${RESET}                            ${BOLD}${BRIGHT_BLUE}║${RESET}"
echo -e "${BOLD}${BRIGHT_BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${RESET}"
echo

exiftool -a -u -g1 -e -api RequestAll=3 -- "$FILE" | awk \
  -v BOLD="$BOLD" -v DIM="$DIM" -v RESET="$RESET" \
  -v HEADER_COLOR="$BOLD$BRIGHT_CYAN" \
  -v KEY_COLOR="$CYAN" \
  -v VAL_COLOR="$BRIGHT_WHITE" \
  -v SEP_COLOR="$DIM" '
/^---- .* ----$/ {
  gsub(/^---- | ----$/, "", $0);
  printf "\n" BOLD "\033[44m\033[97m" " [ %s ] " RESET "\n\n", $0;
  next;
}
/:/ {
  idx = index($0, ":");
  key = substr($0, 1, idx - 1);
  val = substr($0, idx + 1);
  printf KEY_COLOR "%s" RESET SEP_COLOR ":" RESET VAL_COLOR "%s" RESET "\n", key, val;
  next;
}
{ print $0; }
'
