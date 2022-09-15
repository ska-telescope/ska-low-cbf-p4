//

#ifndef _PARDE_P4_
#define _PARDE_P4_

#include "headers.p4"
#include "types.p4"
#include "util.p4"

// ---------------------------------------------------------------------------
// Ingress Parser
// ---------------------------------------------------------------------------
parser IngressParser(
    packet_in                        pkt,
    out header_t                     hdr,
    out metadata_t           ig_md,
    out ingress_intrinsic_metadata_t ig_intr_md) {

    TofinoIngressParser() tofino_parser;

    state start {
        tofino_parser.apply(pkt, ig_intr_md);
        ig_md.timestamp = ig_intr_md.ingress_mac_tstamp;
        ig_md.is_my_ip = false;

        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_ARP  : parse_arp;
            ETHERTYPE_PTP : parse_ptp;
            // ETHERTYPE_IPV6 : accept;
            default : parse_unknown;
        }
    }

    state parse_ptp {
        ig_md.packet_type_ingress  = 7;
        transition accept;
    }

    state parse_unknown{
        ig_md.packet_type_ingress  = 0;
        transition accept;
    }
    state parse_arp {
        pkt.extract(hdr.arp);
        ig_md.dst_ip = hdr.arp.tpa;
        ig_md.packet_type_ingress = 1;
        transition accept;
    }

    state parse_ipv4 {
         pkt.extract(hdr.ipv4);
         transition select(hdr.ipv4.protocol) {
             IP_PROTOCOLS_UDP : parse_udp;
             IP_PROTOCOLS_ICMP : parse_icmp;
             default : parse_ip;
         }
    }
    state parse_ip{
        ig_md.packet_type_ingress  = 2;
        transition accept;
    }

    state parse_icmp {
        pkt.extract(hdr.icmp);
        ig_md.packet_type_ingress = 3;
        transition accept;
    }

    state parse_udp {
         pkt.extract(hdr.udp);
         transition select(hdr.udp.dst_port) {
             UDP_SPEAD : parse_spead;
             UDP_PSR : parse_psr;
             default : parse_other;
         }

    }
    state parse_other{
        ig_md.packet_type_ingress  = 4;
        transition accept;
    }

    state parse_spead {
        pkt.extract(hdr.spead);
        ig_md.packet_type_ingress  = 5;
        ig_md.losses = 0;
        ig_md.last_spead_packet = hdr.spead.heap_counter;
        transition parse_channel_info;
    }

    //state parse_codif {
    //    pkt.extract(hdr.codif);
    //    ig_md.packet_type_ingress  = 5;
    //    ig_md.losses = 0;
        //ig_md.last_spead_packet = hdr.spead.heap_counter;
    //    transition parse_channel_info;
    //}

    state parse_channel_info {
        pkt.extract(hdr.channel);
        transition parse_station_info;
    }

    state parse_station_info {
        pkt.extract(hdr.station);
        transition accept;
    }

    state parse_psr {
        ig_md.packet_type_ingress  = 6;
        pkt.extract(hdr.psr);
        transition accept;
    }

}

// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------
control IngressDeparser(
    packet_out                                   pkt,
    inout header_t                               hdr,
    in metadata_t                        ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    Mirror() mirror;


    //pkt.emit(hdr.bridged_md);
    apply{
        if (ig_dprsr_md.mirror_type == MIRROR_TYPE_I2E) {
            mirror.emit<mirror_h>(ig_md.ing_mir_ses, {ig_md.pkt_type, ig_md.current_tstamp_telemetry, ig_md.previous_tstamp_telemetry, ig_md.total_bytes_telemetry});
        }
        pkt.emit(hdr);

    }

}

