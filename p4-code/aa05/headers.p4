//-----------------------------------------------------------------------------
// Protocol Header Definitions
//-----------------------------------------------------------------------------

#ifndef _HEADERS_P4_
#define _HEADERS_P4_

typedef bit<16> ether_type_t;
typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;
typedef bit<16>  loop_count_t;

typedef bit<8>  pkt_type_t;
const pkt_type_t PKT_TYPE_NORMAL = 1;
const pkt_type_t PKT_TYPE_MIRROR = 2;

#if __TARGET_TOFINO__ == 1
typedef bit<3> mirror_type_t;
#else
typedef bit<4> mirror_type_t;
#endif
const mirror_type_t MIRROR_TYPE_I2E = 1;
const mirror_type_t MIRROR_TYPE_E2E = 2;

struct metadata_t {
    bit<32>     ifid;  // Logical Interface ID
    bit<16>     brid;  // Bridging Domain ID
    bit<16>     vrf;   // VRF ID
    bit<1>      l3;    // Set if routed
    bit<48>     timestamp;
    ipv4_addr_t dst_ip;
    ipv4_addr_t src_ip;
    mac_addr_t  dst_mac_addr; //
    bool        is_my_ip;
    mac_addr_t  src_eth_addr;
    bool        pingable;
    bit<16>     l4_src_port;
    bit<16>     l4_dst_port;
    // type 0-unknown, 1-ARP, 2-ICMP, 3-IP(non UDP), 4-UDP(other), 5-SPEAD, 6-PSR
    bit<4>      packet_type_ingress;
    bit<32>     last_spead_packet;
    bit<32>     losses;
    bit<32>     total_bytes_telemetry;
    bit<32>     elapsed_time;
    bit<32>     current_tstamp_telemetry;
    bit<32>     previous_tstamp_telemetry;
    bit<16>     frequency_no;
    bit<16>     beam_no;
    bit<8>      sub_array;
    MirrorId_t  ing_mir_ses;
    pkt_type_t  pkt_type;



}

header telemetry_spead_h{
    bit<16> frequency_no;
    bit<16> beam_no;
    bit<8> sub_array;
    bit<32>     total_bytes_telemetry;
    bit<32>     current_tstamp_telemetry;
    bit<32>     previous_tstamp_telemetry;
}

header arp_resolution_h{
    bit<7> reserved;
    bit<9> dst_port;
    mac_addr_t dst_mac_addr;
    ipv4_addr_t dst_ip_addr;
}

@flexible
header mirror_bridged_metadata_h {
    pkt_type_t pkt_type;
    bit<1> do_egr_mirroring;  //  Enable egress mirroring
    MirrorId_t egr_mir_ses;   // Egress mirror session ID
    bit<32> timestamp;
    bit<32> byte_total;
    bit<4>  packet_type_ingress;

}

header mirror_h {
  pkt_type_t  pkt_type;
  bit<32>     current_tstamp_telemetry;
  bit<32>     previous_tstamp_telemetry;
  bit<32>     total_bytes_telemetry;
  bit<16>     frequency_no;
  bit<16>     beam_no;
  bit<8>      sub_array;

}

header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    ether_type_t ether_type;
}

header arp_h {
    bit<16>      htype;
    ether_type_t ptype;
    bit<8>       hlen;
    bit<8>       plen;
    bit<16>      oper;
    mac_addr_t sha;
    ipv4_addr_t     spa;
    mac_addr_t tha;
    ipv4_addr_t     tpa;
}

header vlan_tag_h {
    bit<3> pcp;
    bit<1> cfi;
    vlan_id_t vid;
    bit<16> ether_type;
}

header ipv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> total_len;
    bit<16> identification;
    bit<3> flags;
    bit<13> frag_offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

header ipv4_option_h {
    bit<8> type;
    bit<8> length;
    bit<16> value;
}

header ipv6_h {
    bit<4> version;
    bit<8> traffic_class;
    bit<20> flow_label;
    bit<16> payload_len;
    bit<8> next_hdr;
    bit<8> hop_limit;
    ipv6_addr_t src_addr;
    ipv6_addr_t dst_addr;
}

header tcp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4> data_offset;
    bit<4> res;
    bit<8> flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}

header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> hdr_length;
    bit<16> checksum;
}

header icmp_h {
    bit<8> type;
    bit<8> code;
    bit<16> checksum;
    // ...
}


// CASS Headers
header spead_h {
    bit<64> spead_header;
    //bit<64> heap_counter;
    bit<32> high_heap_counter;
    bit<32> heap_counter;
    bit<64> spead_payload_len;
    bit<64> ref_time;
    bit<64> frame_timestamp;
    bit<64> freq_channel;
}

header channel_info_h {
    bit<32> pad;
    bit<16> beam_no;
    bit<16> frequency_no;
}

header station_info_h {
    bit<24> pad;
    bit<8> sub_array;
    bit<16> station_no;
    bit<16> num_antennas;
}

header psr_h {
    bit<64> sequence_number;
    bit<64> timestamp;
    bit<32> timestamp_from_epoch;
    bit<32> channel_separation;
    bit<64> first_channel_freq;
    bit<32> scale_1;
    bit<32> scale_2;
    bit<32> scale_3;
    bit<32> scale_4;
    bit<32> first_channel_number;
    bit<16> channels_per_packet;
    bit<16> valid_channels_per_packet;
    bit<16> no_time_samples;
    bit<16> beam_number;
    bit<32> magic_word;
    bit<8> pkt_dst;
    bit<8> data_precs;
    bit<8> avg_power;
    bit<8> ts_per_rel_wt;
    bit<8> os_num;
    bit<8> os_denom;
    bit<16> beamformer_version;
    bit<64> scan_id;
    bit<32> offset_1;
    bit<32> offset_2;
    bit<32> offset_3;
    bit<32> offset_4;
}


#endif /* _HEADERS_P4_ */
