# Сбор информации через ADB Shell

```
echo '=== BUILD INFO ===' && getprop | grep -E 'ro.build|ro.product|ro.board' && echo -e '\n=== CPU & MEM ===' && cat /proc/cpuinfo | head -20 && echo -e '\n=== MEMORY ===' && free -m && echo -e '\n=== STORAGE ===' && df -h /data /system && echo -e '\n=== NETWORK ===' && ip addr show && echo -e '\n=== RUNNING PROCESSES ===' && ps -A | head -30 && echo -e '\n=== LOGCAT LAST ERRORS ===' && logcat -d -s AndroidRuntime:* *:E | tail -20
```

# Описание устройства

## Харакетристики

- _SoC:_ Allwinner H313 (он же IK316), 4 ядра ARM Cortex-A53.
- _GPU:_ ARM Mali-G31 MP2.
- _RAM:_ ~1 ГБ (в логе видно 813 МБ total, часть зарезервирована системой)
- _Storage:_ 8 ГБ eMMC (раздел /data около 3.5 ГБ доступного)
- _Android:_ Версия 10 (API 29), сборка от октября 2025 года (судя по дате в логе, прошивка кастомная или с будущей датой сборки) 
- _Платформа:_ cupid, Устройство: titan-p1.
	
# Дамп собранной информации

## === BUILD INFO ===

```
[ro.board.platform]: [cupid]
[ro.build.characteristics]: [tv]
[ro.build.date]: [Wed Oct 29 15:11:43 CST 2025]
[ro.build.date.utc]: [1761721903]
[ro.build.description]: [titan_p1-userdebug 10 QP1A.191105.004 eng.akrc5.20251029.151147 test-keys]
[ro.build.display.id]: [Android TV_2025-10-29-15.12.34]
[ro.build.f]: [128]
[ro.build.fingerprint]: [google/walley/titan-p1:15.0/QP1A.191105.004/eng.akrc5.20251029.151147:userdebug/release-keys]
[ro.build.flavor]: [titan_p1-userdebug]
[ro.build.host]: [R750xs]
[ro.build.id]: [QP1A.191105.004]
[ro.build.name]: [Android TV]
[ro.build.product]: [titan-p1]
[ro.build.r]: [8]
[ro.build.tags]: [release-keys]
[ro.build.type]: [userdebug]
[ro.build.user]: [akrc5]
[ro.build.version.all_codenames]: [REL]
[ro.build.version.base_os]: []
[ro.build.version.codename]: [REL]
[ro.build.version.incremental]: [eng.akrc5.20251029.151147]
[ro.build.version.min_supported_target_sdk]: [23]
[ro.build.version.preview_sdk]: [0]
[ro.build.version.preview_sdk_fingerprint]: [REL]
[ro.build.version.release]: [15.0]
[ro.build.version.sdk]: [29]
[ro.build.version.security_patch]: [2019-12-05]
[ro.product.board]: [exdroid]
[ro.product.brand]: [google]
[ro.product.build.date]: [Wed Oct 29 15:11:43 CST 2025]
[ro.product.build.date.utc]: [1761721903]
[ro.product.build.fingerprint]: [Allwinner/titan_p1/titan-p1:10/QP1A.191105.004/akrc510291511:userdebug/test-keys]
[ro.product.build.id]: [QP1A.191105.004]
[ro.product.build.tags]: [test-keys]
[ro.product.build.type]: [userdebug]
[ro.product.build.version.incremental]: [eng.akrc5.20251029.151147]
[ro.product.build.version.release]: [10]
[ro.product.build.version.sdk]: [29]
[ro.product.cpu.abi]: [armeabi-v7a]
[ro.product.cpu.abi2]: [armeabi]
[ro.product.cpu.abilist]: [armeabi-v7a,armeabi]
[ro.product.cpu.abilist32]: [armeabi-v7a,armeabi]
[ro.product.cpu.abilist64]: []
[ro.product.device]: [titan-p1]
[ro.product.firmware]: [IK316-Q-v1.0]
[ro.product.first_api_level]: [29]
[ro.product.locale]: [en-US]
[ro.product.manufacturer]: [Google]
[ro.product.model]: [Android TV]
[ro.product.name]: [walley]
[ro.product.odm.brand]: [google]
[ro.product.odm.device]: [titan-p1]
[ro.product.odm.manufacturer]: [Google]
[ro.product.odm.model]: [Android TV]
[ro.product.odm.name]: [walley]
[ro.product.odm.platform]: [homlet]
[ro.product.platform]: [homlet]
[ro.product.product.brand]: [google]
[ro.product.product.device]: [titan-p1]
[ro.product.product.manufacturer]: [Google]
[ro.product.product.model]: [Android TV]
[ro.product.product.name]: [walley]
[ro.product.product.platform]: [homlet]
[ro.product.system.brand]: [google]
[ro.product.system.device]: [titan-p1]
[ro.product.system.manufacturer]: [Google]
[ro.product.system.model]: [Android TV]
[ro.product.system.name]: [walley]
[ro.product.system.platform]: [homlet]
[ro.product.system.stacksize]: [8M]
[ro.product.vendor.brand]: [google]
[ro.product.vendor.device]: [titan-p1]
[ro.product.vendor.manufacturer]: [Google]
[ro.product.vendor.model]: [Android TV]
[ro.product.vendor.name]: [walley]
[ro.product.vendor.platform]: [homlet]
```

## === CPU & MEM ===

