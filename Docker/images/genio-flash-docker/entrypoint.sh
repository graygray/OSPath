#!/usr/bin/env bash
set -e

echo "========================================"
echo " Genio Flash Container"
echo "========================================"
echo "[INFO] python3: $(python3 --version 2>/dev/null || true)"
echo "[INFO] pip3   : $(pip3 --version 2>/dev/null || true)"
echo "[INFO] fastboot:"
fastboot --version || true
echo "[INFO] genio-config:"
genio-config || true
echo "========================================"

exec "$@"