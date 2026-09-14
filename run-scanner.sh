#!/bin/bash
export ETH_RPC_URL="https://ethereum-rpc.publicnode.com"
export ETHERSCAN_API_KEY="YYIKG5DRM15IYSAWXNJKA25TU2TD89RW3X"

# Lista de alvos: "TARGET (Vault)|TOKEN|NOME_DO_PROJETO"
TARGETS=(
  "0xAA2E727ba59b4fEa24d0Db4e49a392Fdc3E8e778|0x767FE9EDC9E0dF98E07454847909b5E959D7ca0E|Illuvium-ILV-Stake"
)

for item in "${TARGETS[@]}"; do
    IFS="|" read -r target token name <<< "$item"
    
    echo "=================================================="
    echo "🔍 Escaneando alvo V14: $name"
    echo "Vault: $target"
    echo "Token: $token"
    echo "=================================================="

    export TARGET=$target
    export TOKEN=$token

    forge test --fork-url "$ETH_RPC_URL" --etherscan-api-key "$ETHERSCAN_API_KEY" --match-contract DivinoV14 -vvv

    echo ""
    echo "✅ Varredura concluída para $name!"
    echo "--------------------------------------------------"
done
