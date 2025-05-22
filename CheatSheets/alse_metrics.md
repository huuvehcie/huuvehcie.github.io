# Метрики для фонового мониторинга ПО на AstraLinux

| **Категория**       | **Метрика**                          | **Команда для сбора (с временными метками)**                                                                 |
|----------------------|--------------------------------------|------------------------------------------------------------------------------------------------------------|
| **Ресурсы системы**  | Загрузка CPU (общая и по ядрам)      | `sar -u ALL -P ALL 5 -t -o /var/log/cpu.log`                                                              |
|                      | Использование ОЗУ и swap             | `vmstat -t 5 > /var/log/mem.log`                                                                          |
|                      | Дисковая активность (IOPS, latency)  | `iostat -xtz 5 -t > /var/log/disk_io.log`                                                                |
|                      | Свободное место на диске             | `df -h | awk '{print strftime("%Y-%m-%d %T"), $0}' >> /var/log/disk_space.log`                                 |
|                      | Сетевой трафик (пакеты/байты)        | `sar -n DEV 5 -t > /var/log/network.log`                                                                 |
|                      | Открытые сокеты                     | `ss -tunap -o state established | awk '{print strftime("%Y-%m-%d %T"), $0}' >> /var/log/sockets.log`                  |
| **Процессы**         | Потребление ресурсов процессами      | `pidstat -druh -p ALL 5 -t > /var/log/processes.log`                                                     |
|                      | Количество потоков                   | `ps -eLf | awk '{print strftime("%Y-%m-%d %T"), $0}' >> /var/log/threads.log`                                      |
| **ОС и ядро**        | Uptime системы                       | `awk '{print strftime("%Y-%m-%d %T"), "Uptime:", $1}' /proc/uptime >> /var/log/uptime.log`               |
|                      | Очередь задач ядра                   | `sar -q 5 -t > /var/log/runqueue.log`                                                                     |
|                      | Статус systemd-юнитов                | `systemctl list-units --type=service --state=running --no-pager | awk '{print strftime("%Y-%m-%d %T"), $0}' >> /var/log/services.log` |
| **Логи и ошибки**    | Критические события (реaltime)       | `journalctl -p 3 --since "5 seconds ago" -f -o short-iso >> /var/log/critical_events.log`                |
| **Безопасность**     | Активные iptables-правила            | `iptables-save | awk '{print strftime("%Y-%m-%d %T"), $0}' >> /var/log/firewall.log`                                   |
| **Совместимость**    | Загруженные библиотеки процесса      | `lsof -p <PID> | grep 'mem' | awk '{print strftime("%Y-%m-%d %T"), $0}' >> /var/log/libs.log`                          |
| **Производительность** | Контекстные переключения            | `sar -w 5 -t > /var/log/context_switches.log`                                                            |
|                      | Прерывания (IRQ)                     | `sar -I ALL 5 -t > /var/log/interrupts.log`                                                              |

### Рекомендации по запуску:
1. Для **демонизации** используйте `nohup command &` или `screen`.
2. Все команды автоматически добавляют временные метки:
   - `-t` в `sar/vmstat/iostat` 
   - `strftime()` в `awk` для других утилит.
3. Интервал сбора (5 сек) можно менять (например, `sar -u 10` для 10 сек).
4. Для анализа PID конкретного процесса:  
   ```bash
   watch -n5 'ps -p <PID> -o pid,%cpu,%mem,time,cputime >> /var/log/target_process.log'
