#!/usr/bin/env bash

# Run this file if you want to update submodules.
git submodule update --init --recursive
git submodule update --remote --merge --recursive
