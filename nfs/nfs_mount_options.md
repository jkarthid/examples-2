# NFS mount options
Recommended mount options for high perfomance data trancfer e.g. databases, mediation devices, file servers, virtualization datastores.

## Mount options
|Operating System| Options |
|-----------------|-----------|
|Solaris|rw,bg,hard,nointr,rsize=1048576,wsize=1048576,proto=tcp,noac,forcedirectio,vers=3,suid|
|Linux|rw,bg,hard,nointr,rsize=1048576,wsize=1048576,tcp,actimeo=0,vers=3,timeo=600|
|AIX|cio,rw,bg,hard,nointr,rsize=1048576,wsize=1048576,proto=tcp,noac,vers=3,timeo=600|
|HP-UX|rw,bg,vers=3,proto=tcp,noac,forcedirectio,hard,nointr,timeo=600,rsize=1048576,wsize=1048576,suid|

## Operating system settings
### Linux
Increase rpc slot count
```
# cat /etc/modprobe.d/sunrpc.conf
options sunrpc tcp_slot_table_entries=128
```

### Solaris
* Increase __nfs:nfs3_max_threads / nfs:nfs4_max_threads__
* Set appropriate __nfs:nfs4_bsize / nfs:nfs3_bsize__
* Increase nfs rnode cache - __nfs:nrnode__
* __nfs:nfs3_max_transfer_size / nfs:nfs4_max_transfer_size__

## I/O Diagram
![alt text](https://3.bp.blogspot.com/-9okxlkow_kg/WQ7efP7B6kI/AAAAAAAAThw/chM14o4hYDUX7hR35vHQKqX2ZWnWqva4wCLcB/s1600/Selection_010.png)

## Network
### Linux example
```
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 32768 262144 16777216
net.ipv4.tcp_wmem = 32768 262144 16777216
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_timestamps = 0
```

### Solaris example
```
ipadm set-prop -p recv_buf=400000 tcp
ipadm set-prop -p send_buf=400000 tcp
ipadm set-prop -p max_buf=2097152 tcp
ipadm set-prop -p _cwnd_max=2097152 tcp
ipadm set-prop -p _conn_req_max_q=512 tcp
```


## Nic Driver
```
# -------------------- Flow Control --------------------
# flow_control
#       Ethernet flow control
#       Allowed values: 0 - Disable
#                       1 - Receive only
#                       2 - Transmit only
#                       3 - Receive and transmit
#       default value:  0
#
flow_control = 0;

#
# -------------------- Transmit/Receive Queues --------------------
#
# tx_ring_size
#       The number of the transmit descriptors per transmit queue
#       Allowed values: 64 - 4096
#       Default value:  1024
tx_ring_size = 4096;

#
# rx_ring_size
#       The number of the receive descriptors per receive queue
#       Allowed values: 64 - 4096
#       Default value:  1024
rx_ring_size = 4096;

# https://docs.oracle.com/cd/E36784_01/html/E36845/gipaf.html#SOLTUNEPARAMREFgikws
# Description
# This parameter controls the number of transmit queues that are used by the ixgbe network driver.
tx_queue_number = 16;
rx_queue_number = 16;

# Description
# This parameter controls the maximum number of receive queue buffer descriptors per interrupt that are used by the ixgbe network driver.
# You can increase the number of receive queue buffer descriptors by increasing the value of this parameter
rx_limit_per_intr = 1024;
tx_copy_threshold = 1024;
rx_copy_threshold = 512;

#
# mr_enable
#       Enable multiple tx queues and rx queues
#       Allowed values: 0 - 1
#       Default value:  1
# https://docs.oracle.com/cd/E19120-01/open.solaris/819-2724/gipao/index.html
mr_enable = 0;

#
# rx_group_number
#       The number of the receive groups
#       Allowed values: 1 - 16 (for Intel 82598 10Gb ethernet controller)
#       Allowed values: 1 - 64 (for Intel 82599/X540 10Gb ethernet controller)
#       Default value:  1
rx_group_number = 8;
```
