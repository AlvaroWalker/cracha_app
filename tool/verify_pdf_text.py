#!/usr/bin/env python
"""Extrai o texto do PDF vetorial e compara com o layout esperado.

Rodar depois de `flutter test test/badge_vector_text_test.dart`, que grava
`test/_out_vec.pdf`.

O bug original (texto sumindo) só aparecia no PDF final — o layout em Dart
passava e o `dart_pdf` descartava. Então a verificação precisa abrir o PDF e
ler o texto de verdade, não confiar no assert do layout.

Uso:  python tool/verify_pdf_text.py
Exit 1 se qualquer palavra esperada faltar.
"""
import sys
import unicodedata

import pymupdf

# PDFs gerados por test/badge_vector_text_test.dart
PDFS = {
    "Pedro Paulo": "test/_out_vec_pedro.pdf",
    "caso extremo": "test/_out_vec_max.pdf",
}

# Palavras que o gerador vetorial antigo PERDIA: a secretaria do Pedro
# inteira era descartada e "ESTRATEGICO" sumia no caso extremo.
ESPERADO = {
    "Pedro Paulo": [
        "PEDRO", "PAULO", "SOUSA", "MARINS",
        "CONCILIADOR", "DEFESA", "CONSUMIDOR",
        "SECRETARIA", "INTEGRADA", "SEGURANCA", "PUBLICA",
    ],
    "caso extremo": [
        "MAXIMILIANO", "AUGUSTO", "FERREIRA", "ALMEIDA", "SOBRINHO",
        "DIRETOR", "GERAL", "ADMINISTRACAO", "FINANCEIRA", "ORCAMENTARIA",
        "SECRETARIA", "PLANEJAMENTO", "ESTRATEGICO",
    ],
}


def normalizar(s: str) -> str:
    """Compara sem acento e sem caixa — o PDF pode diferir em kerning."""
    s = unicodedata.normalize("NFKD", s)
    s = "".join(c for c in s if not unicodedata.combining(c))
    return " ".join(s.upper().split())


def verificar(rotulo: str, caminho: str) -> list[str]:
    """Retorna a lista de falhas de um PDF."""
    falhas = []
    try:
        doc = pymupdf.open(caminho)
    except FileNotFoundError:
        print(f"ERRO: {caminho} nao existe. Rode antes:")
        print("  flutter test test/badge_vector_text_test.dart")
        return ["arquivo ausente"]

    texto = normalizar(doc[0].get_text())
    doc.close()

    print(f"\n=== {rotulo} ({caminho}) ===")
    print(texto if texto.strip() else "(VAZIO)")

    if not texto.strip():
        falhas.append("sem texto extraivel")
        return falhas

    ausentes = [p for p in ESPERADO[rotulo] if normalizar(p) not in texto]
    if ausentes:
        falhas.append(f"faltando: {', '.join(ausentes)}")

    # Palavra orfa de verdade: linha com UMA palavra de <= 2 caracteres.
    for linha in texto.split("\n"):
        limpa = linha.strip()
        if limpa and len(limpa.split()) == 1 and len(limpa) <= 2:
            falhas.append(f"palavra orfa isolada: '{limpa}'")

    return falhas


def main() -> int:
    problemas = []
    for rotulo, caminho in PDFS.items():
        for f in verificar(rotulo, caminho):
            print(f"  FALHOU: {f}")
            problemas.append((rotulo, f))

    if problemas:
        print(f"\n{len(problemas)} problema(s). Texto perdido no PDF.")
        return 1

    print("\nOK: todas as palavras esperadas estao nos PDFs, sem orfa.")
    return 0


if __name__ == "__main__":
    sys.exit(main())