#ifndef _TYPES_P4_
#define _TYPES_P4_

// ----------------------------------------------------------------------------
// Common protocols/types
//-----------------------------------------------------------------------------
#define ETHERTYPE_IPV4 0x0800
#define ETHERTYPE_ARP  0x0806
#define ETHERTYPE_VLAN 0x8100
#define ETHERTYPE_IPV6 0x86dd
#define ETHERTYPE_PTP 0x88F7

#define IP_PROTOCOLS_ICMP   1
#define IP_PROTOCOLS_IGMP   2
#define IP_PROTOCOLS_IPV4   4
#define IP_PROTOCOLS_TCP    6
#define IP_PROTOCOLS_UDP    17
#define IP_PROTOCOLS_IPV6   41
#define IP_PROTOCOLS_ICMPV6 58

#define UDP_SPEAD 0x1234
#define UDP_PSR 0x2526

#define VLAN_DEPTH 2

// ----------------------------------------------------------------------------
// Common types
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
// Other Metadata Definitions
//-----------------------------------------------------------------------------

// Ingress metadata
struct ingress_metadata_t {
    bit<48> timestamp;
}

// Egress metadata
struct egress_metadata_t {
}

struct header_t {
    mirror_bridged_metadata_h bridged_md;
    ethernet_h ethernet;
    vlan_tag_h[VLAN_DEPTH] vlan_tag;
    ipv4_h ipv4;
    ipv4_option_h ipv4_option;
    ipv6_h ipv6;
    arp_h  arp;
    udp_h udp;
    icmp_h icmp;
    tcp_h tcp;
    telemetry_spead_h telemetry_spead;
    arp_resolution_h arp_resolution;
    spead_h spead;
    channel_info_h channel;
    station_info_h station;
    psr_h psr;
}

struct empty_header_t {}

struct empty_metadata_t {}

#endif /* _P4_TYPES_ */
