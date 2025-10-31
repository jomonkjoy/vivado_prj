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
