#!/usr/bin/env python3
"""
Script para baixar animações Lottie gratuitas do LottieFiles.com
Execute: python download_lottie_icons.py
"""

import urllib.request
import json
import os

# Diretório de destino
LOTTIE_DIR = "assets/lottie"

# URLs de animações Lottie gratuitas (exemplos públicos)
# Nota: Estas são URLs de exemplo. Você pode substituir por URLs específicas do LottieFiles.com
LOTTIE_URLS = {
    "home.json": "https://assets10.lottiefiles.com/packages/lf20_khzniaya.json",
    "credit_card.json": "https://assets2.lottiefiles.com/packages/lf20_tll0j4bb.json",
    "qr_scan.json": "https://assets9.lottiefiles.com/packages/lf20_uu3x2ijq.json",
    "analytics.json": "https://assets4.lottiefiles.com/packages/lf20_qp1q7mct.json",
    "profile.json": "https://assets1.lottiefiles.com/packages/lf20_x62chJ.json",
    "bitcoin.json": "https://assets5.lottiefiles.com/packages/lf20_9wpyhdzo.json",
    "trending_up.json": "https://assets3.lottiefiles.com/packages/lf20_w51pcehl.json",
    "pie_chart.json": "https://assets7.lottiefiles.com/packages/lf20_qp1q7mct.json",
    "bar_chart.json": "https://assets6.lottiefiles.com/packages/lf20_9wpyhdzo.json",
    "freeze.json": "https://assets8.lottiefiles.com/packages/lf20_uu3x2ijq.json",
    "lock.json": "https://assets2.lottiefiles.com/packages/lf20_w51pcehl.json",
    "speed.json": "https://assets4.lottiefiles.com/packages/lf20_khzniaya.json",
    "settings.json": "https://assets1.lottiefiles.com/packages/lf20_tll0j4bb.json",
}

def download_lottie(url, filename):
    """Baixa um arquivo Lottie JSON"""
    try:
        print(f"Baixando {filename}...")
        filepath = os.path.join(LOTTIE_DIR, filename)
        urllib.request.urlretrieve(url, filepath)
        print(f"✓ {filename} baixado com sucesso!")
        return True
    except Exception as e:
        print(f"✗ Erro ao baixar {filename}: {e}")
        return False

def main():
    # Criar diretório se não existir
    os.makedirs(LOTTIE_DIR, exist_ok=True)
    
    print("=" * 50)
    print("Download de Animações Lottie")
    print("=" * 50)
    print()
    
    success_count = 0
    total_count = len(LOTTIE_URLS)
    
    for filename, url in LOTTIE_URLS.items():
        if download_lottie(url, filename):
            success_count += 1
    
    print()
    print("=" * 50)
    print(f"Download concluído: {success_count}/{total_count} arquivos")
    print("=" * 50)
    
    if success_count == total_count:
        print("\n✓ Todos os arquivos foram baixados com sucesso!")
        print("Execute 'flutter pub get' e reinicie o app para ver as animações.")
    else:
        print(f"\n⚠ {total_count - success_count} arquivo(s) falharam.")
        print("Você pode baixar manualmente do LottieFiles.com")

if __name__ == "__main__":
    main()
