# DarkSense Collector

A comprehensive log collection and forwarding system built with Logstash for centralized log management and analysis. This project provides automated setup scripts and configuration files to deploy a robust log collection infrastructure on Ubuntu systems.

## Overview

DarkSense Collector is designed to:
- Collect logs from multiple sources (Windows systems, network devices, syslog)
- Process and enrich log data with organizational metadata
- Forward processed logs to a Kafka-based analytics platform
- Provide automated setup and configuration for Ubuntu-based collectors

## Architecture

The system consists of multiple Logstash pipelines:

1. **Input Pipelines**: Collect logs from various sources
   - `os_windows`: Windows log collection via Beats (port 5044)
   - `syslog`: Network device syslog collection (port 10024, TCP/UDP)

2. **Processing Pipeline**: Central log processing and enrichment
   - `prod_k8s_out`: Processes all logs, adds metadata, and forwards to Kafka

## Project Structure

```
darksense-collector/
├── initial-setup-ubuntu.sh       # Ubuntu system initial configuration
├── install-logstash.sh          # Logstash installation and setup
└── Logstash-Configs/
    ├── pipelines.yaml           # Pipeline configuration
    ├── os_windows.conf          # Windows log input pipeline
    ├── syslog.conf              # Syslog input pipeline
    └── prod_k8s_out.conf        # Output processing pipeline
```

## Prerequisites

- Ubuntu Linux system (tested on recent LTS versions)
- Root or sudo access
- Network connectivity to target systems and Kafka cluster
- SSL certificates for Kafka authentication (truststore.jks, keystore.jks)

## Quick Start

### 1. Initial System Setup

First, configure your Ubuntu system with static networking:

```bash
sudo ./initial-setup-ubuntu.sh
```

This script will:
- Set hostname and domain name
- Configure static IP addressing
- Update system networking configuration
- Reboot the system

### 2. Install and Configure Logstash

After system reboot, install Logstash and configure pipelines:

```bash
sudo ./install-logstash.sh
```

This script will:
- Add Elastic repository and GPG keys
- Install Logstash 9.x
- Copy configuration files to `/etc/logstash/conf.d/`
- Set proper permissions
- Start Logstash service

### 3. Configure Organization Settings

Before running Logstash, update the following placeholders in `Logstash-Configs/prod_k8s_out.conf`:

- `YOURORGANIZATIONNAME`: Your organization's name
- `YOURORGANIZATIONID`: Your organization's unique identifier
- `THENAMEOFYOURCOLLECTOR`: A descriptive name for this collector
- `YOURPASSWORD`: SSL keystore/truststore passwords

### 4. Deploy SSL Certificates

Place your Kafka SSL certificates in `/etc/logstash/certs/`:
- `truststore.jks`: Kafka cluster trust store
- `keystore.jks`: Client authentication keystore

## Configuration Details

### Pipeline Configuration

The system uses multiple pipelines defined in `pipelines.yaml`:

- **os_windows**: Handles Windows event logs from Winlogbeat
  - Workers: 1
  - Batch size: 125
  - Input port: 5044

- **prod_k8s_out**: Processes and forwards all logs
  - Workers: 2
  - Batch size: 125
  - Outputs to Kafka

### Input Sources

#### Windows Logs (`os_windows.conf`)
- Receives logs from Winlogbeat agents
- Listens on port 5044
- Tags logs as "winlogbeat"
- Adds sender identification

#### Syslog (`syslog.conf`)
- Accepts syslog from network devices (Cisco Catalyst switches)
- Listens on port 10024 (both TCP and UDP)
- Tags logs with device type

### Log Processing (`prod_k8s_out.conf`)

The processing pipeline performs several transformations:

1. **Host field normalization**: Standardizes hostname fields
2. **IP address extraction**: Extracts IP addresses from various formats
3. **Metadata enrichment**: Adds organizational context
4. **Kafka forwarding**: Sends processed logs to analytics platform

## Monitoring and Troubleshooting

### Check Logstash Status

```bash
sudo systemctl status logstash
```

### View Logstash Logs

```bash
sudo journalctl -u logstash -f
```

### Test Configuration

```bash
sudo /usr/share/logstash/bin/logstash --config.test_and_exit --path.config=/etc/logstash/conf.d/
```

### Common Issues

1. **Port conflicts**: Ensure ports 5044 and 10024 are available
2. **SSL certificate issues**: Verify certificate paths and passwords
3. **Network connectivity**: Test connectivity to Kafka cluster
4. **Permissions**: Ensure logstash user has access to config files and certificates

## Security Considerations

- SSL/TLS encryption for all Kafka communications
- Certificate-based authentication
- Firewall rules should restrict access to input ports
- Regular certificate rotation recommended
- Monitor for unauthorized access attempts

## Customization

### Adding New Input Sources

1. Create a new `.conf` file in `Logstash-Configs/`
2. Configure input source and add appropriate tags
3. Route output to `prod_k8s_out` pipeline
4. Update `pipelines.yaml` if needed
5. Restart Logstash service

### Modifying Log Processing

Edit `prod_k8s_out.conf` to:
- Add new field transformations
- Modify metadata enrichment
- Change output destinations
- Add conditional processing logic

## Maintenance

### Regular Tasks

- Monitor disk space for log files
- Update SSL certificates before expiration
- Review and rotate Kafka authentication credentials
- Update Logstash version periodically
- Monitor pipeline performance metrics

### Backup

Important files to backup:
- `/etc/logstash/conf.d/` - Configuration files
- `/etc/logstash/certs/` - SSL certificates
- `/etc/logstash/pipelines.yml` - Pipeline definitions

## Support

For issues and questions:
1. Check Logstash logs for error messages
2. Verify network connectivity to all endpoints
3. Validate SSL certificate configuration
4. Review firewall and security group settings

## License

This project is part of the DarkSense security analytics platform. Please refer to your organization's licensing terms.

---

**Note**: This is a production system handling sensitive security logs. Ensure all security best practices are followed and access is properly restricted.