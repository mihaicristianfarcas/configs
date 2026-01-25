#!/bin/bash
#
# Raspberry Pi Access Point Setup Script
# This script configures a Raspberry Pi with Raspberry Pi OS as a wireless
# access point using NetworkManager. The Pi will bridge wireless clients
# to the ethernet connection (eth0 -> wlan0).
#
# Requirements:
#   - Raspberry Pi OS with NetworkManager (default on recent versions)
#   - Ethernet connection to router via eth0
#   - Built-in or compatible USB WiFi adapter on wlan0
#
# Usage: sudo ./setup-rpi-ap.sh
#

set -e

# CONFIGURATION - Modify these variables to customize your access point

# Access Point Settings
AP_SSID="RaspberryPi-AP"          # Network name (SSID)
AP_PASSWORD="raspberry123"         # WiFi password (minimum 8 characters)
AP_CHANNEL="6"                     # WiFi channel (1-11 for 2.4GHz)
AP_BAND="bg"                       # Band: "bg" for 2.4GHz, "a" for 5GHz

# IP Configuration for the Access Point
AP_IP="192.168.4.1"               # IP address for the Pi on the AP network
AP_NETMASK="24"                    # Subnet mask in CIDR notation
AP_DHCP_START="192.168.4.10"      # DHCP range start
AP_DHCP_END="192.168.4.100"       # DHCP range end
AP_DNS="8.8.8.8,8.8.4.4"          # DNS servers for clients

# Interface Names
WIFI_INTERFACE="wlan0"            # Wireless interface for AP
ETH_INTERFACE="eth0"              # Ethernet interface connected to router

# NetworkManager connection names
AP_CON_NAME="ap-hotspot"
ETH_CON_NAME="eth-shared"

# HELPER FUNCTIONS

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

check_dependencies() {
    log_info "Checking dependencies..."
    
    # Check if NetworkManager is installed and running
    if ! command -v nmcli &> /dev/null; then
        log_error "NetworkManager (nmcli) is not installed"
        exit 1
    fi
    
    if ! systemctl is-active --quiet NetworkManager; then
        log_warn "NetworkManager is not running. Starting it..."
        systemctl start NetworkManager
        systemctl enable NetworkManager
    fi
    
    # Check if dnsmasq is available (needed for DHCP)
    if ! command -v dnsmasq &> /dev/null; then
        log_info "Installing dnsmasq for DHCP server..."
        apt-get update
        apt-get install -y dnsmasq
        # Disable standalone dnsmasq - NetworkManager will manage it
        systemctl stop dnsmasq 2>/dev/null || true
        systemctl disable dnsmasq 2>/dev/null || true
    fi
    
    # Check if iptables is available
    if ! command -v iptables &> /dev/null; then
        log_info "Installing iptables..."
        apt-get update
        apt-get install -y iptables
    fi
    
    log_info "All dependencies are satisfied"
}

check_interfaces() {
    log_info "Checking network interfaces..."
    
    # Check if wlan0 exists
    if ! ip link show "$WIFI_INTERFACE" &> /dev/null; then
        log_error "Wireless interface $WIFI_INTERFACE not found"
        log_error "Available interfaces:"
        ip link show
        exit 1
    fi
    
    # Check if eth0 exists
    if ! ip link show "$ETH_INTERFACE" &> /dev/null; then
        log_error "Ethernet interface $ETH_INTERFACE not found"
        log_error "Available interfaces:"
        ip link show
        exit 1
    fi
    
    # Check if WiFi interface supports AP mode
    if command -v iw &> /dev/null; then
        if ! iw list 2>/dev/null | grep -q "* AP"; then
            log_warn "WiFi adapter may not support AP mode. Proceeding anyway..."
        else
            log_info "WiFi adapter supports AP mode"
        fi
    fi
    
    log_info "Network interfaces OK"
}

