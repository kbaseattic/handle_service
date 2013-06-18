#!/usr/bin/env python

from distutils.core import setup
import adm

setup(name='adm',
      version=adm.__version__,
      author=adm.__author__,
      license=adm.__licence__,
      packages=['adm'],
     )