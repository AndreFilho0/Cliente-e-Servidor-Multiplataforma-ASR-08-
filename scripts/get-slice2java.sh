#!/usr/bin/env bash
# Baixa o compilador slice2java (Ice 3.8.3) para a plataforma atual, extraindo-o
# do plugin oficial Slice Tools do ZeroC. So e necessario se voce quiser
# REGERAR os stubs Java (os stubs ja vem commitados no repositorio).
set -euo pipefail

ICE_VERSION="3.8.3"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOLS="$ROOT/tools"
JAR="$TOOLS/slice-tools.jar"
OUT="$TOOLS/slice2java"
URL="https://plugins.gradle.org/m2/com/zeroc/slice-tools/${ICE_VERSION}/slice-tools-${ICE_VERSION}.jar"

mkdir -p "$TOOLS"

# Detecta plataforma -> pasta dentro do jar (resources/<plat>/slice2java)
os="$(uname -s)"; arch="$(uname -m)"
case "$os-$arch" in
  Darwin-arm64)          plat="macos-arm64" ;;
  Darwin-x86_64)         plat="macos-x64" ;;
  Linux-aarch64|Linux-arm64) plat="linux-arm64" ;;
  Linux-x86_64)          plat="linux-x64" ;;
  *) echo "Plataforma nao suportada: $os-$arch" >&2; exit 1 ;;
esac

echo ">> Plataforma detectada: $plat"
if [ ! -f "$JAR" ]; then
  echo ">> Baixando plugin Slice Tools..."
  curl -fSL "$URL" -o "$JAR"
fi

echo ">> Extraindo resources/$plat/slice2java ..."
# unzip -p escreve o binario extraido em stdout
unzip -p "$JAR" "resources/$plat/slice2java" > "$OUT"
chmod +x "$OUT"
echo ">> Pronto: $OUT"
"$OUT" --version
