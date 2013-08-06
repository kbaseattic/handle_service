#!/usr/bin/env python

from distutils.core import setup
import datastore

setup(name='datastore',
      version=datastore.__version__,
      author=datastore.__author__,
      license=datastore.__licence__,
      packages=['datastore'],
     )