#!/usr/bin/env bash
# =============================================================================
#   B E R K Y T   //   C A M E R A   P O R T   T O O L K I T
#   one console . five modules . two devices (r0q / g0q)
# -----------------------------------------------------------------------------
#   [1] GRAB     <-  grab_stock_cam_libs.sh
#   [2] PURGE    <-  remove_port_cam_libs.sh
#   [3] INJECT   <-  copy_stock_cam_libs.sh
#   [4] SELINUX  <-  fix-selinux-dupes.sh            (apply, with backups)
#   [5] DRY-RUN  <-  fix-selinux-dupes.sh --dry      (preview, writes nothing)
#
#   Usage : ./berkyt_toolkit.sh  [-d r0q|g0q]
#   Menu  : type one or more module numbers   ->   1      |   2 3 4   |   A
#           D = switch device, L = view log, Q = quit
#   Env   : NO_COLOR=1          plain output
#           BERKYT_FAST=1       skip boot animation / delays
#           BERKYT_DEVICE=g0q   preselect device (skips the picker)
#
#   Needs : bash 4.4+, terminal 80 cols wide (24 rows is enough)
# =============================================================================

if (( BASH_VERSINFO[0] < 4 )); then
  echo "bash 4+ required (you have $BASH_VERSION)" >&2
  exit 1
fi

# ================================ CONFIG =====================================
PROJECT="$HOME/Project-Berkyt"

# ---- supported devices ------------------------------------------------------
#   id -> target codename / stock firmware folder / model
DEV_IDS=(r0q g0q)
dev_target() { case "$1" in r0q) echo r0q ;; g0q) echo g0q ;; *) echo r0q ;; esac; }
dev_stock()  { case "$1" in r0q) echo "SM-S901E_TUR" ;; g0q) echo "SM-S906N_KOO" ;; *) echo "" ;; esac; }
dev_model()  { case "$1" in r0q) echo "SM-S901E" ;; g0q) echo "SM-S906N" ;; *) echo "?" ;; esac; }
dev_label()  { printf '%s (%s)' "$(dev_model "$1")" "$(dev_target "$1")"; }

# current selection (overridable with BERKYT_DEVICE=... or -d ...)
DEVICE="${BERKYT_DEVICE:-r0q}"

apply_device() {                       # $1 = r0q | g0q   ->  sets all paths
  case "$1" in
    r0q|g0q) DEVICE="$1" ;;
    *)       DEVICE="r0q" ;;
  esac
  TARGET="$(dev_target "$DEVICE")"
  STOCK_NAME="$(dev_stock "$DEVICE")"
  DEV_MODEL="$(dev_model "$DEVICE")"
  DEV_LABEL="$(dev_label "$DEVICE")"

  TOP="$PROJECT/out/target/$TARGET/work_dir"     # unpacked work_dir
  STOCK_DIR="$PROJECT/out/fw/$STOCK_NAME"        # stock firmware
  OUT="$HOME/stock_camera_libs_$DEVICE"          # stock libs dump (per device)
  SRC="$OUT"                                     # INJECT reads from here
  TMP="$HOME/stock_extract_tmp_$DEVICE"          # GRAB scratch dir (per device)
}
apply_device "$DEVICE"

# ---- files GRAB pulls from stock / INJECT copies into work_dir ---------------
ADD_LIST=(
  "system/etc/public.libraries-arcsoft.txt"
  "system/etc/public.libraries-camera.samsung.txt"
  "system/lib/libSlowShutter_jni.media.samsung.so"
  "system/lib64/libDualCamBokehCapture.camera.samsung.so"
  "system/lib64/libFace_Landmark_Engine.camera.samsung.so"
  "system/lib64/libHREnhancementAPI.camera.samsung.so"
  "system/lib64/libHpr_RecFace_dl_v1.0.camera.samsung.so"
  "system/lib64/libImageCropper.camera.samsung.so"
  "system/lib64/libImageTagger.camera.samsung.so"
  "system/lib64/libLocalTM_pcc.camera.samsung.so"
  "system/lib64/libMultiFrameProcessing30.camera.samsung.so"
  "system/lib64/libMultiFrameProcessing30.snapwrapper.camera.samsung.so"
  "system/lib64/libMultiFrameProcessing30Tuning.camera.samsung.so"
  "system/lib64/libPortraitDistortionCorrection.arcsoft.so"
  "system/lib64/libSlowShutter_jni.media.samsung.so"
  "system/lib64/libSwIsp_core.camera.samsung.so"
  "system/lib64/libSwIsp_wrapper_v1.camera.samsung.so"
  "system/lib64/libae_bracket_hdr.arcsoft.so"
  "system/lib64/libarcsoft_dualcam_portraitlighting.so"
  "system/lib64/libarcsoft_superresolution_bokeh.so"
  "system/lib64/libdualcam_refocus_image.so"
  "system/lib64/libhighres_enhancement.arcsoft.so"
  "system/lib64/libhumantracking.arcsoft.so"
  "system/lib64/libhybridHDR_wrapper.camera.samsung.so"
  "system/lib64/libhybrid_high_dynamic_range.arcsoft.so"
  "system/lib64/libsaiv_HprFace_cmh_support_jni.camera.samsung.so"
  "system/lib64/libsamsung_videoengine_9_0.so"
  "system/lib64/libsuperresolution_raw.arcsoft.so"
  "system/lib64/libsuperresolutionraw_wrapper_v2.camera.samsung.so"
)

# ---- files PURGE deletes from work_dir ---------------------------------------
TO_DELETE=(
  "system/lib/FrcMcWrapper.so"
  "system/lib/libFrucPSVTLib.so"
  "system/lib/libSemanticMap_v1.camera.samsung.so"
  "system/lib/libSlowShutter-core.so"
  "system/lib/libaifrc.aidl.quram.so"
  "system/lib/libaifrcInterface.camera.samsung.so"
  "system/lib/libgpuss_wrapper.so"
  "system/lib/libmcaimegpu.samsung.so"
  "system/lib/vendor.samsung.hardware.frcmc-V1-ndk.so"
  "system/lib64/FrcMcWrapper.so"
  "system/lib64/libDocDeblur.camera.samsung.so"
  "system/lib64/libDocDeblur.enhanceX.samsung.so"
  "system/lib64/libDocObjectRemoval.camera.samsung.so"
  "system/lib64/libDocObjectRemoval.enhanceX.samsung.so"
  "system/lib64/libFrucPSVTLib.so"
  "system/lib64/libPetClustering.camera.samsung.so"
  "system/lib64/libSemanticMap_v1.camera.samsung.so"
  "system/lib64/libSlowShutter-core.so"
  "system/lib64/libWideDistortionCorrection.camera.samsung.so"
  "system/lib64/libacz_hhdr.arcsoft.so"
  "system/lib64/libaiclearzoom_raw.arcsoft.so"
  "system/lib64/libaiclearzoomraw_wrapper_v1.camera.samsung.so"
  "system/lib64/libaifrc.aidl.quram.so"
  "system/lib64/libaifrcInterface.camera.samsung.so"
  "system/lib64/libgpuss_wrapper.so"
  "system/lib64/libmcaimegpu.samsung.so"
  "system/lib64/vendor.samsung.hardware.frcmc-V1-ndk.so"
)

