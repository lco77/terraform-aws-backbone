Content-Type: multipart/mixed; boundary="===============5667446636311187280=="
MIME-Version: 1.0

--===============5667446636311187280==
Content-Type: text/cloud-config; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="cloud-config"

#cloud-config
vinitparam:
 - otp : ${device_token}
 - uuid : ${device_uuid}
 - vbond : ${vbond_address}
 - org : ${org_id}

--===============5667446636311187280==
Content-Type: text/cloud-boothook; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="config-${device_uuid}.txt"

#cloud-boothook
  system
   ztp-status            success
   pseudo-confirm-commit 300
   personality           vedge
   device-model          vedge-C8000V
   chassis-number        ${device_uuid}
   system-ip             ${system_ip}
   overlay-id            1
   site-id               ${site_id}
   port-offset           0
   control-session-pps   300
   admin-tech-on-failure
   sp-organization-name  "${org_id}"
   organization-name     "${org_id}"
   port-hop
   track-transport
   track-default-gateway
   console-baud-rate     9600
   config-template-name  ${device_template}
   no on-demand enable
   on-demand idle-timeout 10
   vbond ${vbond_address} port 12346
   logging
    disk
     enable
    !
   !
  !
  bfd default-dscp 48
  bfd app-route multiplier 6
  bfd app-route poll-interval 600000
  security
   ipsec
    rekey               86400
    replay-window       512
    authentication-type sha1-hmac ah-sha1-hmac
   !
  !
  sslproxy
   no enable
   rsa-key-modulus      2048
   certificate-lifetime 730
   eckey-type           P256
   ca-tp-label          PROXY-SIGNING-CA
   settings expired-certificate  drop
   settings untrusted-certificate drop
   settings unknown-status       drop
   settings certificate-revocation-check none
   settings unsupported-protocol-versions drop
   settings unsupported-cipher-suites drop
   settings failure-mode         close
   settings minimum-tls-ver      TLSv1
   dual-side optimization enable
  !
  sdwan
   interface GigabitEthernet1
    tunnel-interface
     encapsulation ipsec preference 10 weight 1
     no border
     color biz-internet restrict
     no last-resort-circuit
     no low-bandwidth-link
     max-control-connections       1
     no vbond-as-stun-server
     vmanage-connection-preference 5
     port-hop
     carrier                       default
     nat-refresh-interval          5
     hello-interval                1000
     hello-tolerance               12
     no allow-service all
     no allow-service bgp
     allow-service dhcp
     allow-service dns
     allow-service icmp
     allow-service sshd
     no allow-service netconf
     allow-service ntp
     no allow-service ospf
     no allow-service stun
     allow-service https
     no allow-service snmp
     no allow-service bfd
    exit
   exit
   appqoe
    no tcpopt enable
    no dreopt enable
   !
   omp
    no shutdown
    send-path-limit  4
    ecmp-limit       4
    graceful-restart
    no as-dot-notation
    timers
     holdtime               60
     advertisement-interval 1
     graceful-restart-timer 43200
     eor-timer              300
    exit
   !
  !
  service tcp-keepalives-in
  service tcp-keepalives-out
  no service tcp-small-servers
  no service udp-small-servers
  hostname ${hostname}
  username admin privilege 15 secret 9 ${password9}
  vrf definition Mgmt-intf
   description Transport VPN
   rd          1:512
   address-family ipv4
    route-target export 1:512
    route-target import 1:512
    exit-address-family
   !
   address-family ipv6
    exit-address-family
   !
  !
  ip arp proxy disable
  no ip finger
  no ip rcmd rcp-enable
  no ip rcmd rsh-enable
  no ip dhcp use class
  no ip ftp passive
  ip name-server ${dns_server}
  ip bootp server
  no ip source-route
  no ip http server
  no ip http secure-server
  ip nat settings central-policy
  interface GigabitEthernet1
   description   INTERNET
   no shutdown
   arp timeout 1200
   ip address dhcp client-id GigabitEthernet1
   no ip redirects
   ip dhcp client default-router distance 1
   ip mtu    1500
   load-interval 30
   mtu           1500
   negotiation auto
  exit
  interface Tunnel1
   no shutdown
   ip unnumbered GigabitEthernet1
   no ip redirects
   ipv6 unnumbered GigabitEthernet1
   no ipv6 redirects
   tunnel source GigabitEthernet1
   tunnel mode sdwan
  exit
  clock timezone UTC 0 0
  logging persistent size 104857600 filesize 10485760
  no logging monitor
  logging buffered 512000
  logging console
  aaa authentication login default local
  aaa authorization exec default local
  aaa server radius dynamic-author
  !
  no crypto ikev2 diagnose error
  no crypto isakmp diagnose error
  no network-clock revertive
  snmp-server ifindex persist
  line con 0
   speed    9600
   stopbits 1
  !
  line vty 0 4
   transport input ssh
  !
  line vty 5 80
   transport input ssh
  !
  lldp run
  nat64 translation timeout tcp 3600
  nat64 translation timeout udp 300
 !
!

--===============5667446636311187280==--