```
processor	: 0
model name	: ARMv8 Processor rev 4 (v8l)
BogoMIPS	: 48.00
Features	: half thumb fastmult vfp edsp neon vfpv3 tls vfpv4 idiva idivt lpae aes pmull sha1 sha2 crc32
CPU implementer	: 0x41
CPU architecture: 8
CPU variant	: 0x0
CPU part	: 0xd03
CPU revision	: 4

processor	: 1
model name	: ARMv8 Processor rev 4 (v8l)
BogoMIPS	: 48.00
Features	: half thumb fastmult vfp edsp neon vfpv3 tls vfpv4 idiva idivt lpae aes pmull sha1 sha2 crc32
CPU implementer	: 0x41
CPU architecture: 8
CPU variant	: 0x0
CPU part	: 0xd03
CPU revision	: 4
```

## === MEMORY ===

```
		total        used        free      shared     buffers
Mem:              813         777          36           5           0
-/+ buffers/cache:            776          36
Swap:             610         290         319
```

## === STORAGE ===

```
Filesystem            Size  Used Avail Use% Mounted on
/dev/block/mmcblk0p17 3.5G  1.0G  2.5G  29% /data
/dev/block/dm-0       1.6G  1.6G  5.1M 100% /apex/com.android.resolv
```

## === NETWORK ===

```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc pfifo_fast state DOWN group default qlen 1000
    link/ether 9c:00:d3:ee:b4:85 brd ff:ff:ff:ff:ff:ff
3: tunl0@NONE: <NOARP> mtu 1480 qdisc noop state DOWN group default qlen 1
    link/ipip 0.0.0.0 brd 0.0.0.0
4: gre0@NONE: <NOARP> mtu 1476 qdisc noop state DOWN group default qlen 1
    link/gre 0.0.0.0 brd 0.0.0.0
5: gretap0@NONE: <BROADCAST,MULTICAST> mtu 1462 qdisc noop state DOWN group default qlen 1000
    link/ether 00:00:00:00:00:00 brd ff:ff:ff:ff:ff:ff
6: ip_vti0@NONE: <NOARP> mtu 1480 qdisc noop state DOWN group default qlen 1
    link/ipip 0.0.0.0 brd 0.0.0.0
7: ip6_vti0@NONE: <NOARP> mtu 1500 qdisc noop state DOWN group default qlen 1
    link/tunnel6 :: brd ::
8: sit0@NONE: <NOARP> mtu 1480 qdisc noop state DOWN group default qlen 1
    link/sit 0.0.0.0 brd 0.0.0.0
9: ip6tnl0@NONE: <NOARP> mtu 1452 qdisc noop state DOWN group default qlen 1
    link/tunnel6 :: brd ::
11: wlan0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 08:ec:7b:89:46:c1 brd ff:ff:ff:ff:ff:ff
    inet 172.16.110.100/24 brd 172.16.110.255 scope global wlan0
       valid_lft forever preferred_lft forever
    inet6 fe80::aec:7bff:fe89:46c1/64 scope link 
       valid_lft forever preferred_lft forever
```

## === RUNNING PROCESSES ===

```
USER           PID  PPID     VSZ    RSS WCHAN            ADDR S NAME                       
root             1     0   28064   2648 SyS_epoll_wait      0 S init
root             2     0       0      0 kthreadd            0 S [kthreadd]
root             4     2       0      0 worker_thread       0 S [kworker/0:0H]
root             6     2       0      0 smpboot_thread_fn   0 S [ksoftirqd/0]
root             7     2       0      0 rcu_gp_kthread      0 S [rcu_preempt]
root             8     2       0      0 rcu_gp_kthread      0 S [rcu_sched]
root             9     2       0      0 rcu_gp_kthread      0 S [rcu_bh]
root            10     2       0      0 smpboot_thread_fn   0 S [migration/0]
root            11     2       0      0 rescuer_thread      0 S [lru-add-drain]
root            12     2       0      0 smpboot_thread_fn   0 S [cpuhp/0]
root            13     2       0      0 smpboot_thread_fn   0 S [cpuhp/1]
root            14     2       0      0 smpboot_thread_fn   0 S [migration/1]
root            15     2       0      0 smpboot_thread_fn   0 S [ksoftirqd/1]
root            16     2       0      0 worker_thread       0 S [kworker/1:0]
root            17     2       0      0 worker_thread       0 S [kworker/1:0H]
root            18     2       0      0 smpboot_thread_fn   0 S [cpuhp/2]
root            19     2       0      0 smpboot_thread_fn   0 S [migration/2]
root            20     2       0      0 smpboot_thread_fn   0 S [ksoftirqd/2]
root            22     2       0      0 worker_thread       0 S [kworker/2:0H]
root            23     2       0      0 smpboot_thread_fn   0 S [cpuhp/3]
root            24     2       0      0 smpboot_thread_fn   0 S [migration/3]
root            25     2       0      0 smpboot_thread_fn   0 S [ksoftirqd/3]
root            27     2       0      0 worker_thread       0 S [kworker/3:0H]
root            28     2       0      0 devtmpfsd           0 S [kdevtmpfs]
root            29     2       0      0 rescuer_thread      0 S [netns]
root           449     2       0      0 oom_reaper          0 S [oom_reaper]
root           450     2       0      0 rescuer_thread      0 S [writeback]
root           452     2       0      0 kcompactd           0 S [kcompactd0]
root           453     2       0      0 rescuer_thread      0 S [crypto]
```
