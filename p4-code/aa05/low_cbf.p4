// tna_cass_multicast.p4


#include <core.p4>
#include <tna.p4>
#include "const.p4"
#include "parde.p4"


struct pair {
    bit<32>     losses;
    bit<32>     current;
}

struct pair_test {
    bit<32>     uptime;
    bit<32>     downtime;


}
struct pair_test_total {
    bit<32>     packet;
    bit<32>     byte;

}


// ---------------------------------------------------------------------------
// Ingress control block
// ---------------------------------------------------------------------------
control Ingress(
        inout header_t                                  hdr,
        inout metadata_t                                ig_md,
        in ingress_intrinsic_metadata_t                 ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t     ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t       ig_tm_md) {

    Hash<bit<16>>(HashAlgorithm_t.CRC16) crc16;

    @name(".counter_ingress_type")
    Counter<bit<32>, bit<13>>(8192, CounterType_t.PACKETS_AND_BYTES) counter_ingress_type;

    @name(".counter_spead_losses")
    Counter<bit<32>, bit<40>>(8192, CounterType_t.PACKETS_AND_BYTES) counter_spead_losses;
    @name(".direct_counter")
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) direct_counter;
    @name(".counter_spead")
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) direct_counter_spead;
    @name(".counter_spead_corr")
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) direct_counter_spead_corr;
    @name(".counter")
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) direct_counter_2;
    @name(".counter_arp")
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) direct_counter_arp;
    // Register to record losses total and current sequence number in the pair
    @name(".reg_losses")
    Register<pair, bit<40>>(8192) reg_losses;
    // updating the register every packet for a given frequency
    RegisterAction<pair, bit<40>, bit<32>>(reg_losses) reg_losses_action = {
        void apply(inout pair value, out bit<32> read_value){
            bit<32> last_pkt_ts;
            read_value = value.current;
            last_pkt_ts = value.current;
            value.losses = last_pkt_ts;
            value.current = ig_md.last_spead_packet + 1;
        }
    };
    Register<pair_test, bit<16>>(65535) last_seen;
    RegisterAction<pair_test, bit<16>, bit<32>>(last_seen) last_seen_action = {
        void apply(inout pair_test value, out bit<32> read_value){



            read_value = value.downtime;

            if(value.uptime == 99){

                value.uptime = 0;
                value.downtime = ig_md.timestamp[31:0];
            }
            else{

                value.uptime = value.uptime+1;
                value.downtime = value.downtime;
            }
            /* Update the register with the new timestamp */

            ;
        }
    };
    /*Register<pair_test, bit<16>>(65535) last_seen_down;
    RegisterAction<pair_test, bit<16>, bit<32>>(last_seen) last_seen_action = {
        void apply(inout pair_test value, out bit<32> read_value){


            bit<16> tmp;
            tmp = 0;
            bit<32> down;
            bit<32> up;
            down = value.downtime;
            up = value.uptime;
            read_value = down ++ up;

            /* Update the register with the new timestamp */
    /*        value.uptime = tmp++ig_md.timestamp[47:32];
            value.downtime = ig_md.timestamp[31:0];
        }
    };*/
    Register<pair_test_total, bit<16>>(65535) total_spead;
    RegisterAction<pair_test_total, bit<16>, bit<32>>(total_spead) total_spead_action = {
        void apply(inout pair_test_total value, out bit<32> read_value){

            read_value = value.packet;
            bit<16> tmp;
            bit<32> tmp2;
            tmp = 0;
            tmp2 = tmp++hdr.ipv4.total_len;
            if(value.packet == 99){

                value.packet = 0;
                value.byte = value.byte;
            }
            else{

                value.packet = value.packet+1;
                value.byte = value.byte+tmp2;
            }

        }
    };
    Register<pair_test_total, bit<16>>(65535) total_spead_bytes;
    RegisterAction<pair_test_total, bit<16>, bit<32>>(total_spead_bytes) total_spead_action_bytes = {
        void apply(inout pair_test_total value, out bit<32> read_value){
            read_value = value.byte;
            bit<16> tmp;
            bit<32> tmp2;
            tmp = 0;
            tmp2 = tmp++hdr.ipv4.total_len;
            if(value.packet == 99){

                value.packet = 0;
                value.byte = 0;
            }
            else{

                value.packet = value.packet+1;
                value.byte = value.byte+tmp2;
            }

        }
    };




    @name(".drop")
    action drop() {
        ig_dprsr_md.drop_ctl = 0x1; // Drop packet.
    }

    action nop() {
    }

    @name(".set_egr_port")
    action set_egr_port(PortId_t dest_port) {
        ig_tm_md.ucast_egress_port = dest_port;
        direct_counter.count();


    }

    @name(".ing_port_table")
    table ing_port_table {
        key = {
            ig_intr_md.ingress_port : exact @name("ingress_port");
        }
        actions = {
            set_egr_port;
        }
        counters = direct_counter;
        size = 512;
    }

    @name(".set_ifid")
    action set_ifid(bit<32> ifid) {
        ig_md.ifid = ifid;
        // Set the destination port to an invalid value
        ig_tm_md.ucast_egress_port = 9w0x1ff;
    }

    @name(".ing_port")
    table  ing_port {
        key = {
            ig_intr_md.ingress_port : exact @name("ingress_port");

        }

        actions = {
            set_ifid;
        }

        size = 1024;
    }

    @name(".set_ifid_corr")
    action set_ifid_corr(bit<32> ifid) {
        ig_md.ifid = ifid;
        direct_counter_spead_corr.count();
        // Set the destination port to an invalid value
        ig_tm_md.ucast_egress_port = 9w0x1ff;
    }

    @name(".multiplier_spead")
    table  multiplier_spead {
        key = {

            hdr.channel.frequency_no: exact @name("frequency_no");
            hdr.station.sub_array: exact @name("sub_array");
            hdr.channel.beam_no: exact @name("beam_no");
        }

        actions = {
            set_ifid_corr;
            @defaultonly nop;
        }
        size = SPEAD_TABLE_SIZE;
        const default_action = nop;
        counters = direct_counter_spead_corr;
    }

    @name(".set_egr_port_beam")
    action set_egr_port_beam(PortId_t dest_port) {
        direct_counter_2.count();
        ig_tm_md.ucast_egress_port = dest_port;
    }

    @name(".psr_table")
    table psr_table {
        key = {
            hdr.psr.beam_number: exact @name("beam_number");
        }
        actions = {
            set_egr_port_beam;
            @defaultonly nop;
        }
        size = SPEAD_TABLE_SIZE;
        const default_action = nop;
        counters = direct_counter_2;
    }

    @name(".set_src_ifid_md")
    action set_src_ifid_md(ReplicationId_t rid, bit<9> yid, bit<16> brid, bit<13> hash1, bit<13> hash2) {
        ig_tm_md.rid = rid;
        ig_tm_md.level2_exclusion_id = yid;
        ig_md.brid = brid;
        ig_tm_md.level1_mcast_hash = hash1;
        ig_tm_md.level2_mcast_hash = hash2;
    }

    @name(".ing_src_ifid")
    table  ing_src_ifid {
        key = {
            ig_md.ifid : exact;
        }

        actions = {
            set_src_ifid_md;
        }

        size = 1024;
    }

    @name(".flood")
    action flood() {
        ig_tm_md.mcast_grp_a = ig_md.brid;
    }

    @name(".l2_switch")
    action l2_switch(PortId_t port) {
        ig_tm_md.ucast_egress_port = port;
    }

    @name(".route")
    action route(bit<16> vrf) {
        ig_md.l3 = 1;
        ig_md.vrf = vrf;
    }

    @name(".ing_dmac")
    table ing_dmac {
        key = {
            ig_md.brid   : exact;
            //hdr.ethernet.dst_addr : exact;
        }

        actions = {
            l2_switch;
            route;
            flood;
        }

        //const default_action = flood;
        size = 1024;
    }

    @name(".mcast_route")
    action mcast_route(bit<16> xid, MulticastGroupId_t mgid1, MulticastGroupId_t mgid2) {
        ig_tm_md.level1_exclusion_id = xid;
        ig_tm_md.mcast_grp_a = mgid1;
        ig_tm_md.mcast_grp_b = mgid2;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    @name(".ing_ipv4_mcast")
    table ing_ipv4_mcast {
        key = {
            ig_md.vrf   : exact;
            hdr.ipv4.src_addr : ternary;
            hdr.ipv4.dst_addr : ternary;
        }

        actions = {
            mcast_route;
        }

        size = 1024;
    }
    @name(".answer_arp_request")
    action answer_arp_request(mac_addr_t my_eth_addr) {
        direct_counter_arp.count();
        hdr.arp.tha = hdr.arp.sha;
        hdr.arp.tpa = hdr.arp.spa;;
        hdr.arp.sha = my_eth_addr;
        hdr.arp.spa = ig_md.dst_ip;
        hdr.arp.oper = ARP_OPER_REPLY;
        hdr.ethernet.dst_addr = hdr.ethernet.src_addr;
        hdr.ethernet.src_addr = my_eth_addr;
        ig_tm_md.ucast_egress_port = ig_intr_md.ingress_port;

    }
    @name(".arp_table")
    table arp_table {
        key = {
            hdr.arp.tpa: exact @name("target_ip");
        }
        actions = {
            answer_arp_request;
            @defaultonly nop;
        }
        size = 1024;
        counters = direct_counter_arp;
        default_action = nop();
    }

    // Increment counter, then do proper routing
    // then update loss register
    @name(".set_egr_port_freq")
    action set_egr_port_freq(PortId_t dest_port) {
        bit<32> last_pkt_ts;
        direct_counter_spead.count();
        ig_tm_md.ucast_egress_port = dest_port;

    }


    @name(".spead_table")
    table spead_table {
        key = {
            hdr.channel.frequency_no: exact @name("frequency_no");
            hdr.station.sub_array: exact @name("sub_array");
            hdr.channel.beam_no: exact @name("beam_no");
        }
        actions = {
            set_egr_port_freq;
            @defaultonly nop;
        }
        size = SPEAD_TABLE_SIZE;
        const default_action = nop;
        //registers = reg_losses;
        counters = direct_counter_spead;

    }

    @name(".set_egr_port_ptp")
    action set_egr_port_ptp(PortId_t dest_port) {
        ig_tm_md.ucast_egress_port = dest_port;

    }


    @name(".ptp_table")
    table ptp_table {
        key = {
            ig_intr_md.ingress_port : exact @name("ingress_port");
        }
        actions = {
            set_egr_port_ptp;
            @defaultonly nop;
        }
        size = SPEAD_TABLE_SIZE;
        const default_action = nop;
        //registers = reg_losses;


    }



    apply {
        //<bit 13> = <bit4> ++ <bit9>
        counter_ingress_type.count(ig_md.packet_type_ingress++ig_intr_md.ingress_port);
        ing_port_table.apply();//generic table

        ing_port.apply();//setting the scene for multicast



        if (ig_md.packet_type_ingress == 6){
            psr_table.apply();
        }

        if (ig_md.packet_type_ingress == 5){
            multiplier_spead.apply();
            spead_table.apply();
            bit<16> result;
            result = crc16.get({hdr.channel.frequency_no, hdr.station.sub_array, hdr.channel.beam_no});
            bit<32> total;
            bit<16> tmp;
            bit<32> tmp2;
            bit<32> last_time;
            tmp = 0;
            tmp2 = tmp++hdr.ipv4.total_len;
            last_time = last_seen_action.execute(result);

            // + hdr.ipv4.total_len;
            total = total_spead_action.execute(result);
            ig_md.total_bytes_telemetry = total_spead_action_bytes.execute(result)+tmp2;

            if (total == 99){
                //
                ig_md.current_tstamp_telemetry = ig_md.timestamp[31:0];
                ig_md.previous_tstamp_telemetry = last_time;
                ig_md.ing_mir_ses = 27;
                ig_dprsr_md.mirror_type = MIRROR_TYPE_I2E;
                ig_md.pkt_type = PKT_TYPE_MIRROR;
            }
            ig_md.losses = reg_losses_action.execute(hdr.channel.frequency_no++hdr.channel.beam_no++hdr.station.sub_array);
            if (ig_md.last_spead_packet != ig_md.losses ){
                counter_spead_losses.count(hdr.channel.frequency_no++hdr.channel.beam_no++hdr.station.sub_array);
            }

        }

        ing_src_ifid.apply();
        ing_dmac.apply();

        if (ig_md.packet_type_ingress == 7){
            ptp_table.apply();
        }

        if (ig_md.packet_type_ingress == 1){
            arp_table.apply();
        }


        if (ig_md.packet_type_ingress== 0){ //packet unknown but
            ig_dprsr_md.drop_ctl = 0x1;
        }

        if (ig_md.packet_type_ingress == 2){ // IP packet but not processed
            ig_dprsr_md.drop_ctl = 0x1;
        }

    }

}


