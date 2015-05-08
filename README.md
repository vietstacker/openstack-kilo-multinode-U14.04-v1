# Đặt gạch tài liệu cài đặt OpenStack Kilo
Install OpenStack Kilo on Ubuntu 14.04


### CONTROLLER(CTL) NODE 

- Tải git và các script 

```sh
apt-get update
apt-get -y install git
git clone https://github.com/tothanhcong/openstack-kilo-multinode-U14.04-v1.git
mv openstack-kilo-multinode-U14.04-v1/KILO-U14.04/ /root/
rm -rf openstack-kilo-multinode-U14.04-v1/
cd KILO-U14.04
chmod +x *.sh
```

- Thực thi script thứ nhất: Đặt tên và cấu hình card mạng cho node CTL
```sh
bash ctl-1-ipadd.sh
```

- Script 2

```sh
bash ctl-2-prepare.sh
```