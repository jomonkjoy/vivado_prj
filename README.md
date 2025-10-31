# Vivado Environment Setup

This guide describes how to configure your shell environment to use **Xilinx Vivado 2019.2** tools.

---

## 🧩 Environment Variables

Add the following lines to your `~/.bashrc` or `~/.bash_profile` file to set up Vivado paths permanently:

```bash
# Vivado Environment Setup
export VIVADO_HOME=/tools/Xilinx/Vivado
export VIVADO_VER=2019.2
export VIVADO_TOOL=${VIVADO_HOME}/${VIVADO_VER}/bin
export PATH=${VIVADO_TOOL}:$PATH
```
OR

```bash
export VIVADO_HOME=/tools/Xilinx
export VIVADO_VER=2025.1
export VIVADO_TOOL=${VIVADO_HOME}/${VIVADO_VER}/Vivado/bin
export PATH=${VIVADO_TOOL}:$PATH
```

## 🧩 Root Cause

Vivado 2019.2 was built against ncurses 5. You can create a symbolic link from .6 to .5 safely — Vivado works fine with it.

```
sudo ln -s /usr/lib64/libtinfo.so.6 /usr/lib64/libtinfo.so.5
sudo ln -s /lib/x86_64-linux-gnu/libtinfo.so.6 /lib/x86_64-linux-gnu/libtinfo.so.5
```
