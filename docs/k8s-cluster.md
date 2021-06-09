## firewall-cmd

```bash
firewall-cmd --permanent --add-port=22/tcp
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --permanent --add-port=2376/tcp
firewall-cmd --permanent --add-port=2379/tcp
firewall-cmd --permanent --add-port=2380/tcp
firewall-cmd --permanent --add-port=6443/tcp
firewall-cmd --permanent --add-port=8472/udp
firewall-cmd --permanent --add-port=9099/tcp
firewall-cmd --permanent --add-port=10250/tcp
firewall-cmd --permanent --add-port=10254/tcp
firewall-cmd --permanent --add-port=30000-32767/tcp
firewall-cmd --permanent --add-port=30000-32767/udp

# gpushare
firewall-cmd --permanent --add-port=12345/tcp

# traefik bad gateway 502
firewall-cmd --add-masquerade --permanent

# coredns can not parse domain in multi nodes
firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -i cni0 -j ACCEPT

firewall-cmd --reload
```