# ============================== UI : STATE ===================================
BOX_W=78            # width of every panel
HUD_H=9             # height of the live status box
HUD_ON=0
HUD_ROWS=24
FX=0                # animations on/off (set in main)
FX_DELAY=0.02       # tiny per-item delay so the live box is readable
USE_COLOR=0
FRAME_C=""
TAG_T=""; TAG_C=""
RT=""               # runtime dir (set in main)
FEED=""; SESSION=""; HIST=""

# ============================== UI : PALETTE =================================
init_colors() {
  USE_COLOR=0
  C_RST="" C_BOLD="" C_DIM="" C_BORD="" C_TITLE="" C_CYAN="" C_PINK=""
  C_AMBER="" C_GRN="" C_RED="" C_GREY="" C_WHT=""
  if [[ -z "${NO_COLOR:-}" && ( -t 1 || "${FORCE_COLOR:-}" == 1 ) ]]; then
    USE_COLOR=1
    C_RST=$'\e[0m';              C_BOLD=$'\e[1m';            C_DIM=$'\e[2m'
    C_BORD=$'\e[38;5;129m';      C_TITLE=$'\e[1;38;5;51m'
    C_CYAN=$'\e[38;5;51m';       C_PINK=$'\e[38;5;205m';     C_AMBER=$'\e[38;5;214m'
    C_GRN=$'\e[38;5;46m';        C_RED=$'\e[38;5;196m'
    C_GREY=$'\e[38;5;244m';      C_WHT=$'\e[38;5;252m'
  fi
  FRAME_C="$C_BORD"
}

# ============================ UI : PRIMITIVES ================================
# repv VAR CHAR COUNT   -> VAR = CHAR x COUNT   (no subshell, fast)
repv() {
  local n="$3" s
  (( n < 0 )) && n=0
  printf -v s '%*s' "$n" ''
  printf -v "$1" '%s' "${s// /$2}"
}

box_top() {  # title
  local t="$1" k R
  k=$(( BOX_W - 8 - ${#t} ))
  repv R '─' "$k"
  printf '%s┌──[ %s%s%s ]%s─%s\n' "$FRAME_C" "$C_TITLE" "$t" "$FRAME_C" "$R" "$C_RST"
}
box_bot() {
  local R; repv R '─' $(( BOX_W - 2 ))
  printf '%s└%s┘%s\n' "$FRAME_C" "$R" "$C_RST"
}
box_sep() {
  local R; repv R '─' $(( BOX_W - 2 ))
  printf '%s├%s┤%s\n' "$FRAME_C" "$R" "$C_RST"
}
box_row() {  # color text
  local w=$(( BOX_W - 4 )) t="${2:0:$(( BOX_W - 4 ))}"
  printf '%s│%s %s%-*s%s %s│%s\n' "$FRAME_C" "$C_RST" "$1" "$w" "$t" "$C_RST" "$FRAME_C" "$C_RST"
}
box_kv() {   # label value [value_color]
  local w=$(( BOX_W - 4 )) lab val pad
  printf -v lab '%-10s' "$1"
  val="${2:0:$(( w - 12 ))}"
  pad=$(( w - 12 - ${#val} ))
  printf '%s│%s %s%s%s: %s%s%s%*s %s│%s\n' \
    "$FRAME_C" "$C_RST" "$C_GREY" "$lab" "$C_RST" "${3:-$C_WHT}" "$val" "$C_RST" "$pad" "" "$FRAME_C" "$C_RST"
}
box_status() {  # label value badge badge_color
  local w=$(( BOX_W - 4 )) lab val vw pad
  vw=$(( w - 12 - 11 - 1 ))
  printf -v lab '%-10s' "$1"
  val="$2"
  if (( ${#val} > vw )); then val="...${val: -$(( vw - 3 ))}"; fi
  pad=$(( vw - ${#val} ))
  printf '%s│%s %s%s%s: %s%s%s%*s %s[%-9s]%s %s│%s\n' \
    "$FRAME_C" "$C_RST" "$C_GREY" "$lab" "$C_RST" "$C_WHT" "$val" "$C_RST" "$pad" "" "$4" "$3" "$C_RST" "$FRAME_C" "$C_RST"
}
log_row() {  # time tag message
  local mw=$(( BOX_W - 20 )) m="${3:0:$(( BOX_W - 20 ))}"
  tag_fmt "$2"
  printf '%s│%s %s%s%s [%s%s%s] %s%-*s%s %s│%s\n' \
    "$FRAME_C" "$C_RST" "$C_GREY" "$1" "$C_RST" "$TAG_C" "$TAG_T" "$C_RST" "$C_WHT" "$mw" "$m" "$C_RST" "$FRAME_C" "$C_RST"
}
menu_row() { # key name description
  local dw=$(( BOX_W - 22 )) d="${3:0:$(( BOX_W - 22 ))}"
  printf '%s│%s %s  [%s%s%s]%s  %s%-9s%s  %s%-*s%s %s│%s\n' \
    "$FRAME_C" "$C_RST" "$C_GREY" "$C_AMBER" "$1" "$C_GREY" "$C_RST" "$C_CYAN" "$2" "$C_RST" \
    "$C_WHT" "$dw" "$d" "$C_RST" "$FRAME_C" "$C_RST"
}

tag_fmt() {  # sets TAG_T (4 chars) + TAG_C
  case "$1" in
    OK)   TAG_T=" OK "; TAG_C="$C_GRN"   ;;
    RM)   TAG_T=" RM "; TAG_C="$C_RED"   ;;
    --)   TAG_T=" -- "; TAG_C="$C_GREY"  ;;
    INFO) TAG_T="INFO"; TAG_C="$C_CYAN"  ;;
    RUN)  TAG_T=" RUN"; TAG_C="$C_PINK"  ;;
    FIX)  TAG_T=" FIX"; TAG_C="$C_GRN"   ;;
    DEL)  TAG_T=" DEL"; TAG_C="$C_RED"   ;;
    DRY)  TAG_T=" DRY"; TAG_C="$C_AMBER" ;;
    SKIP) TAG_T="SKIP"; TAG_C="$C_GREY"  ;;
    MISS) TAG_T="MISS"; TAG_C="$C_AMBER" ;;
    WARN) TAG_T="WARN"; TAG_C="$C_AMBER" ;;
    ERR)  TAG_T=" ERR"; TAG_C="$C_RED"   ;;
    FAIL) TAG_T="FAIL"; TAG_C="$C_RED"   ;;
    *)    printf -v TAG_T '%-4.4s' "$1"; TAG_C="$C_WHT" ;;
  esac
}

