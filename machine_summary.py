#!/usr/bin/python
# -*- coding: utf-8 -*-
"""
Produce a machine summary table in ReStructuredText
"""
from __future__ import with_statement
import math
import os
import socket
try:
    from collections import Counter
except ImportError:
    from collections import defaultdict
    class Counter(defaultdict):
        def __init__(self, items=()):
            defaultdict.__init__(self, int)
            for item in items:
                self[item] += 1


__version__ = '0.4'


def fmt_with_units(size, units):
    return ('%.1f %s' % (size, units)).replace('.0 ', ' ')


def fmt_size_decimal(bytes):
    size, units = bytes, 'B'
    for prefix in 'KB', 'MB', 'GB', 'TB', 'PB':
        if size >= 1000:
            size, units = size / 1000., prefix
    return fmt_with_units(size, units)


def fmt_size_si(bytes):
    size, units = bytes, 'B'
    for prefix in 'KiB', 'MiB', 'GiB', 'TiB', 'PiB':
        if size >= 1024:
            size, units = size / 1024., prefix
    return fmt_with_units(size, units)


def round_binary(bytes):
    bits = bin(bytes).lstrip('0b')
    if len(bits) < 2:
        return bytes
    mantissa = int(bits[:2], 2)
    exponent = len(bits) - 2
    if bits[2:].strip('0'):
        mantissa += 1
    return mantissa << exponent


def get_hostname():
    """Return the (full) hostname"""
    hostname = socket.getfqdn()
    if hostname in ('localhost6.localdomain6', 'localhost.localdomain'):
        # I'd like to return the full hostname, but socket.getfqdn() is buggy
        # and returns 'localhost6.localdomain6' on modern ubuntu
        hostname = socket.gethostname()
    return hostname


def read_file(filename):
    with open(filename) as f:
        return f.read()


def get_fields(filename, fieldnames, separator=':'):
    if isinstance(fieldnames, str):
        fieldnames = (fieldnames, )
    with open(filename) as f:
        for line in f:
            field, _, value = line.partition(separator)
            if field.strip() in fieldnames:
                yield value.strip()


def get_cpu_info():
    """Return the model of the first"""
    models = Counter(get_fields('/proc/cpuinfo', ['model name', 'cpu model']))
    return ', '.join(
        '%d × %s' % (count, model)
        for model, count in sorted(models.items())
    )


def get_ram_info():
    """Return the amount of RAM"""
    for value in get_fields('/proc/meminfo', 'MemTotal'):
        kibibytes = int(value.split()[0])
        # How do I add the "reserved" ram that the kernel subtracts from
        # MemTotal?  I see it in /var/log/dmesg, but not in /proc
        # I could use dmidecode or lshw, if I had root...
        # oh well, assume if it's almost a round number of gigs, then it's
        # that exact number of gigs.
        return fmt_size_si(round_binary(kibibytes * 1024))
    return 'n/a'


def get_disk_info(device):
    if device == 'simfs':
        # iv.lt VPSes have no /sys/block; they mount /dev/simfs on /
        r = os.statvfs('/')
        size = fmt_size_si(r.f_blocks * r.f_bsize)
        return size
    elif device == 'swap':
        with open('/proc/swaps') as f:
            next(f) # skip header line
            size = 0
            for line in f:
                size += int(line.split()[2])
            return fmt_size_si(size * 1024)

    sectors = int(read_file('/sys/block/%s/size' % device))
    size = fmt_size_decimal(sectors * 512)
    if device.startswith('cciss'):
        vendor = read_file('/sys/block/%s/device/vendor' % device).strip()
        raid_level = read_file('/sys/block/%s/device/raid_level' % device).strip()
        return '%s (%s hardware %s)' % (size, vendor, raid_level)
    try:
        model = read_file('/sys/block/%s/device/model' % device).strip()
        return '%s (model %s)' % (size, model)
    except IOError:
        return size


def enumerate_disks():
    if not os.path.exists('/sys/block'):
        # iv.lt VPSes have no /sys/block; they mount /dev/simfs and use
        # /dev/null for swap
        if os.path.exists('/dev/simfs'):
            return ['simfs', 'swap']
        return ['???']
    return sorted(name for name in os.listdir('/sys/block')
                  if name.startswith(('sd', 'cciss')))


def get_disks_info():
    disks = enumerate_disks()
    return ',\n        '.join(
        '%s - %s' % (d, get_disk_info(d))
        for d in disks
    )


def get_netdev_info(device):
    mac = read_file('/sys/class/net/%s/address' % device).strip()
    if mac:
        return 'MAC: %s' % mac


def get_network_info():
    devices = sorted(
        (d, get_netdev_info(d)) for d in os.listdir('/sys/class/net')
        if not d.startswith(('.', 'lo', 'br', 'virbr', 'vboxnet'))
           and '.' not in d
    )
    return ',\n        '.join(
        '%s - %s' % (d, info) if info else d
        for d, info in devices
    )


def get_os_info():
    """Return the OS name and version"""
    # bit of a hack that works on ubuntu and openwrt
    if os.path.exists('/etc/lsb-release'):
        fn = '/etc/lsb-release'
    elif os.path.exists('/etc/openwrt_release'):
        fn = '/etc/openwrt_release'
    else:
        return 'n/a'
    for value in get_fields(fn, 'DISTRIB_DESCRIPTION', '='):
        return value.strip('"')
    return 'n/a'


def get_architecture():
    """Return the OS architecture"""
    return os.uname()[4] # (kernel_name, node_name, kernel_release, kernel_version, cpu)



def main():
    if os.getenv('RUN_AS_CGI'):
        print "Content-Type: text/plain; charset=UTF-8"
        print
    hostname = get_hostname()
    print(hostname)
    print('=' * len(hostname))
    print("")
    print(':CPU: %s' % get_cpu_info())
    print(':RAM: %s' % get_ram_info())
    print(':Disks: %s' % get_disks_info())
    print(':Network: %s' % get_network_info())
    print(':OS: %s (%s)' % (get_os_info(), get_architecture()))


if __name__ == '__main__':
    main()