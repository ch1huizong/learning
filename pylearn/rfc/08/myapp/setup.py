#! /usr/bin/env python
# -*- coding:UTF-8 -*-

from distutils.core import setup

setup(name="spam",
        version = "1.0",
        py_modules = ["gen"],  #模块
        packages = ["spampkg"],   #包
        scripts = ["runspam.py"]  #主脚本
        )