gradient_bar() {  # char
  local cols=(201 200 171 135 99 51) i idx esc=""
  for (( i = 0; i < BOX_W; i++ )); do
    idx=$(( i / 13 )); (( idx > 5 )) && idx=5
    if (( USE_COLOR )); then printf -v esc '\e[38;5;%sm' "${cols[idx]}"; fi
    printf '%s%s' "$esc" "$1"
  done
  printf '%s\n' "$C_RST"
}

short_path() {
  if [[ "$1" == "$HOME"* ]]; then printf '~%s' "${1#"$HOME"}"; else printf '%s' "$1"; fi
}

# ============================== UI : BANNER ==================================
draw_banner() {  # [slow]
  local cols=(199 198 171 135 99 51) i=0 line esc="" pad
  repv pad ' ' $(( (BOX_W - 50) / 2 ))
  while IFS= read -r line; do
    if (( USE_COLOR )); then printf -v esc '\e[38;5;%sm' "${cols[i]}"; fi
    printf '%s%s%s%s\n' "$pad" "$esc" "$line" "$C_RST"
    i=$(( i + 1 ))
    [[ "${1:-}" == slow ]] && sleep 0.05
  done <<'EOF'
██╗██╗██╗██╗██╗██╗╗ ██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗██╗ ██╗██╗  ██╗██╗██╗   ██╗██╗██╗██╗██╗██╗██╗██╗██╗
██║██╔══██║██╔════╝██║██╔══██║██║██║ ██║██╔╝╚██╗██║ ██╔╝╚██╗██╔══██║██╔══╝
██║██████╔╝██║     ██║██████╔╝██║███████║  ╚███╔╝    ██║   ██║
██║██╔══██╗██║     ██║██╔══██╗██║██╔══██║  ██╔██╗    ██║   ██║
██║██████╔╝███████╗██║██║  ██║██║██║  ██║ ██╔╝ ██╗   ██║   ██║
╚═╝╚═════╝ ╚══════╝╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝
EOF
  gradient_bar '─'
  local t="CAMERA PORT TOOLKIT  //  $TARGET  //  $DEV_MODEL  //  v1.0" l
  l=$(( ${#t} + 8 ))
  repv pad ' ' $(( (BOX_W - l) / 2 ))
  printf '%s%s┌┬┐ %s%s%s%s └┬┘%s\n' "$pad" "$C_PINK" "$C_BOLD" "$C_CYAN" "$t" "$C_RST$C_PINK" "$C_RST"
  gradient_bar '─'
}

draw_title_compact() {
  printf '  %s┌┬┐%s %sBERKYT%s %s//%s %sCAMERA PORT TOOLKIT%s  %s%s . %s . v1.0%s\n' \
    "$C_PINK" "$C_RST" "$C_BOLD$C_CYAN" "$C_RST" "$C_PINK" "$C_RST" "$C_CYAN" "$C_RST" \
    "$C_GREY" "$TARGET" "$DEV_MODEL" "$C_RST"
  gradient_bar '─'
}

# ============================== UI : PANELS ==================================
draw_scan() {
  local FRAME_C="$C_BORD" badge bc n
  box_top "SYSTEM SCAN"
  box_status "DEVICE" "$DEV_MODEL" "$TARGET" "$C_CYAN"
  if   [ -d "$TOP/system/system/lib64" ]; then badge="NESTED";    bc="$C_GRN"
  elif [ -d "$TOP/system/lib64" ];        then badge="FLAT";      bc="$C_GRN"
  elif [ -d "$TOP" ];                     then badge="NO ROOTFS"; bc="$C_AMBER"
  else                                         badge="MISSING";   bc="$C_RED"; fi
  box_status "WORK_DIR" "$(short_path "$TOP")" "$badge" "$bc"
  if [ -d "$STOCK_DIR" ]; then badge="ONLINE";  bc="$C_GRN"
  else                         badge="MISSING"; bc="$C_RED"; fi
  box_status "STOCK FW" "$(short_path "$STOCK_DIR")" "$badge" "$bc"
  n=$(find "$OUT" -type f 2>/dev/null | wc -l); n=$(( n + 0 ))
  if (( n > 0 )); then badge="$n FILES"; bc="$C_GRN"
  else                 badge="EMPTY";    bc="$C_AMBER"; fi
  box_status "LIB CACHE" "$(short_path "$OUT")" "$badge" "$bc"
  box_bot
}

menu_task() { task_meta "$1"; menu_row "$1" "$T_NAME" "$T_DESC"; }

draw_modules() {
  local FRAME_C="$C_BORD"
  box_top "MODULES"
  menu_task 1
  menu_task 2
  menu_task 3
  menu_task 4
  menu_task 5
  menu_row A ALL  "Run 1 > 2 > 3 > 4 in order (stops on first failure)"
  menu_row D DEV  "Switch device  (current: $DEV_LABEL)"
  menu_row L LOG  "Browse the full session log"
  menu_row Q QUIT "Exit the toolkit"
  box_bot
}

draw_history() {  # rows
  local FRAME_C="$C_BORD" n="$1" i line ts st nm dt msg
  local lines=()
  box_top "MISSION LOG"
  mapfile -t lines < <(tail -n "$n" "$HIST" 2>/dev/null)
  if (( ${#lines[@]} == 0 )); then
    box_row "$C_GREY" "-- no operations logged yet --"
    for (( i = 1; i < n; i++ )); do box_row "" ""; done
  else
    for line in "${lines[@]}"; do
      IFS='|' read -r ts st nm dt <<< "$line"
      printf -v msg '%-11s %s' "$nm" "$dt"
      log_row "$ts" "$st" "$msg"
    done
    for (( i = ${#lines[@]}; i < n; i++ )); do box_row "" ""; done
  fi
  box_bot
}

draw_menu() {
  local rows
  rows=$(tput lines 2>/dev/null || echo 24)
  (( USE_COLOR )) && printf '\e[2J\e[H'
  if (( rows >= 34 )); then
    draw_banner; draw_scan; draw_modules; draw_history 4
  else
    draw_title_compact; draw_scan; draw_modules; draw_history 2
  fi
}

# ============================ UI : LIVE STATUS BOX ===========================
# The box lives in files under $RT so the main shell and the task subshell
# always agree on what to show.
hud_put() { printf '%s\n' "$2" > "$RT/hud.$1"; }
hud_get() { IFS= read -r "$2" < "$RT/hud.$1" || true; }
prog_set() { hud_put prog "$1 $2"; }

hud_box() {
  local FRAME_C label state="" task="" now="" pi=0 pn=0 bc
  local bar_w=30 filled=0 pct=0 tail_s lead='PROGRESS [' used pad bf="" be="" b
  local rows=() r line ts tg m
  hud_get state state; hud_get task task; hud_get now now
  IFS=' ' read -r pi pn < "$RT/hud.prog" || true
  pi=${pi:-0}; pn=${pn:-0}
  bc="$C_GRN"
  case "$state" in
    OK)   FRAME_C="$C_GRN";   label="COMPLETE" ;;
    FAIL) FRAME_C="$C_RED";   label="FAILED"; bc="$C_RED" ;;
    RUN)  FRAME_C="$C_AMBER"; label="RUNNING"  ;;
    *)    FRAME_C="$C_BORD";  label="STANDBY"  ;;
  esac
  box_top "BERKYT//CORE :: $label"
  box_kv "TASK" "$task" "$C_CYAN"
  box_kv "NOW"  "$now"  "$C_AMBER"
  if (( pn > 0 )); then
    pct=$(( pi * 100 / pn )); filled=$(( pi * bar_w / pn ))
    if (( filled > bar_w )); then filled=$bar_w; fi
    printf -v tail_s ' %d/%d  %d%%' "$pi" "$pn" "$pct"
  else
    tail_s=' --/--  n/a'
  fi
  used=$(( ${#lead} + bar_w + 1 + ${#tail_s} ))
  pad=$(( BOX_W - 4 - used )); if (( pad < 0 )); then pad=0; fi
  for (( b = 0; b < filled; b++ ));    do bf+="█"; done
  for (( b = filled; b < bar_w; b++ )); do be+="░"; done
  printf '%s│%s %s%s%s%s%s%s%s]' "$FRAME_C" "$C_RST" "$C_GREY" "$lead" "$bc" "$bf" "$C_GREY" "$be" "$C_GREY"
  printf '%s%s%s%*s %s│%s\n' "$C_WHT" "$tail_s" "$C_RST" "$pad" "" "$FRAME_C" "$C_RST"
  box_sep
  mapfile -t rows < <(tail -n 3 "$FEED" 2>/dev/null)
  for r in 0 1 2; do
    line="${rows[$r]:-}"
    if [[ -z "$line" ]]; then
      box_row "" ""
    else
      IFS='|' read -r ts tg m <<< "$line"
      log_row "$ts" "$tg" "$m"
    fi
  done
  box_bot
}

hud_draw() {   # redraw pinned box in place (top of screen)
  (( HUD_ON )) || return 0
  printf '\e7\e[1;1H'
  hud_box
  printf '\e8'
  return 0
}

hud_begin() {
  HUD_ON=0
  [[ -t 1 ]] || return 0
  printf '\e[2J\e[H'
  local rows cols
  rows=$(tput lines 2>/dev/null || echo 0)
  cols=$(tput cols  2>/dev/null || echo 0)
  (( rows >= HUD_H + 10 && cols >= BOX_W + 2 )) || return 0
  HUD_ON=1; HUD_ROWS=$rows
  hud_draw
  printf '\e[%d;%dr\e[%d;1H' $(( HUD_H + 1 )) "$rows" $(( HUD_H + 1 ))   # scroll region below the box
}

hud_end() {
  if (( HUD_ON )); then
    hud_draw
    printf '\n\e7\e[r\e8'          # release scroll region, keep cursor where it is
    HUD_ON=0
  else
    echo; hud_box
  fi
}

hud_now() { hud_put now "$1"; hud_draw; }

# ============================ UI : EVENT LOGGING =============================
log_only() {   # tag message   (feeds live box + session log, prints nothing)
  local ts
  printf -v ts '%(%H:%M:%S)T' -1
  printf '%s|%s|%s\n' "$ts" "$1" "$2" >> "$FEED"
  tag_fmt "$1"
  printf '%s [%s] %s\n' "$ts" "$TAG_T" "$2" >> "$SESSION"
  hud_put now "$2"
  hud_draw
  return 0
}

emit() {       # tag message...   (styled line + log)
  local tag="$1"; shift
  local msg="$*"
  tag_fmt "$tag"
  printf '  %s[%s%s%s]%s %s\n' "$C_BORD" "$TAG_C" "$TAG_T" "$C_BORD" "$C_RST" "$msg"
  if [[ "$tag" == ERR ]]; then printf '%s\n' "$msg" > "$RT/lasterr"; fi
  log_only "$tag" "$msg"
}

note() { printf '    %s%s%s\n' "$C_GREY" "$*" "$C_RST"; }

section() {
  local R
  repv R '─' $(( ${#1} + 4 ))
  printf '\n  %s▌%s %s%s%s\n  %s%s%s\n' "$C_PINK" "$C_RST" "$C_BOLD$C_CYAN" "$1" "$C_RST" "$C_BORD" "$R" "$C_RST"
  log_only RUN "$1"
}

module_header() {  # id name desc
  printf '\n  %s┌┬┐ MODULE %s :: %s └┬┘%s\n' "$C_PINK$C_BOLD" "$1" "$2" "$C_RST"
  printf '  %s%s%s\n' "$C_GREY" "$3" "$C_RST"
}

report_box() {  # title  label value color  [label value color ...]
  local BOX_W=52 FRAME_C="$C_CYAN" title="$1"
  shift
  echo
  box_top "$title"
  while (( $# >= 3 )); do
    box_kv "$1" "$2" "$3"
    shift 3
  done
  box_bot
}

set_summary() { printf '%s\n' "$1" > "$RT/summary"; }
fx_pause()    { (( FX )) && sleep "$FX_DELAY"; return 0; }

# ============================ SHARED TASK HELPERS ============================
# Auto-detect: is the real rootfs at TOP/system or TOP/system/system ?
locate_sys() {   # $1 = verb ("using" / "writing to")  -> sets SYS
  if [ -d "$TOP/system/system/lib64" ]; then
    SYS="$TOP/system"
    emit INFO "Detected nested layout: $1 $SYS"
  elif [ -d "$TOP/system/lib64" ]; then
    SYS="$TOP"
    emit INFO "Detected flat layout: $1 $SYS"
  else
    emit ERR "cannot locate system rootfs under $TOP"
    exit 1
  fi
}

# lz4 -> sparse -> raw -> lpunpack      (sets SEARCH_DIR in the caller)
unpack_super() {  # $1 = super image
  local SUPER="$1"
  command -v lpunpack >/dev/null || {
    emit ERR "lpunpack not installed."
    emit INFO "Install: sudo apt install android-sdk-libsparse-utils lz4"
    exit 1
  }
  # Decompress LZ4 if needed
  if file "$SUPER" | grep -qi "lz4"; then
    emit RUN "Decompressing LZ4..."
    lz4 -d "$SUPER" "$TMP/super_decomp.img"
    SUPER="$TMP/super_decomp.img"
  fi
  # Convert sparse to raw if needed
  if file "$SUPER" | grep -qi "sparse"; then
    emit RUN "Converting sparse -> raw..."
    simg2img "$SUPER" "$TMP/super_raw.img"
    SUPER="$TMP/super_raw.img"
  fi
  emit RUN "Running lpunpack..."
  lpunpack "$SUPER" "$TMP/extracted/"
  SEARCH_DIR="$TMP/extracted"
}

# ============================ MODULE 1 : GRAB ================================
task_grab() {
  # ---- Sanity check ----
  [ -d "$STOCK_DIR" ] || { emit ERR "$STOCK_DIR not found"; exit 1; }

  rm -rf "$OUT" "$TMP"
  mkdir -p "$OUT" "$TMP"

  section "Stock firmware directory contents (top 2 levels)"
  printf '%s' "$C_GREY"
  find "$STOCK_DIR" -maxdepth 2 \( -type f -o -type d \) | head -40 | sed 's/^/    /'
  printf '%s' "$C_RST"

  local SEARCH_DIR="" SUPER AP

  # ---- Case 1: already extracted (has system/ folder) ----
  if [ -d "$STOCK_DIR/system" ]; then
    emit INFO "Detected: extracted stock (system/ exists)"
    SEARCH_DIR="$STOCK_DIR"
  fi

  # ---- Case 2: super.img present ----
  if [ -z "$SEARCH_DIR" ]; then
    SUPER=$(find "$STOCK_DIR" -maxdepth 2 -iname "super.img*" | head -1)
    if [ -n "$SUPER" ]; then
      emit INFO "Detected: $SUPER"
      unpack_super "$SUPER"
    fi
  fi

  # ---- Case 3: AP_*.tar.md5 present ----
  if [ -z "$SEARCH_DIR" ]; then
    AP=$(find "$STOCK_DIR" -maxdepth 2 -iname "AP_*.tar.md5" | head -1)
    if [ -n "$AP" ]; then
      emit INFO "Detected AP tar: $AP"
      mkdir -p "$TMP/ap_extract"
      hud_now "extracting AP tar (this can take a while)"
      tar --ignore-failed-read -xf "$AP" -C "$TMP/ap_extract/" 2>/dev/null || \
          tar -xf "$AP" -C "$TMP/ap_extract/"

      SUPER=$(find "$TMP/ap_extract" -iname "super.img*" | head -1)
      [ -n "$SUPER" ] || { emit ERR "no super.img in AP"; exit 1; }
      unpack_super "$SUPER"
    fi
  fi

  [ -n "$SEARCH_DIR" ] || {
    emit ERR "Could not detect stock firmware format in $STOCK_DIR"
    emit INFO "Please run 'ls -la $STOCK_DIR' and share the output."
    exit 1
  }

  emit INFO "Search dir: $SEARCH_DIR"

  # ---- Copy phase ----
  local MISSING=() COPIED=0 total=${#ADD_LIST[@]} i=0 path filename found
  section "Copying camera libs out of stock  ($total files)"
  for path in "${ADD_LIST[@]}"; do
    i=$(( i + 1 )); prog_set "$i" "$total"
    filename=$(basename "$path")
    found=$(find "$SEARCH_DIR" -type f -name "$filename" 2>/dev/null | head -1)

    if [ -z "$found" ]; then
      MISSING+=("$path")
      emit MISS "$path"
      continue
    fi

    mkdir -p "$OUT/$(dirname "$path")"
    cp "$found" "$OUT/$path"
    COPIED=$(( COPIED + 1 ))
    emit OK "$path"
    fx_pause
  done

  # ---- Report ----
  local mc="$C_GRN"
  if (( ${#MISSING[@]} > 0 )); then mc="$C_RED"; fi
  report_box "GRAB REPORT" "Copied" "$COPIED / $total" "$C_GRN" "Missing" "${#MISSING[@]}" "$mc"
  if [ ${#MISSING[@]} -gt 0 ]; then
    echo
    printf '  %sMISSING FILES (investigate manually):%s\n' "$C_AMBER" "$C_RST"
    printf '  %s\n' "${MISSING[@]}"
  fi

  # ---- Package ----
  cd "$HOME"
  hud_now "packing stock_camera_libs_$DEVICE.tar.gz"
  tar czf "stock_camera_libs_$DEVICE.tar.gz" "$(basename "$OUT")"
  echo
  emit OK "Archive: ~/stock_camera_libs_$DEVICE.tar.gz"
  printf '  %s' "$C_CYAN"
  du -sh "$HOME/stock_camera_libs_$DEVICE.tar.gz"
  printf '%s' "$C_RST"

  set_summary "copied $COPIED / $total, missing ${#MISSING[@]}"
}

# ============================ MODULE 2 : PURGE ===============================
task_remove() {
  locate_sys "using"

  local total=${#TO_DELETE[@]} i=0 REMOVED=0 MISSING=0 f target
  section "Removing port camera libs  ($total targets)"
  for f in "${TO_DELETE[@]}"; do
    target="$SYS/$f"
    i=$(( i + 1 )); prog_set "$i" "$total"
    if [ -f "$target" ]; then
      rm -f "$target"
      emit RM "$f"
      REMOVED=$(( REMOVED + 1 ))
    else
      emit -- "$f (not present)"
      MISSING=$(( MISSING + 1 ))
    fi
    fx_pause
  done

  report_box "PURGE REPORT" "Removed" "$REMOVED" "$C_RED" "Absent" "$MISSING" "$C_GREY"
  set_summary "removed $REMOVED / absent $MISSING"
}

# ============================ MODULE 3 : INJECT ==============================
task_copy() {
  locate_sys "writing to"

  [ -d "$SRC/system" ] || { emit ERR "$SRC/system not found - run module [1] GRAB first"; exit 1; }

  local total=${#ADD_LIST[@]} i=0 COPIED=0 MISSING=0 f src dst
  section "Injecting stock camera libs  ($total files)"
  for f in "${ADD_LIST[@]}"; do
    src="$SRC/$f"
    dst="$SYS/$f"
    i=$(( i + 1 )); prog_set "$i" "$total"
    if [ ! -f "$src" ]; then
      emit MISS "MISSING in stock dump: $f"
      MISSING=$(( MISSING + 1 ))
      continue
    fi
    mkdir -p "$(dirname "$dst")"
    cp -f "$src" "$dst"
    chmod 644 "$dst"
    emit OK "$f"
    COPIED=$(( COPIED + 1 ))
    fx_pause
  done

  local mc="$C_GRN"
  if (( MISSING > 0 )); then mc="$C_RED"; fi
  report_box "INJECT REPORT" "Copied" "$COPIED" "$C_GRN" "Missing" "$MISSING" "$mc"
  set_summary "copied $COPIED / missing $MISSING"
}

# ========================= MODULE 4/5 : SELINUX ==============================
# Removes duplicate SELinux context entries across partitions in a
# UN1CA-style unpacked work_dir.
#
#   * Scans *_service_contexts and *_property_contexts in product,
#     system, system_ext, vendor.
#   * Finds keys that carry more than one distinct label.
#   * Decides which partition should own each key (see keep rules).
#   * Deletes the redundant copies from the other partitions.
#   * Backs up every file it touches.
#   * Whitelists AOSP's intentional *_service / *_vndservice splits.

# ---------------------------------------------------------------
# Locate context files
# ---------------------------------------------------------------
find_one() { find "$WORK" -type f -name "$1" 2>/dev/null | head -n1; }

# ---------------------------------------------------------------
# Partition priority (higher wins ties)
# ---------------------------------------------------------------
part_of() {
  case "$1" in
    */product/etc/selinux/*)    echo product ;;
    */system_ext/etc/selinux/*) echo system_ext ;;
    */vendor/etc/selinux/*)     echo vendor ;;
    */system/system/etc/selinux/*|*/system/etc/selinux/*) echo system ;;
    *) echo unknown ;;
  esac
}
prio_of() {
  case "$(part_of "$1")" in
    product)    echo 1 ;;
    system)     echo 2 ;;
    system_ext) echo 3 ;;
    vendor)     echo 4 ;;
    *)          echo 0 ;;
  esac
}

# ---------------------------------------------------------------
# Whitelist of intentional _service / _vndservice splits
# ---------------------------------------------------------------
is_whitelisted_service() {
  case "$1" in
    '*'|manager) return 0 ;;
    EngineeringModeService|WlanDutService|android.samsung.IRemosaicDaemon) return 0 ;;
  esac
  return 1
}

# ---------------------------------------------------------------
# Keep rules
# ---------------------------------------------------------------
keep_part_service() {
  case "$1" in
    vendor.*|*.qti.*|com.qualcomm.*|org.codeaurora.*) echo vendor ;;
    android.hardware.*|android.system.*|com.android.*) echo system ;;
    *) echo system ;;
  esac
}

keep_part_property() {
  case "$1" in
    ro.vendor.*|persist.vendor.*|vendor.*|ro.hardware.*|ro.boot.*) echo vendor ;;
    ro.telephony.*|persist.radio.*|gsm.*|ril.*)                     echo system_ext ;;
    service.bootanim.*|service.bootchecker.*)                       echo system_ext ;;
    ro.product.*|ro.build.*|ro.system.*|ro.system_ext.*)            echo system ;;
    *)                                                              echo system ;;
  esac
}

# ---------------------------------------------------------------
# Backup
# ---------------------------------------------------------------
backup_file() {
  local f="$1"
  local base
  base="$(echo "$f" | sed 's|/|_|g')"
  [[ -f "$BACKUP/$base" ]] || cp "$f" "$BACKUP/$base"
}

# ---------------------------------------------------------------
# Parse "key|label|file" from a context file
# ---------------------------------------------------------------
parse_ctx() {
  awk -v s="$1" '
    /^[[:space:]]*#/ { next }
    NF < 2 { next }
    { print $1 "|" $2 "|" s }
  ' "$1"
}

# ---------------------------------------------------------------
# Core: fix one family of context files
# ---------------------------------------------------------------
fix_family() {
  local kind="$1"   # "service" or "property"
  shift
  local files=("$@")
  local keep_fn="keep_part_${kind}"
  local whitelist=""
  [[ "$kind" == "service" ]] && whitelist="is_whitelisted_service"
  local dtag=DEL
  [[ "$DRY" == "--dry" ]] && dtag=DRY

  section "${kind^^} CONTEXTS"

  local tmp; tmp="$(mktemp)"
  local cfl; cfl="$(mktemp)"

  for f in "${files[@]}"; do parse_ctx "$f"; done | sort -u > "$tmp"

  awk -F'|' '{print $1"|"$2}' "$tmp" | sort -u \
  | awk -F'|' '{n[$1]++; t[$1]=t[$1]" "$2} END {for (s in n) if (n[s]>1) print s}' \
  | sort -u > "$cfl"

  if [[ ! -s "$cfl" ]]; then
    emit OK "no conflicts."
    rm -f "$tmp" "$cfl"
    return
  fi

  local total i=0
  total="$(wc -l < "$cfl" | tr -d ' ')"
  SEL_CONFLICTS=$(( SEL_CONFLICTS + total ))

  while IFS= read -r key; do
    [[ -z "$key" ]] && continue
    i=$(( i + 1 )); prog_set "$i" "$total"

    if [[ -n "$whitelist" ]] && "$whitelist" "$key"; then
      emit SKIP "whitelisted: $key"
      SEL_SKIPPED=$(( SEL_SKIPPED + 1 ))
      continue
    fi

    local keep_part; keep_part="$("$keep_fn" "$key")"

    # files containing this exact key
    local hits=()
    while IFS= read -r h; do hits+=("$h"); done \
      < <(awk -F'|' -v k="$key" '$1==k {print $3}' "$tmp" | sort -u)

    # pick target = a file in keep_part, else highest priority
    local target="" best=-1
    for h in "${hits[@]}"; do
      if [[ "$(part_of "$h")" == "$keep_part" ]]; then target="$h"; break; fi
    done
    if [[ -z "$target" ]]; then
      for h in "${hits[@]}"; do
        local p; p="$(prio_of "$h")"
        if (( p > best )); then best="$p"; target="$h"; fi
      done
    fi

    emit FIX "$key  -> keep in $(part_of "$target")"
    SEL_FIXED=$(( SEL_FIXED + 1 ))
    for h in "${hits[@]}"; do
      [[ "$h" == "$target" ]] && continue
      emit "$dtag" "delete from $(part_of "$h"): $h"
      if [[ "$DRY" != "--dry" ]]; then
        backup_file "$h"
        awk -v k="$key" '!(NF>=1 && $1==k)' "$h" > "$h.new"
        mv "$h.new" "$h"
      fi
    done
  done < "$cfl"

  rm -f "$tmp" "$cfl"
}

task_selinux() {   # $1 = "--dry" for preview, empty to apply
  set -euo pipefail
  DRY="${1:-}"
  SEL_CONFLICTS=0; SEL_FIXED=0; SEL_SKIPPED=0

  WORK="$TOP"
  if [[ -z "$WORK" || ! -d "$WORK" ]]; then
    emit ERR "work_dir not found: $TOP"
    exit 1
  fi

  WORK="$(readlink -f "$WORK")"
  BACKUP="$WORK/.selinux_backup_$(date +%Y%m%d_%H%M%S)"
  mkdir -p "$BACKUP"

  SERVICE_FILES=()
  for n in product_service_contexts plat_service_contexts \
           system_ext_service_contexts vendor_service_contexts \
           vndservice_contexts; do
    p="$(find_one "$n")" && [[ -n "$p" ]] && SERVICE_FILES+=("$p")
  done

  PROP_FILES=()
  for n in product_property_contexts plat_property_contexts \
           system_ext_property_contexts vendor_property_contexts; do
    p="$(find_one "$n")" && [[ -n "$p" ]] && PROP_FILES+=("$p")
  done

  emit INFO "work_dir: $WORK"
  emit INFO "service context files: ${#SERVICE_FILES[@]}"
  for f in "${SERVICE_FILES[@]}"; do note "$f"; done
  emit INFO "property context files: ${#PROP_FILES[@]}"
  for f in "${PROP_FILES[@]}"; do note "$f"; done

  fix_family service  "${SERVICE_FILES[@]}"
  fix_family property "${PROP_FILES[@]}"

  emit INFO "backups: $BACKUP"
  local verb="fixed"
  if [[ "$DRY" == "--dry" ]]; then
    emit WARN "DRY RUN - nothing was written."
    verb="would fix"
  else
    emit OK "done."
  fi

  report_box "SELINUX REPORT" \
    "Conflicts" "$SEL_CONFLICTS" "$C_WHT" \
    "Whitelist" "$SEL_SKIPPED" "$C_GREY" \
    "${verb^}" "$SEL_FIXED" "$C_GRN"
  set_summary "conflicts $SEL_CONFLICTS / $verb $SEL_FIXED / whitelisted $SEL_SKIPPED"
}

# ============================== TASK TABLE ===================================
task_meta() {   # id -> T_ID T_NAME T_FN T_ARG T_DESC
  printf -v T_ID '%02d' "$1"
  T_ARG=""
  case "$1" in
    1) T_NAME="GRAB";    T_FN=task_grab;    T_DESC="Pull stock camera libs out of the stock firmware" ;;
    2) T_NAME="PURGE";   T_FN=task_remove;  T_DESC="Remove port camera libs from work_dir" ;;
    3) T_NAME="INJECT";  T_FN=task_copy;    T_DESC="Copy stock camera libs into work_dir" ;;
    4) T_NAME="SELINUX"; T_FN=task_selinux; T_DESC="Fix duplicate SELinux contexts (backup + apply)" ;;
    5) T_NAME="DRY-RUN"; T_FN=task_selinux; T_DESC="SELinux scan only - preview, writes nothing"
       T_ARG="--dry" ;;
  esac
}

# ============================== RUN ENGINE ===================================
# Each module runs in its own subshell with `set -e` (same as the original
# standalone scripts): an `exit 1` inside a module ends that module only.
run_queue() {   # ids...
  local ids=("$@") n=$# i=0 id rc=0 sum st ts final=OK
  : > "$FEED"
  hud_put state RUN
  hud_put task  "queue of $n module(s)"
  hud_put now   "spinning up"
  hud_put prog  "0 0"
  hud_begin

  for id in "${ids[@]}"; do
    i=$(( i + 1 ))
    task_meta "$id"
    hud_put task "[$i/$n] $T_ID $T_NAME"
    hud_put prog "0 0"
    hud_put now  "booting module"
    : > "$RT/summary"; : > "$RT/lasterr"
    module_header "$T_ID" "$T_NAME" "$T_DESC"
    log_only RUN "module $T_ID $T_NAME started"

    ( set -e; "$T_FN" "$T_ARG" )
    rc=$?

    sum=""
    if (( rc == 0 )); then
      st=OK
      IFS= read -r sum < "$RT/summary" || true
      [[ -n "$sum" ]] || sum="completed"
    else
      st=FAIL; final=FAIL
      IFS= read -r sum < "$RT/lasterr" || true
      [[ -n "$sum" ]] || sum="exit code $rc"
    fi
    printf -v ts '%(%H:%M:%S)T' -1
    printf '%s|%s|%s|%s\n' "$ts" "$st" "$T_ID $T_NAME" "$sum" >> "$HIST"
    log_only "$st" "$T_ID $T_NAME :: $sum"
    if (( rc != 0 )); then
      if (( i < n )); then emit ERR "queue aborted - remaining modules skipped"; fi
      break
    fi
  done

  hud_put state "$final"
  hud_put now "queue finished"
  hud_end
  hold
}

# ============================ MENU / BOOT / MAIN =============================
hold()  { printf '\n  %s[ ENTER ]%s return to main console ' "$C_AMBER" "$C_RST"; read -r _ || true; }
flash() { printf '  %s!! %s%s\n' "$C_RED" "$1" "$C_RST"; sleep 1.2; }

# ---- device picker ----------------------------------------------------------
draw_device_pick() {
  local FRAME_C="$C_BORD" d tgt stk badge
  (( USE_COLOR )) && printf '\e[2J\e[H'
  box_top "SELECT DEVICE"
  for d in "${DEV_IDS[@]}"; do
    tgt="$(dev_target "$d")"
    stk="$(dev_stock "$d")"
    if   [ -d "$PROJECT/out/target/$tgt/work_dir" ] && [ -d "$PROJECT/out/fw/$stk" ]; then
      badge="${C_GRN}READY${C_RST}"
    elif [ -d "$PROJECT/out/target/$tgt/work_dir" ] || [ -d "$PROJECT/out/fw/$stk" ]; then
      badge="${C_AMBER}PARTIAL${C_RST}"
    else
      badge="${C_RED}MISSING${C_RST}"
    fi
    menu_row "$d" "$(dev_model "$d")" "$tgt   fw:$stk   [$badge]"
  done
  menu_row B BACK "Keep current device: $DEV_LABEL"
  box_bot
}

choose_device() {
  local pick old="$DEVICE"
  while true; do
    draw_device_pick
    printf '  %s> SELECT DEVICE%s %s[ r0q | g0q | B ]%s %s>%s ' \
      "$C_PINK" "$C_RST" "$C_GREY" "$C_RST" "$C_AMBER" "$C_RST"
    read -r pick || { apply_device "$old"; return 1; }
    pick="${pick,,}"
    case "$pick" in
      r0q|g0q)   apply_device "$pick"; return 0 ;;
      b|back|"") apply_device "$old";  return 1 ;;
      *)         flash "unknown device: $pick" ;;
    esac
  done
}

view_log() {
  if [[ ! -s "$SESSION" ]]; then flash "session log is empty - run a module first"; return; fi
  if command -v less >/dev/null 2>&1; then less -R "$SESSION"; else cat "$SESSION"; hold; fi
}

boot_line() {  # label status [note]
  local dots
  tag_fmt "$2"
  repv dots '.' $(( 40 - ${#1} ))
  printf '  %s>%s %s %s%s%s [%s%s%s]' "$C_PINK" "$C_RST" "$1" "$C_GREY" "$dots" "$C_RST" "$TAG_C" "$TAG_T" "$C_RST"
  if [[ -n "${3:-}" ]]; then printf ' %s%s%s' "$C_GREY" "$3" "$C_RST"; fi
  printf '\n'
  sleep 0.06
}

boot_sequence() {
  (( FX )) || return 0
  local t miss=""
  printf '\e[2J\e[H'
  draw_banner slow
  echo
  boot_line "bash runtime ${BASH_VERSION%%[^0-9.]*}" OK
  for t in find awk sed tar sort cp mktemp readlink; do command -v "$t" >/dev/null 2>&1 || miss+="$t "; done
  if [[ -z "$miss" ]]; then boot_line "core utilities" OK; else boot_line "core utilities" FAIL "missing: $miss"; fi
  miss=""
  for t in lz4 simg2img lpunpack file; do command -v "$t" >/dev/null 2>&1 || miss+="$t "; done
  if [[ -z "$miss" ]]; then boot_line "packed-firmware toolchain" OK; else boot_line "packed-firmware toolchain" WARN "optional, missing: $miss"; fi
  if [ -d "$TOP" ];       then boot_line "work_dir online" OK;       else boot_line "work_dir online" WARN "not found"; fi
  if [ -d "$STOCK_DIR" ]; then boot_line "stock firmware online" OK; else boot_line "stock firmware online" WARN "not found"; fi
  if (( $(tput cols 2>/dev/null || echo 0) >= BOX_W + 2 )); then boot_line "display 80 cols" OK; else boot_line "display 80 cols" WARN "terminal is narrow"; fi
  sleep 0.5
}

main_menu() {
  local choice tok bad
  local toks=() queue=()
  while true; do
    draw_menu
    printf '  %s> SELECT MODULE%s %s[ 1-5 | A | D | L | Q ]%s %s>%s ' "$C_PINK" "$C_RST" "$C_GREY" "$C_RST" "$C_AMBER" "$C_RST"
    read -r choice || { echo; return; }
    choice="${choice//,/ }"
    choice="${choice^^}"
    read -ra toks <<< "$choice"
    (( ${#toks[@]} )) || continue

    queue=(); bad=""
    for tok in "${toks[@]}"; do
      case "$tok" in
        Q|QUIT|EXIT) return ;;
        L|LOG)       view_log; continue 2 ;;
        D|DEV|DEVICE) choose_device; continue 2 ;;
        A|ALL)       queue+=(1 2 3 4) ;;
        1|2|3|4|5)   queue+=("$tok") ;;
        *)           bad="$tok" ;;
      esac
    done
    if [[ -n "$bad" ]]; then flash "unknown module: $bad"; continue; fi
    (( ${#queue[@]} )) || continue
    run_queue "${queue[@]}"
  done
}

cleanup() {
  [[ -t 1 ]] && printf '\e[r'
  [[ -n "${RT:-}" ]] && rm -rf "$RT"
  return 0
}

main() {
  init_colors
  RT="$(mktemp -d)"
  FEED="$RT/run.log"; SESSION="$RT/session.log"; HIST="$RT/history.log"
  : > "$FEED"; : > "$SESSION"; : > "$HIST"
  : > "$RT/summary"; : > "$RT/lasterr"
  hud_put state STANDBY; hud_put task ""; hud_put now ""; hud_put prog "0 0"
  trap cleanup EXIT
  trap 'echo; exit 130' INT TERM

  if [[ -t 1 && -z "${BERKYT_FAST:-}" ]]; then FX=1; fi

  # ---- device selection:  CLI  >  env  >  interactive prompt ----
  local cli_dev="" a
  while (( $# )); do
    a="$1"
    case "$a" in
      -d|--device)     shift; cli_dev="${1:-}"; shift ;;
      -d=*|--device=*) cli_dev="${a#*=}";      shift ;;
      r0q|g0q)         cli_dev="$a";           shift ;;
      -h|--help)
        printf 'usage: %s [-d r0q|g0q]\n' "${0##*/}"
        printf 'env:   BERKYT_DEVICE=r0q|g0q   BERKYT_FAST=1   NO_COLOR=1\n'
        exit 0 ;;
      *) shift ;;
    esac
  done
  if   [[ -n "$cli_dev" ]];               then apply_device "$cli_dev"
  elif [[ -z "${BERKYT_DEVICE:-}"     ]]; then choose_device || true
  fi

  boot_sequence
  main_menu
  printf '\n  %s┌┬┐%s %sSESSION TERMINATED%s %s// stay frosty, operator%s %s└┬┘%s\n\n' \
    "$C_PINK" "$C_RST" "$C_BOLD$C_CYAN" "$C_RST" "$C_GREY" "$C_RST" "$C_PINK" "$C_RST"
}

# run only when executed (lets the file be sourced for testing)
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi