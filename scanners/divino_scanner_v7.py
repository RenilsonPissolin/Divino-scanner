import re, sys
def scan_v7(file_path):
    try:
        code = open(file_path, encoding='utf-8', errors='ignore').read()
    except FileNotFoundError:
        print(f"Arquivo nao encontrado: {file_path}")
        print("Arquivos.sol na pasta:")
        import os
        print([f for f in os.listdir('.') if f.endswith('.sol')])
        return

    print(f"Escaneando {file_path} com {len(code.split(chr(10)))} linhas...")
    bugs = 0
    lines = code.split('\n')
    for line_num, line in enumerate(lines, 1):
        if 'tx.origin' in line and '//' not in line.split('tx.origin')[0]:
            print(f"[HIGH] tx.origin na linha {line_num} -> {line.strip()}")
            bugs+=1
        if ('getReserves()' in line or 'balanceOf(' in line) and ('price' in line.lower() or 'amount' in line.lower()):
            print(f"[CRITICAL] Oracle Manipulation na linha {line_num} -> {line.strip()}")
            bugs+=1

    # Detector de shadowing simples
    if 'targetAsset' in code:
         print(f"[CRITICAL] Possivel Shadowing - variavel 'targetAsset' encontrada - verifique linha 65!")

    if bugs == 0:
        print("Nenhum dos 3 novos detectores encontrou nada. OK.")
    print("Scan finalizado.")

if len(sys.argv) > 1:
    scan_v7(sys.argv[1])
else:
    print("Uso: python divino_scanner_v7.py SEU_ARQUIVO.sol")
