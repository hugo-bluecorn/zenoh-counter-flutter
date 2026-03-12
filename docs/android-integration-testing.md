# Android Integration Testing Guide

Testing the Flutter subscriber on an Android device connected to the
Kubuntu host running the C++ publisher + zenohd router.

## Problem

The lab WiFi (FlandersMake) puts devices on different subnets, so the
Android phone cannot reach the host directly. Solution: create a WiFi
hotspot on the host using the idle WiFi adapter, giving both devices a
shared `10.42.0.0/24` network.

## Hardware (verified 2026-03-12)

| Component | Device | Notes |
|-----------|--------|-------|
| Ethernet | `enp0s31f6` | Primary internet, always connected |
| WiFi | `wlp0s20f3` | Intel Raptor Lake CNVi, AP mode confirmed |
| Android | USB or WiFi | Connects to hotspot |

## Network Topology

```
                    Kubuntu Host (10.42.0.1)
                   ┌──────────────────────────┐
 Internet ─── eth0 │  zenohd (:7447)          │ wlp0s20f3 (hotspot)
                   │  counter_pub (-e tcp/…)  │      │
                   └──────────────────────────┘      │ WiFi AP
                                                     │ "zenoh-test"
                                                     │
                                              Android phone
                                              (10.42.0.x)
                                              Flutter app
                                              (-e tcp/10.42.0.1:7447)
```

## Quick Start (One Script)

`scripts/android-test.sh` handles hotspot + zenohd + C++ publisher:

```bash
# Terminal 1: start everything
./scripts/android-test.sh

# Terminal 2: run Flutter app on Android (USB-connected for debug)
fvm flutter devices
fvm flutter run -d <device-id>
```

The script prints the host IP and endpoint to enter in the app. Press
Ctrl+C to stop router + publisher. The hotspot persists until you run:

```bash
./scripts/android-test.sh --stop
```

### Script options

```bash
./scripts/android-test.sh                  # defaults (ssid: zenoh-test)
./scripts/android-test.sh --ssid MyNet     # custom SSID
./scripts/android-test.sh --no-hotspot     # hotspot already up
./scripts/android-test.sh --stop           # tear down hotspot only
```

Environment variables: `ZENOH_COUNTER_CPP`, `ZENOH_DART`, `WIFI_IFACE`,
`HOTSPOT_SSID`, `HOTSPOT_PASS`.

---

## Manual Steps (Reference)

### Step 1: Create the WiFi Hotspot

Uses `nmcli` which is managed by NetworkManager -- no conflict with KDE
network applet.

```bash
# Create and activate hotspot in one command
nmcli device wifi hotspot ifname wlp0s20f3 \
  ssid zenoh-test password "zenoh1234"
```

This automatically:
- Sets the WiFi adapter to AP mode
- Assigns `10.42.0.1/24` to the host
- Starts dnsmasq for DHCP (clients get `10.42.0.x`)
- Enables NAT/IP forwarding through ethernet

#### Verify

```bash
# Should show "Hotspot" connection active on wlp0s20f3
nmcli connection show --active
```

#### Stop / Restart

```bash
# Stop hotspot
nmcli connection down Hotspot

# Restart hotspot
nmcli connection up Hotspot
```

### Step 2: Connect Android to Hotspot

On the Android phone:
1. Settings > Wi-Fi
2. Connect to **zenoh-test** with password **zenoh1234**
3. Verify connectivity: `ping 10.42.0.1` (or open browser)

> Note: Android may warn "no internet" -- ignore it. The local
> network to the host is what matters.

### Step 3: Start zenohd + C++ Publisher (Router Mode)

```bash
# zenohd router
../zenoh_dart/extern/zenoh/target/release/zenohd -l tcp/0.0.0.0:7447 &

# C++ publisher (client mode -> router)
../zenoh-counter-cpp/build/app/counter_pub -e tcp/localhost:7447
```

Router mode is required for Android (no UDP multicast over WiFi AP).

### Step 4: Run Flutter App on Android

```bash
# List connected devices
fvm flutter devices

# Run on Android device (USB-connected for debug)
fvm flutter run -d <device-id>
```

In the app:
1. Connection screen appears
2. Enter endpoint: **tcp/10.42.0.1:7447**
3. Tap Connect
4. Counter screen should show incrementing values

### Step 5: Teardown

```bash
# Stop router + publisher (Ctrl+C)

# Stop the hotspot
nmcli connection down Hotspot
```

## Troubleshooting

### Hotspot not visible on Android

```bash
# Check hotspot is active
nmcli connection show --active | grep Hotspot

# Check WiFi is not blocked
rfkill list
# If blocked: sudo rfkill unblock wifi
```

### Android connects but no DHCP

Firewall may be blocking dnsmasq on the hotspot interface:

```bash
# Check if ufw is active
sudo ufw status

# If active, allow hotspot traffic
sudo ufw allow in on wlp0s20f3
sudo ufw allow out on wlp0s20f3
```

### Can't reach host from Android

```bash
# On host, verify hotspot IP
ip addr show wlp0s20f3
# Should show 10.42.0.1/24

# On Android, verify IP assignment
# Settings > Wi-Fi > zenoh-test > IP address
# Should be 10.42.0.x

# Test from Android (if terminal available)
ping 10.42.0.1
```

### App connects but no counter values

```bash
# Verify zenohd is listening
ss -tlnp | grep 7447

# Verify publisher is connected to router
# (check zenohd logs for peer join)

# Verify the key expression matches (default: demo/counter)
```

### Changing hotspot band

Default is 2.4GHz (best compatibility). For 5GHz:

```bash
nmcli connection down Hotspot
nmcli connection modify Hotspot 802-11-wireless.band a
nmcli connection up Hotspot
```

Use `bg` to switch back to 2.4GHz.
