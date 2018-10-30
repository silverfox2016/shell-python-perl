#!/bin/bash
fping 192.168.253.197  2>/dev/null|grep -c alive
