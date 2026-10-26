# Troubleshooting

## 1. ptest cannot connect

Run these commands inside the affected WSL distribution:

    WIN_HOST="$(ip route show default | awk 'NR == 1 {print $3; exit}')"
    printf 'Windows host: %s\n' "$WIN_HOST"
    nc -vz "$WIN_HOST" 7890

If netcat is unavailable, try an explicit proxy request:

    curl -v --connect-timeout 10 --proxy "http://$WIN_HOST:7890" -I https://www.google.com

- **Connection refused:** verify the proxy listener and port.
- **Timeout:** inspect the Windows firewall, WSL network mode, and listener address.
- **Proxy connection succeeds but the target fails:** inspect Mihomo rules, proxy-node health, and DNS behavior.

Do not expose a proxy port to untrusted interfaces just to make a test pass. Restrict firewall access to the WSL virtual network where practical.

## 2. Windows proxy listens only on 127.0.0.1

In WSL2 NAT networking, 127.0.0.1 usually refers to the Linux distribution itself, not the Windows host. Use a Windows address reachable from WSL and ensure the proxy listener accepts connections on that interface. Mirrored networking has different localhost behavior; validate your actual setup.

## 3. The gateway address changes

The helper discovers the default route every time pon or ptest is called. If discovery does not return the correct reachable address, set an override before enabling the proxy:

    export WSL_PROXY_HOST="YOUR_REACHABLE_WINDOWS_HOST"
    export WSL_PROXY_PORT="7890"

Replace the placeholder with the address that is actually reachable from your distribution. Do not blindly copy example gateway addresses.

## 4. curl works but apt or another tool does not

Applications differ in their support for proxy environment variables. sudo may clear environment variables, and APT may need a dedicated proxy configuration. Configure the affected tool explicitly instead of assuming that the whole operating system is transparently tunneled.

## 5. Git over SSH ignores the variables

A remote such as git@github.com:owner/repo.git uses SSH. HTTP proxy variables do not automatically proxy SSH. Use an HTTPS remote or configure SSH proxying separately.

## 6. Some UDP, DNS, or raw-socket traffic bypasses the proxy

This project configures application-level proxy environment variables. It does not install TUN, rewrite system routes, or transparently capture arbitrary traffic. Use a Linux-side TUN design if broader network-layer interception is required, and test DNS/UDP behavior separately.

## 7. Shell configuration conflicts

The installer adds one marked loader block to either ~/.bashrc or ~/.zshrc. Do not source all of .bashrc from .zshrc (or vice versa). Backups are created before changing a shell startup file. If something behaves unexpectedly, check for duplicate loader blocks or older manual proxy definitions.
