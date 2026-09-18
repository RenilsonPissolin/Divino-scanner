#!/bin/bash
echo "=== DIVINO SCANNER V3 - FINAL ==="
forge test --match-contract DivinoScannerPrecisionV3 --match-test testV3_PrecisionLoss -vvv
echo "Se aparecer [CRITICAL] 0 shares, o vault é vulnerável!"
