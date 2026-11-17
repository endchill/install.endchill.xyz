#!/usr/bin/env bash

# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2026 ENDChill

PS4='${BASH_SOURCE[0]##*/}: $?: $LINENO: '

set -eu


if [ "${CLICOLOR_FORCE:-$_CLICOLOR_FORCE}" = 1 ] || { [ "${CLICOLOR:-$_CLICOLOR}" = 1 ] && [ -t 1 ]; }; then
    RESET="$(printf '\033[0m')"
    BOLD="$(printf '\033[1m')"
    RED="$(printf '\033[31m')"
    # GREEN="$(printf '\033[32m')"
    YELLOW="$(printf '\033[33m')"
    BLUE="$(printf '\033[34m')"
    MAGENTA="$(printf '\033[35m')"
    CYAN="$(printf '\033[36m')"
    # GRAY="$(printf '\033[37m')"
else
    RESET=""
    BOLD=""
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    # MAGENTA=""
    CYAN=""
    # GRAY=""
fi


if [[ "$EUID" -ne 0 ]]; then
    printf '%s\n' "${BOLD}Installer Description:${RESET} kanata setup and config script (systemd system-level)"
    printf '%s\n' "By ${YELLOW}ENDChill${RESET}; Under ${CYAN}MIT License${RESET}; Repository at ${BOLD}https://github.com/endchill/install.endchill.xyz${RESET}"
    printf '%s\n' "Installer needs ${RED}root permissions${RESET}, ${MAGENTA}always${RESET} read script code before running it"
    exec sudo bash -s -- "${CLICOLOR:-}" "${CLICOLOR_FORCE:-}" "$@"
fi


_CLICOLOR_FORCE="${1:-}"
_CLICOLOR="${2:-}"

if [ "${CLICOLOR_FORCE:-$_CLICOLOR_FORCE}" = 1 ] || { [ "${CLICOLOR:-$_CLICOLOR}" = 1 ] && [ -t 1 ]; }; then
    RESET="$(printf '\033[0m')"
    BOLD="$(printf '\033[1m')"
    RED="$(printf '\033[31m')"
    # GREEN="$(printf '\033[32m')"
    YELLOW="$(printf '\033[33m')"
    BLUE="$(printf '\033[34m')"
    # MAGENTA="$(printf '\033[35m')"
    # CYAN="$(printf '\033[36m')"
    # GRAY="$(printf '\033[37m')"
else
    RESET=""
    BOLD=""
    RED=""
    # GREEN=""
    YELLOW=""
    BLUE=""
    # MAGENTA=""
    # CYAN=""
    # GRAY=""
fi


# _print_log {info|warn|error} <log_message>
function _print_log() {
    local file_descriptor log_level_color stream_type message
    log_level="$1"
    message="$2"

    case "$log_level" in
        "info")
            log_level_color="$BLUE"
            file_descriptor=1
        ;;
        "warn")
            log_level_color="$YELLOW"
            file_descriptor=2
        ;;
        "error")
            log_level_color="$RED"
            file_descriptor=2
        ;;
    esac

    printf '[%b%s%b] %s\n' "$log_level_color" "$log_level" "$RESET" "$message" >& "$file_descriptor"
}


# _creeate_systemd_unit <filename>
_creeate_kanata_config() {
    local filename="$1"

    printf \
'(defcfg
  process-unmapped-keys yes
)

(defsrc
  lmet lalt lctl rctl lsft rsft
  j k l ;
  d f
  n m /
  u i
  caps
)

(defalias
  sj (switch
       ((and lmet lalt))         (unmod (lmet lalt) home) break
       ((and lmet (not lalt)))   (unmod (lmet) lft)       break
       ()                        j                        break)
  sk (switch
       ((and lmet (not lalt)))   (unmod (lmet) up)        break
       ()                        k                        break)
  sl (switch
       ((and lmet (not lalt)))   (unmod (lmet) down)      break
       ()                        l                        break)
  sc (switch
       ((and lmet lalt))         (unmod (lmet lalt) end)  break
       ((and lmet (not lalt)))   (unmod (lmet) rght)      break
       ()                        ;                        break)

  sd (switch
       ((and lmet (not lalt) (not (or lsft rsft))))  (unmod (lmet) bspc) break
       ()                                            d                   break)
  sf (switch
       ((and lmet (not lalt) (not (or lsft rsft))))  (unmod (lmet) del)  break
       ()                                            f                   break)

  sn (switch
       ((and lmet (not lalt) (not (or lctl rctl))))  (unmod (lmet) min)  break
       ()                                            n                   break)
  sm (switch
       ((and lmet (not lalt) (not (or lctl rctl))))  (unmod (lmet) eql)  break
       ()                                            m                   break)

  ss (switch
       ((and lmet (not lalt) (not (and (or lctl rctl) (or lsft rsft)))))  (unmod (lmet) bksl) break
       ()                                                                 /                   break)

  sx (switch
       ((and lmet (not lalt)))   (unmod (lmet) ret)  break
       ()                        XX                  break)

  su (switch
       ((and lmet (not lalt) (not (or lctl rctl lsft rsft))))  (unmod (lmet) mfwd) break  ;; mouse:276
       ()                                                      u                   break)
  si (switch
       ((and lmet (not lalt) (not (or lctl rctl lsft rsft))))  (unmod (lmet) mbck) break  ;; mouse:275
       ()                                                      i                   break)
)

(deflayer base
  lmet lalt lctl rctl lsft rsft
  @sj @sk @sl @sc
  @sd @sf
  @sn @sm @ss
  @su @si
  @sx
)
' > "$filename"
}


# _creeate_systemd_unit <filename> <kanata_binary_path> <system_config_dirpath>
_creeate_systemd_unit() {
    local filename="$1" _kanata_binary_path="$2" _config_filepath="$3"

    printf \
'[Unit]
Description=Kanata keyboard remapper
Documentation=https://github.com/jtroo/kanata
After=local-fs.target

[Service]
Type=simple
ExecStart=%s --cfg %s
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
' "$_kanata_binary_path" "$_config_filepath" > "$filename"
}


_main() {
    name="${0##*/}"
    config_dirpath="/etc/kanata"
    systemd_units_dirpath="/etc/systemd/system"
    kanata_binary_path="$(command -v kanata)"

    [[ ! -d "$config_dirpath" ]] && mkdir -p "$config_dirpath"
    _print_log "info" "Created directory at ${BOLD}$config_dirpath${RESET}"

    modprobe uinput
    _print_log "info" "Enabled uinput kernel module"

    _creeate_kanata_config "$config_dirpath/kanata.kbd"
    _print_log "info" "Created kanata config at ${BOLD}$config_dirpath/kanata.kbd${RESET}"

    _creeate_systemd_unit "$systemd_units_dirpath/kanata.service" "$kanata_binary_path" "$config_dirpath/kanata.kbd"
    _print_log "info" "Created kanata systemd service at ${BOLD}$systemd_units_dirpath/kanata.service${RESET}"

    systemctl daemon-reload
    systemctl enable --now kanata.service &>/dev/null
    _print_log "info" "Enabled and started kanata systemd service"

    _print_log "info" "Done"

    return 0
}


_main "$@"
exit "$?"