backup_existing_config() {
    log_info "Backing up existing NetworkManager connections..."
    
    BACKUP_DIR="/root/nm-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Backup existing connection profiles
    if [ -d "/etc/NetworkManager/system-connections" ]; then
        cp -r /etc/NetworkManager/system-connections/* "$BACKUP_DIR/" 2>/dev/null || true
    fi
    
    log_info "Backup saved to $BACKUP_DIR"
}

cleanup_existing_connections() {
    log_info "Cleaning up existing connections on $WIFI_INTERFACE..."
    
    # Delete any existing AP connection with our name
    nmcli connection delete "$AP_CON_NAME" 2>/dev/null || true
    
    # Disconnect wlan0 from any existing connection
    nmcli device disconnect "$WIFI_INTERFACE" 2>/dev/null || true
    
    # Delete any existing hotspot connections on wlan0
    for conn in $(nmcli -t -f NAME,TYPE connection show | grep wireless | cut -d: -f1); do
        CONN_DEV=$(nmcli -t -f connection.interface-name connection show "$conn" 2>/dev/null | cut -d: -f2)
        if [ "$CONN_DEV" = "$WIFI_INTERFACE" ]; then
            log_info "Removing existing wireless connection: $conn"
            nmcli connection delete "$conn" 2>/dev/null || true
        fi
    done
    
    log_info "Cleanup complete"
}

configure_ethernet() {
    log_info "Configuring ethernet interface ($ETH_INTERFACE)..."
    
    # Check if there's already a working ethernet connection
    ETH_STATE=$(nmcli -t -f GENERAL.STATE device show "$ETH_INTERFACE" 2>/dev/null | cut -d: -f2)
    
    if [[ "$ETH_STATE" == *"connected"* ]]; then
        log_info "Ethernet is already connected"
    else
        # Create a new ethernet connection with DHCP
        nmcli connection delete "$ETH_CON_NAME" 2>/dev/null || true
        
        nmcli connection add \
            type ethernet \
            con-name "$ETH_CON_NAME" \
            ifname "$ETH_INTERFACE" \
            ipv4.method auto \
            ipv6.method auto \
            connection.autoconnect yes
        
        nmcli connection up "$ETH_CON_NAME"
        log_info "Ethernet connection configured"
    fi
}

create_access_point() {
    log_info "Creating wireless access point..."
    
    # Create the AP connection using nmcli
    # Using 'wifi' for the hotspot that acts as an access point
    nmcli connection add \
        type wifi \
        con-name "$AP_CON_NAME" \
        ifname "$WIFI_INTERFACE" \
        ssid "$AP_SSID" \
        mode ap \
        ipv4.method shared \
        ipv4.addresses "${AP_IP}/${AP_NETMASK}" \
        wifi.band "$AP_BAND" \
        wifi.channel "$AP_CHANNEL" \
        wifi-sec.key-mgmt wpa-psk \
        wifi-sec.psk "$AP_PASSWORD" \
        connection.autoconnect yes \
        connection.autoconnect-priority 100
    
    log_info "Access point connection created"
}

configure_dnsmasq() {
    log_info "Configuring DHCP server (dnsmasq)..."
    
    # NetworkManager's shared mode uses dnsmasq internally
    # We can customize it with a configuration file
    
    mkdir -p /etc/NetworkManager/dnsmasq-shared.d
    
    cat > /etc/NetworkManager/dnsmasq-shared.d/ap-settings.conf << EOF
# Custom DHCP settings for Access Point
# Interface to listen on
interface=$WIFI_INTERFACE

# DHCP range
dhcp-range=${AP_DHCP_START},${AP_DHCP_END},255.255.255.0,24h

# DNS servers to provide to clients
dhcp-option=6,${AP_DNS}

# Gateway
dhcp-option=3,${AP_IP}

# Don't read /etc/resolv.conf
no-resolv

# Upstream DNS servers
server=8.8.8.8
server=8.8.4.4

# Don't read /etc/hosts
no-hosts

# Log queries (comment out for production)
# log-queries
EOF
    
    log_info "DHCP configuration complete"
}

enable_ip_forwarding() {
    log_info "Enabling IP forwarding..."
    
    # Enable immediately
    echo 1 > /proc/sys/net/ipv4/ip_forward
    
    # Make persistent
    if ! grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf; then
        echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    else
        sed -i 's/^#*net.ipv4.ip_forward=.*/net.ipv4.ip_forward=1/' /etc/sysctl.conf
    fi
    
    # Apply sysctl settings
    sysctl -p /etc/sysctl.conf 2>/dev/null || true
    
    log_info "IP forwarding enabled"
}

configure_firewall() {
    log_info "Configuring firewall rules for NAT..."
    
    # Flush existing NAT rules (be careful in production!)
    iptables -t nat -F POSTROUTING 2>/dev/null || true
    
    # Enable masquerading (NAT) for traffic from AP network to ethernet
    iptables -t nat -A POSTROUTING -o "$ETH_INTERFACE" -j MASQUERADE
    
    # Allow forwarding between interfaces
    iptables -A FORWARD -i "$WIFI_INTERFACE" -o "$ETH_INTERFACE" -j ACCEPT
    iptables -A FORWARD -i "$ETH_INTERFACE" -o "$WIFI_INTERFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT
    
    # Save iptables rules to persist across reboots
    if command -v netfilter-persistent &> /dev/null; then
        netfilter-persistent save
    else
        # Install iptables-persistent for rule persistence
        log_info "Installing iptables-persistent..."
        DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent
        netfilter-persistent save
    fi
    
    log_info "Firewall configured"
}

