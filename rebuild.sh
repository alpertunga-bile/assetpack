#!/bin/bash

if [ -d "build/" ]; then
    rm -rf build
fi

cmake -B build/

cmake --build build -j8
