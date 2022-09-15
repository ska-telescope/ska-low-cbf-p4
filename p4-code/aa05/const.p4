//
#ifndef _CONST_P4_
#define _CONST_P4_

const bit<16> SPEAD_TABLE_SIZE = 16w65535;

/* ARP */
const bit<16> ARP_HTYPE_ETHERNET = 0x0001;
const bit<8>  ARP_HLEN_ETHERNET  = 6;
const bit<8>  ARP_PLEN_IPV4      = 4;
const bit<16> ARP_OPER_REQUEST   = 0x0001;
const bit<16> ARP_OPER_REPLY     = 0x0002;

// Constants to help with static flow entries and troubleshooting
//const PortId_t PORT_1_0 = 9w128;
//const PortId_t PORT_1_1 = 9w129;
// for wedge-3 only
//const PortId_t<14> PORT_LIST = ;
const PortId_t PORT_1_0 = 9w128;
const PortId_t PORT_2_0 = 9w136;
const PortId_t PORT_3_0 = 9w144;
const PortId_t PORT_4_0 = 9w152;
const PortId_t PORT_5_0 = 9w160;
const PortId_t PORT_6_0 = 9w168;
const PortId_t PORT_7_0 = 9w176;
const PortId_t PORT_8_0 = 9w184;
const PortId_t PORT_9_0 = 9w60;
const PortId_t PORT_10_0 = 9w52;
const PortId_t PORT_11_0 = 9w44;
const PortId_t PORT_12_0 = 9w36;
const PortId_t PORT_13_0 = 9w28;
const PortId_t PORT_14_0 = 9w20;
const PortId_t PORT_15_0 = 9w12;
const PortId_t PORT_16_0 = 9w4;
const PortId_t PORT_17_0 = 9w0;
const PortId_t PORT_18_0 = 9w8;
const PortId_t PORT_19_0 = 9w16;
const PortId_t PORT_20_0 = 9w24;
const PortId_t PORT_30_0 = 9w156;
const PortId_t PORT_31_0 = 9w132;
const PortId_t PORT_32_0 = 9w140;


#endif
