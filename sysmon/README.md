# Sysmon for Linux config

This is a simple Sysmon for Linux config to just get process starts.

## Install
First follow [this page](https://github.com/Sysinternals/SysmonForLinux/blob/main/INSTALL.md)
to install Sysmon for Linux.

Then run
```bash
sudo sysmon -accepteula -i sysmon_config.xml
```

## Get logs
To get a stream of logs in human-readible format:
```bash
sudo bash -c '
    tail -f /var/log/syslog |
    /opt/sysmon/sysmonLogView -e 1
'
```

`sysmonLogView` has some extra filtering options, e.g. to filter to only processes:
creted by user `path_user`:
```bash
/opt/sysmon/sysmonLogView -e 1 -f User=path_user
```
