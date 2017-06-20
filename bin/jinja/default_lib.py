#! /usr/bin/env python
from jinja2 import Environment

env = Environment()

for libname in ["filters", "tests", "globals"]: #, "functions", "tags", "operators"]:
  print("%s:" % libname)
  library = getattr(env, libname)
  keys = library.keys()
  keys.sort()

  for feature in keys:
    print("  %s" % feature)
  print