// ---------------------------------------------------------------------------
// Egress control block
// ---------------------------------------------------------------------------
control Egress(
    inout header_t                                    hdr,
    inout metadata_t                           eg_md,
    in    egress_intrinsic_metadata_t                 eg_intr_md,
    in    egress_intrinsic_metadata_from_parser_t     eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t    eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t eg_oport_md) {

    @name(".counter_egress_type")
    Counter<bit<32>, bit<13>>(8192, CounterType_t.PACKETS_AND_BYTES) counter_egress_type;

    @name(".set_telemetry_header")
    action set_telemetry_header(ipv4_addr_t src_addr, ipv4_addr_t dst_addr, mac_addr_t hw_src_addr, mac_addr_t hw_dst_addr) {
        hdr.ipv4.total_len = 118;
        hdr.ethernet.dst_addr = hw_dst_addr;
        hdr.ethernet.src_addr = hw_src_addr;
        hdr.ipv4.dst_addr = dst_addr;
        hdr.ipv4.src_addr = src_addr;
        hdr.udp.hdr_length = 98;
        hdr.udp.checksum = 0;
        hdr.telemetry_spead.setValid();
        hdr.telemetry_spead.frequency_no = hdr.channel.frequency_no;
        hdr.telemetry_spead.beam_no = hdr.channel.beam_no;
        hdr.telemetry_spead.sub_array = hdr.station.sub_array;
        hdr.telemetry_spead.total_bytes_telemetry = eg_md.total_bytes_telemetry;
        hdr.telemetry_spead.current_tstamp_telemetry = eg_md.current_tstamp_telemetry;
        hdr.telemetry_spead.previous_tstamp_telemetry = eg_md.previous_tstamp_telemetry;

    }

    action nop() {
    }

    @name(".telemetry_table")
    table telemetry_table {
        key = {
            eg_md.pkt_type : exact @name("pkt_type");
        }
        actions = {
            set_telemetry_header;
            @defaultonly nop;
        }
        size = 10;
        const default_action = nop;

    }


    apply {
        counter_egress_type.count(eg_md.packet_type_ingress++eg_intr_md.egress_port);

        telemetry_table.apply();
    }

}

// ---------------------------------------------------------------------------------------
// main package block
// note that the Pipeline must be named "pipe" for the P4Runtime shell scripts to work
// ---------------------------------------------------------------------------------------

// instantiate one pipeline only
Pipeline(
    IngressParser(),
    Ingress(),
    IngressDeparser(),
    EgressParser(),
    Egress(),
    EgressDeparser()
) pipe;

// instantiate the package Switch with a single pipeline
@pkginfo(name="low_cbf", version="0.4.5")
@pkginfo(organization="CSIRO")
@pkginfo(contact="guillaume.jourjon@csiro.au")
@brief("Low CBF P4 rules for AA0.5")
@description("Low CBF P4 rules for AA0.5")
Switch(pipe) main;
