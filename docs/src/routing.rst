Routing Logic
=============

List of Tables
--------------

+------------------------+-------------------------------+-------------------------------------------+
|  Table Name            |  Match                        |  Action                                   |
+========================+===============================+===========================================+
| BasicTable             | Incoming Port                 | Send to destination Port p                |
+------------------------+-------------------------------+-------------------------------------------+
| PSR routing            | PSR Beam number               | Send to destination Port p  and           |
|                        |                               | Change UDP destionation port              |
+------------------------+-------------------------------+-------------------------------------------+
| Multicast SPEAD        | Triple <freq, subarray, beam> | Send to multicast group                   |
+------------------------+-------------------------------+-------------------------------------------+
| Unicast SPEAD          | Triple <freq, subarray, beam> | Send to destination Port p                |
+------------------------+-------------------------------+-------------------------------------------+
| Change MAC address     | Dst IP Address                | Change MAC dst addr                       |
+------------------------+-------------------------------+-------------------------------------------+
| IP routing             | Dst IP Address                | Send to destination Port p                |
+------------------------+-------------------------------+-------------------------------------------+
| PTP routing from Clock | Incoming Port                 | Send to multicast group 1                 |
+------------------------+-------------------------------+-------------------------------------------+
| PTP routing to Clock   | Incoming Port                 | Send to destination Port p                |
+------------------------+-------------------------------+-------------------------------------------+
| ARP traffic            | Target IP                     | 3 actions: SDP queries, answers, and SPS  |
+------------------------+-------------------------------+-------------------------------------------+

General Logic
-------------

On arrival switch attempt to extract all relevant headers. Then try to match each table in sequence:

#. If protocol P present then:

    * If P = SPS Spead, match spead multicast then unicast
    * If P = PSR, match PSR
    * If P = UDP, match MAC changing, then IP forwarding
    * If P = PTP, match “PTP routing from Clock” then “PTP routing to Clock”
    * If P = ARP, match ARP table
    * If P = IPv4, perform TTL = TTL-1

#. Try to match Basic Table

#. Try to apply Multicast Table

Logic is sequential meaning that the last rule that will be matched always win.
i.e. If a packet matches basic rule and also matches the SPEAD unicast rule then SPEAD unicast wins.

Conflict might occur if:

* Basic rule and any other rules are matches
* Protocol rules and IP forwarding rules are matches
* Any rules in step 1 and 2 getting overruled by Multicast rule in step 3

Flowchart
---------

.. mermaid::

    flowchart TB
        Arrive[Packet Arrives] --> Extract(Extract Headers)
        Extract --> Multi{Multicast Table?}
        Multi -- Yes --> ApplyMulti(Apply Multicast rule)
        Multi -- No --> Basic{Basic Table?}
        Basic -- Yes --> ApplyBasicRule(Apply Basic rule)
        Basic -- No --> IP{IPv4?}
        IP -- Yes --> TTL(Decrement TTL)
        subgraph IP Based Protocols
            TTL --> IP_FORWARD{IP DEST Match}
            IP_FORWARD -- No --> PSR{PSR?}
            PSR -- No --> SPS_M{SPS SPEAD\nMulticast?}
            SPS_M -- No --> SPS_U{SPS SPEAD\nUnicast?}
        end
        IP -- No --> ARP{ARP?}
        subgraph "Non-IP Protocols"
            ARP -- No --> PTP{PTP?}
        end
        PTP -- No --> Discard
        ARP -- Yes --> ApplyARD(Apply ARP rule)
        PTP -- Yes --> ApplyPTP(Apply PTP rule)
        IP_FORWARD -- Yes --> ApplyIPForward(Apply IP Forward rule)
        PSR -- Yes --> ApplyPSR(Apply PSR rule)
        SPS_M -- Yes --> ApplySPSM(Apply SPS Multicast rule)
        SPS_U -- Yes --> ApplySPSU(Apply SPS Unicast rule)
        SPS_U -- No --> Discard