start_access_point() {
    log_info "Starting access point..."
    
    # Bring up the AP connection
    nmcli connection up "$AP_CON_NAME"
    
    # Wait a moment for it to fully initialize
    sleep 3
    
    # Verify it's running
    AP_STATE=$(nmcli -t -f GENERAL.STATE device show "$WIFI_INTERFACE" 2>/dev/null | cut -d: -f2)
    
    if [[ "$AP_STATE" == *"connected"* ]]; then
        log_info "Access point is now active!"
    else
        log_error "Failed to start access point"
        log_error "Current state: $AP_STATE"
        nmcli device show "$WIFI_INTERFACE"
        exit 1
    fi
}

create_management_script() {
    log_info "Creating management script..."
    
    cat > /usr/local/bin/ap-control << 'SCRIPT'
#!/bin/bash
# Access Point Control Script

AP_CON_NAME="ap-hotspot"
WIFI_INTERFACE="wlan0"

case "$1" in
    start)
        echo "Starting access point..."
        nmcli connection up "$AP_CON_NAME"
        ;;
    stop)
        echo "Stopping access point..."
        nmcli connection down "$AP_CON_NAME"
        ;;
    restart)
        echo "Restarting access point..."
        nmcli connection down "$AP_CON_NAME" 2>/dev/null
        sleep 2
        nmcli connection up "$AP_CON_NAME"
        ;;
    status)
        echo "Access Point Status:"
        echo ""
        nmcli device show "$WIFI_INTERFACE"
        echo ""
        echo "Connected Clients:"
        echo ""
        iw dev "$WIFI_INTERFACE" station dump 2>/dev/null || echo "No clients or unable to query"
        echo ""
        echo "DHCP Leases:"
        echo ""
        cat /var/lib/NetworkManager/dnsmasq-*.leases 2>/dev/null || echo "No leases found"
        ;;
    clients)
        echo "Connected WiFi Clients:"
        iw dev "$WIFI_INTERFACE" station dump 2>/dev/null | grep -E "Station|signal|rx bytes|tx bytes" || echo "No clients connected"
        ;;
    *)
        echo "Usage: ap-control {start|stop|restart|status|clients}"
        exit 1
        ;;
esac
SCRIPT
    
    chmod +x /usr/local/bin/ap-control
    log_info "Management script created at /usr/local/bin/ap-control"
}

print_summary() {
    echo ""
    echo -e "${GREEN}Access Point Setup Complete!${NC}"
    echo ""
    echo "Network Details:"
    echo "  SSID:        $AP_SSID"
    echo "  Password:    $AP_PASSWORD"
    echo "  AP IP:       $AP_IP"
    echo "  DHCP Range:  $AP_DHCP_START - $AP_DHCP_END"
    echo "  WiFi Band:   $AP_BAND (Channel $AP_CHANNEL)"
    echo ""
    echo "Management Commands:"
    echo "  ap-control start    - Start the access point"
    echo "  ap-control stop     - Stop the access point"
    echo "  ap-control restart  - Restart the access point"
    echo "  ap-control status   - Show AP status and info"
    echo "  ap-control clients  - List connected clients"
    echo ""
    echo "NetworkManager Commands:"
    echo "  nmcli device wifi list          - List nearby networks"
    echo "  nmcli connection show           - Show all connections"
    echo "  nmcli device show wlan0         - Show wlan0 details"
    echo ""
    echo "Troubleshooting:"
    echo "  journalctl -u NetworkManager -f - View NM logs"
    echo "  systemctl restart NetworkManager - Restart NM"
    echo ""
}

# MAIN EXECUTION

main() {
    echo ""
    echo "  Raspberry Pi Access Point Setup Script"
    echo ""
    
    check_root
    check_dependencies
    check_interfaces
    backup_existing_config
    cleanup_existing_connections
    configure_ethernet
    enable_ip_forwarding
    configure_dnsmasq
    configure_firewall
    create_access_point
    start_access_point
    create_management_script
    print_summary
}

# Run main function
main "$@"