// ---------------------------------------------------------------------------
// Ingress Parser
// ---------------------------------------------------------------------------
parser EgressParser(
    packet_in                       pkt,
    out header_t                    hdr,
    out metadata_t           eg_md,
    out egress_intrinsic_metadata_t eg_intr_md) {

    TofinoEgressParser() tofino_parser;

    state start {
        tofino_parser.apply(pkt, eg_intr_md);
        //ig_md.timestamp = ig_intr_md.ingress_mac_tstamp;
        //ig_md.is_my_ip = false;

        transition parse_metadata;
    }

    state parse_metadata {
        mirror_h mirror_md = pkt.lookahead<mirror_h>();

        transition select(mirror_md.pkt_type) {
            PKT_TYPE_MIRROR : parse_mirror_md;
            PKT_TYPE_NORMAL : parse_bridged_md;
            default : accept;
        }
    }

    state parse_bridged_md {
        pkt.extract(hdr.bridged_md);
        transition parse_ethernet;
    }

    state parse_mirror_md {
        mirror_h mirror_md;
        pkt.extract(mirror_md);
        eg_md.pkt_type = mirror_md.pkt_type;
        eg_md.previous_tstamp_telemetry = mirror_md.previous_tstamp_telemetry;
        eg_md.current_tstamp_telemetry = mirror_md.current_tstamp_telemetry;
        eg_md.total_bytes_telemetry = mirror_md.total_bytes_telemetry;
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_ARP  : parse_arp;
            ETHERTYPE_PTP : parse_ptp;
            // ETHERTYPE_IPV6 : accept;
            default : parse_unknown;
        }
    }

    state parse_ptp {
        eg_md.packet_type_ingress  = 7;
        transition accept;
    }

    state parse_unknown{
        eg_md.packet_type_ingress  = 0;
        transition accept;
    }
    state parse_arp {
        pkt.extract(hdr.arp);
        //ig_md.dst_ip = hdr.arp.tpa;
        eg_md.packet_type_ingress = 1;
        transition accept;
    }

    state parse_ipv4 {
         pkt.extract(hdr.ipv4);
         transition select(hdr.ipv4.protocol) {
             IP_PROTOCOLS_UDP : parse_udp;
             IP_PROTOCOLS_ICMP : parse_icmp;
             default : parse_ip;
         }
    }
    state parse_ip{
        eg_md.packet_type_ingress  = 2;
        transition accept;
    }

    state parse_icmp {
        pkt.extract(hdr.icmp);
        eg_md.packet_type_ingress = 3;
        transition accept;
    }

    state parse_udp {
         pkt.extract(hdr.udp);
         transition select(hdr.udp.dst_port) {
             UDP_SPEAD : parse_spead;
             UDP_PSR : parse_psr;
             default : parse_other;
         }
    //    transition parse_psr;
    }
    state parse_other{
        eg_md.packet_type_ingress  = 4;
        transition accept;
    }

    state parse_spead {
        pkt.extract(hdr.spead);
        eg_md.packet_type_ingress  = 5;
        eg_md.losses = 0;
        eg_md.last_spead_packet = hdr.spead.heap_counter;
        transition parse_channel_info;
    }

    state parse_channel_info {
        pkt.extract(hdr.channel);
        transition parse_station_info;
    }

    state parse_station_info {
        pkt.extract(hdr.station);
        transition accept;
    }

    state parse_psr {
        eg_md.packet_type_ingress  = 6;
        pkt.extract(hdr.psr);
        transition accept;
    }

}

// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------
control EgressDeparser(
    packet_out                                  pkt,
    inout header_t                              hdr,
    in metadata_t                        eg_md,
    in egress_intrinsic_metadata_for_deparser_t eg_dprsr_md) {

    //Mirror() mirror;
    Checksum() ipv4_csum;

    //pkt.emit(hdr.bridged_md);
    apply{
        if(hdr.ipv4.isValid()){
            hdr.ipv4.hdr_checksum = ipv4_csum.update(
                {
                    hdr.ipv4.version,
                    hdr.ipv4.ihl,
                    hdr.ipv4.diffserv,
                    hdr.ipv4.total_len,
                    hdr.ipv4.identification,
                    hdr.ipv4.flags,
                    hdr.ipv4.frag_offset,
                    hdr.ipv4.ttl,
                    hdr.ipv4.protocol,
                    hdr.ipv4.src_addr,
                    hdr.ipv4.dst_addr
                }
            );
        }
        pkt.emit(hdr);

    }

}


#endif
