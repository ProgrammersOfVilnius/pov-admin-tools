#!/usr/bin/python3
from __future__ import print_function
import argparse
import re
import sys


__version__ = '1.0.1'


date_rx = re.compile(r'^\d{4}-\d{2}-\d{2}( \d{2}:\d{2})?')


def warn(filename, lineno, message):
    print("%s:%d: %s" % (filename, lineno, message), file=sys.stderr)


def check(fileobj, filename):
    prev_date = None
    prev_dates = {}
    for n, line in enumerate(fileobj, 1):
        m = date_rx.match(line)
        if not m:
            continue
        cur_date = m.group(0)
        if prev_date is not None and cur_date < prev_date:
            warn(filename, n,
                 'date out of order (%s after %s)' % (cur_date, prev_date))
            if cur_date in prev_dates:
                warn(filename, prev_dates[cur_date],
                     '%s previously used here' % cur_date)
        prev_dates[cur_date] = n
        prev_date = cur_date


def main():
    parser = argparse.ArgumentParser(
        description="Check /root/Changelog for consistency")
    parser.add_argument("--version", action="version", version=__version__)
    parser.add_argument("filename", nargs='*', default=['/root/Changelog'],
                        help="file names to check (default: /root/Changelog)")
    args = parser.parse_args()
    for filename in args.filename or ['/root/Changelog']:
        try:
            with open(filename) as fp:
                check(fp, filename)
        except IOError as e:
            print("%s: %s" % (sys.argv[0], e), file=sys.stderr)


if __name__ == '__main__':
    main()
