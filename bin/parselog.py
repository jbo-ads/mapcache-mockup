#!/usr/bin/env python3

from math import sqrt
import sys
import re


# Handle command line arguments
import argparse
p = argparse.ArgumentParser(description='Parse Apache log files for time profiling')
p.add_argument("--nolog", dest='log', action='store_false',
               help='Don\'t display log entries')
p.add_argument("--log", dest='log', action='store_true',
               help='Display log entries (default)')
p.set_defaults(log=True,stat=False)
args = p.parse_args()

# Pattern for localizing relevant information from an Apache log line
linepattern = ( '\[(.*?) (.*?) (.*?) (.*?):(.*?):(.*?) (.*?)\] '
                + '\[(.*?)\] '
                + '\[(.*?) (.*?):(.*?) (.*?)\] '
                + '(.*?): '
                + '(.*?) (MOCKUP) (.*?) ([^ ,\n]*)( )?([^ ,\n]*)?(, .*?)?' )


statistics = {
 'f'  : 'mapcache_handler',  # Function name
 'n'  : 0,                   # Number of samples
 's'  : 0,                   # Sum of samples
 's2' : 0,                   # Sum of sample squares
 'min': 86400000000,         # Minimum of samples
 'max': 0,                   # Maximum of samples
}


# Collect Apache log data and arrange them by thread
exid = {}
logbythread = {}
for line in sys.stdin:
  try:
    s = re.match(linepattern,line).groups()
  except AttributeError:
    continue
  log = {
    'time': float(s[5])+60*(int(s[4])+60*int(s[3])),
    'ptid': s[9]+':'+s[11],
    'type': s[15],
    'func': s[16],
    'sub': s[18],
  }
  if ( log['type'] == 'BEGIN'
       and log['func'] in [ 'mapcache_handler', '_thread_get_tile', '_thread_get_subtile' ] ):
    try:
      exid[log['ptid']] = exid[log['ptid']] + 1
    except KeyError:
      exid[log['ptid']] = 0
  log['thrkey'] = log['ptid']+':'+str(exid[log['ptid']])
  try:
    logbythread[log['thrkey']].append(log)
  except KeyError:
    logbythread[log['thrkey']] = [ log ]
  if log['type'] == 'END':
    l = [ l for l in logbythread[log['thrkey']]
             if l['type'] == 'BEGIN' and l['func'] == log['func'] ][0]
    log['delta_us'] = int(.5+1e6*(log['time']-l['time']))
    l['delta_us'] = log['delta_us']
    l['type'] = '*BEGIN*'
    log['type'] = '*END*'
  if log['func'] == statistics['f'] and log['type'] == '*END*':
    sample = log['delta_us']
    statistics['n']  = statistics['n']  + 1
    statistics['s']  = statistics['s']  + sample
    statistics['s2'] = statistics['s2'] + sample*sample
    if sample > statistics['max']: statistics['max'] = sample
    if sample < statistics['min']: statistics['min'] = sample
  if ( log['type'] == '*END*'
       and log['func'] in [ 'mapcache_handler', '_thread_get_tile', '_thread_get_subtile' ] ):
    thread = log['thrkey']
    # Display log by thread with call graph indentation
    if args.log:
      disptype = { '*BEGIN*': 'BEGIN:', '*END*': 'END..:' }
      indent = 1
      seq = logbythread[thread]
      print('Thread #'+thread+':')
      for log in seq:
        if log['type'] == '*END*': indent = indent - 1
        dl = { disptype[log['type']]+log['func']: log['delta_us'] }
        print('  '*indent,dl)
        if log['type'] == '*BEGIN*': indent = indent + 1
      print()
    del logbythread[thread]


# Display statistics
if args.stat:
  mean = statistics['s'] / statistics['n']
  variance = statistics['s2'] / statistics['n'] - mean*mean
  stddev = sqrt(abs(variance))
  statistics['mean'] = mean
  statistics['variance'] = variance
  statistics['stddev'] = stddev
  print(statistics)
