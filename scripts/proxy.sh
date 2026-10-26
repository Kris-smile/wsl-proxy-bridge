# shellcheck shell=sh
# WSL Proxy Bridge - source this file from Bash or Zsh.
# Proxy is not enabled automatically. Run pon when you want to enable it.

_wsl_proxy_detect_host() {
    if [ -n "${WSL_PROXY_HOST:-}" ]; then
        printf '%s\n' "$WSL_PROXY_HOST"
        return 0
    fi

    if command -v ip >/dev/null 2>&1; then
        ip route show default 2>/dev/null | awk 'NR == 1 { print $3; exit }'
        return 0
    fi

    return 1
}

_wsl_proxy_port() {
    printf '%s\n' "${WSL_PROXY_PORT:-7890}"
}

proxy_on() {
    local host port proxy_url
    host="$(_wsl_proxy_detect_host)"
    port="$(_wsl_proxy_port)"

    if [ -z "$host" ]; then
        printf '%s\n' '[wsl-proxy] Could not detect the Windows host. Set WSL_PROXY_HOST manually.' >&2
        return 1
    fi

    proxy_url="http://${host}:${port}"
    export http_proxy="$proxy_url"
    export https_proxy="$proxy_url"
    export all_proxy="$proxy_url"
    export HTTP_PROXY="$proxy_url"
    export HTTPS_PROXY="$proxy_url"
    export ALL_PROXY="$proxy_url"
    export no_proxy='localhost,127.0.0.1,::1'
    export NO_PROXY="$no_proxy"

    printf '[wsl-proxy] Enabled: %s\n' "$proxy_url"
}

proxy_off() {
    unset http_proxy https_proxy all_proxy
    unset HTTP_PROXY HTTPS_PROXY ALL_PROXY
    unset no_proxy NO_PROXY
    printf '%s\n' '[wsl-proxy] Disabled in the current shell.'
}

proxy_status() {
    local host port active
    host="$(_wsl_proxy_detect_host)"
    port="$(_wsl_proxy_port)"
    active=0

    if [ -n "${http_proxy:-}${https_proxy:-}${all_proxy:-}${HTTP_PROXY:-}${HTTPS_PROXY:-}${ALL_PROXY:-}" ]; then
        active=1
    fi

    printf 'Windows host: %s\n' "${host:-not detected}"
    printf 'Proxy port:   %s\n' "$port"
    if [ "$active" -eq 1 ]; then
        printf '%s\n' 'Environment:  enabled (proxy variable values hidden)'
    else
        printf '%s\n' 'Environment:  disabled'
    fi
}

proxy_test() {
    local host port
    if ! command -v curl >/dev/null 2>&1; then
        printf '%s\n' '[wsl-proxy] curl is required for ptest.' >&2
        return 127
    fi

    host="$(_wsl_proxy_detect_host)"
    port="$(_wsl_proxy_port)"
    if [ -z "$host" ]; then
        printf '%s\n' '[wsl-proxy] Could not detect the Windows host. Set WSL_PROXY_HOST manually.' >&2
        return 1
    fi

    printf '[wsl-proxy] Testing https://www.google.com through %s:%s ...\n' "$host" "$port"
    curl -I -v --connect-timeout 10 --max-time 20 \
        --proxy "http://${host}:${port}" \
        https://www.google.com
}

pon() { proxy_on "$@"; }
poff() { proxy_off "$@"; }
pstatus() { proxy_status "$@"; }
ptest() { proxy_test "$@"; }
