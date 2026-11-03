#!/bin/sh
# ---------------------------------------------------------------------------
#  unIDE: сборка под Linux и папка поставки (этап 7 плана переноса)
#
#  Запуск на Linux (x86_64) с установленным Lazarus 3.x (lazbuild, fpc):
#    sh lazarus/linux/build_linux.sh            сборка + папка + инструменты
#    sh lazarus/linux/build_linux.sh --no-tools без скачивания 7zz и arduino-cli
#    sh lazarus/linux/build_linux.sh --no-build только папка из готового exe
#
#  Переменные: LAZBUILD, FPC (пути к программам), LAZBUILD_OPTS (ключи
#  lazbuild, например --lazarusdir=...), OUT (папка поставки, по умолчанию
#  <репозиторий>/dist/unide-linux64).
#
#  Шаги:
#    1. подготовка исходников: lazprep_cli (LazPrep.pas, то же, что
#       Utils - "Lazarus: prepare sources" в unIDE) -> <репозиторий>/laz;
#    2. lazbuild --bm=Linux64 laz/SyntaxHLClaude.lpi
#       -> Output/SyntaxHLClaude_linux64;
#    3. папка поставки: программа, IDE.clr, schemes, designer, справка
#       (*_ref), RqLcl, LICENSE; <программа>.build.txt - ветка и коммит для
#       заголовка окна;
#    4. tools: свои 7zz (7-Zip) и arduino-cli, как tools\7zip в Windows.
#       Версии и SHA-256 закреплены ниже; не совпало - файл не ставится.
#
#  Что программа берёт из системы - в README_linux.txt папки поставки.
# ---------------------------------------------------------------------------
set -eu

SEVENZIP_VERSION=26.04
SEVENZIP_URL=https://github.com/ip7z/7zip/releases/download/26.04/7z2604-linux-x64.tar.xz
SEVENZIP_SHA256=fc0327ba27e89bd086cf426dff17d77de582953cdbbc10a6576540a06853ffcd
ARDUINO_CLI_VERSION=1.5.1
ARDUINO_CLI_URL=https://github.com/arduino/arduino-cli/releases/download/v1.5.1/arduino-cli_1.5.1_Linux_64bit.tar.gz
# из 1.5.1-checksums.txt того же выпуска
ARDUINO_CLI_SHA256=28a8e119c498a25607821c36cb2dc49e8463941b261a0d99091baa7bc692dd2b

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
OUT=${OUT:-$ROOT/dist/unide-linux64}
LAZBUILD=${LAZBUILD:-lazbuild}
LAZBUILD_OPTS=${LAZBUILD_OPTS:-}
FPC=${FPC:-fpc}
EXE_NAME=SyntaxHLClaude
BUILT_EXE=$ROOT/Output/SyntaxHLClaude_linux64

WITH_BUILD=1
WITH_TOOLS=1
for ARG in "$@"; do
  case "$ARG" in
    --no-tools) WITH_TOOLS=0 ;;
    --no-build) WITH_BUILD=0 ;;
    *) echo "неизвестный параметр: $ARG" >&2; exit 2 ;;
  esac
done

fail() {
  echo "ОШИБКА: $*" >&2
  exit 1
}

need() {
  command -v "$1" >/dev/null 2>&1 || fail "нет программы $1 ($2)"
}

[ "$(uname -s)" = Linux ] || fail "скрипт для Linux"
[ "$(uname -m)" = x86_64 ] || fail "сборка Linux64 - только x86_64, здесь $(uname -m)"
need iconv "пакет libc-bin"

# --- 1-2. Сборка ----------------------------------------------------------
if [ "$WITH_BUILD" = 1 ]; then
  need "$LAZBUILD" "Lazarus, или переменная LAZBUILD"
  need "$FPC" "Free Pascal, или переменная FPC"
  TMP_PREP=$(mktemp -d)
  trap 'rm -rf "$TMP_PREP"' EXIT
  echo "== 1. подготовка исходников -> $ROOT/laz"
  iconv -f CP1251 -t UTF-8 "$ROOT/LazPrep.pas" > "$TMP_PREP/LazPrep.pas"
  "$FPC" -Mdelphi -O1 -FU"$TMP_PREP" -FE"$TMP_PREP" -Fu"$TMP_PREP" \
    "$ROOT/lazarus/linux/lazprep_cli.lpr" > "$TMP_PREP/fpc.log" 2>&1 ||
    { cat "$TMP_PREP/fpc.log"; fail "lazprep_cli не собран"; }
  "$TMP_PREP/lazprep_cli" "$ROOT" "$ROOT/laz" | tail -n 5
  echo "== 2. lazbuild --bm=Linux64"
  "$LAZBUILD" $LAZBUILD_OPTS --bm=Linux64 "$ROOT/laz/SyntaxHLClaude.lpi" > "$TMP_PREP/lazbuild.log" 2>&1 ||
    { tail -n 40 "$TMP_PREP/lazbuild.log"; fail "lazbuild: ошибка сборки"; }
  grep -E "Linking|lines compiled" "$TMP_PREP/lazbuild.log" | tail -n 2
fi
[ -x "$BUILT_EXE" ] || fail "нет $BUILT_EXE - сначала сборка (без --no-build)"

# --- 3. Папка поставки ----------------------------------------------------
echo "== 3. папка поставки $OUT"
rm -rf "$OUT"
mkdir -p "$OUT"
cp "$BUILT_EXE" "$OUT/$EXE_NAME"
chmod 755 "$OUT/$EXE_NAME"
cp "$ROOT/IDE.clr" "$ROOT/LICENSE" "$OUT/"
for DIR in schemes designer RqLcl rapidq_ref unide_ref fb_ref git_ref \
           qemu_ref rosbe_ref Arduino_Ref; do
  [ -d "$ROOT/$DIR" ] && cp -R "$ROOT/$DIR" "$OUT/"
done

# Ветка и коммит - в заголовок окна (GitInfo.GitBuildInfoShort)
if command -v git >/dev/null 2>&1 && [ -d "$ROOT/.git" ]; then
  {
    echo "build=$(date '+%d.%m.%Y %H:%M:%S')"
    echo "source=$ROOT/"
    echo "repo=$ROOT"
    echo "branch=$(git -C "$ROOT" rev-parse --abbrev-ref HEAD)"
    echo "commit=$(git -C "$ROOT" rev-parse HEAD)"
    echo "changes=$(git -C "$ROOT" status --porcelain --untracked-files=no | wc -l | tr -d ' ')"
    echo "untracked=0"
  } > "$OUT/$EXE_NAME.build.txt"
fi

cat > "$OUT/README_linux.txt" <<'EOT'
unIDE для Linux (x86_64, gtk2)

Запуск: ./SyntaxHLClaude
Настройки (editor.ini) и журналы (hang.log, crash.log) - в этой папке,
папка должна быть доступна на запись.

Из системы нужны:
  - библиотеки gtk2 (Debian/Ubuntu: libgtk2.0-0);
  - компиляторы - по проектам: fpc, fbc (FreeBASIC), wine (Delphi 7,
    RapidQ, rc.exe), git, ninja и RosBE-Unix (ReactOS);
  - qemu-system-x86 и qemu-utils - для Run Image проекта ReactOS;
  - xdg-utils - открытие файлов и ссылок в программах по умолчанию.

Свои инструменты (tools/):
  - tools/7zip/7zz - 7-Zip для архивов unIDE FAR;
  - tools/arduino-cli/arduino-cli - сборка и загрузка скетчей Arduino.
Нет их здесь - берутся из PATH.
EOT

# --- 4. Инструменты -------------------------------------------------------
fetch() {
  # fetch <адрес> <файл>
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL -o "$2" "$1"
  elif command -v wget >/dev/null 2>&1; then
    wget -q -O "$2" "$1"
  else
    fail "нет curl и wget"
  fi
}

check_sha() {
  # check_sha <файл> <sha256>
  GOT=$(sha256sum "$1" | cut -d ' ' -f 1)
  [ "$GOT" = "$2" ] || fail "SHA-256 $1: $GOT, ожидалось $2"
}

if [ "$WITH_TOOLS" = 1 ]; then
  need sha256sum "пакет coreutils"
  need tar "пакет tar"
  TMP_TOOLS=$(mktemp -d)
  echo "== 4. 7-Zip $SEVENZIP_VERSION"
  fetch "$SEVENZIP_URL" "$TMP_TOOLS/7z.tar.xz"
  check_sha "$TMP_TOOLS/7z.tar.xz" "$SEVENZIP_SHA256"
  mkdir -p "$OUT/tools/7zip"
  tar -xJf "$TMP_TOOLS/7z.tar.xz" -C "$OUT/tools/7zip" 7zz License.txt readme.txt
  chmod 755 "$OUT/tools/7zip/7zz"
  echo "== 4. arduino-cli $ARDUINO_CLI_VERSION"
  fetch "$ARDUINO_CLI_URL" "$TMP_TOOLS/arduino-cli.tar.gz"
  check_sha "$TMP_TOOLS/arduino-cli.tar.gz" "$ARDUINO_CLI_SHA256"
  mkdir -p "$OUT/tools/arduino-cli"
  tar -xzf "$TMP_TOOLS/arduino-cli.tar.gz" -C "$OUT/tools/arduino-cli" arduino-cli LICENSE.txt
  chmod 755 "$OUT/tools/arduino-cli/arduino-cli"
  rm -rf "$TMP_TOOLS"
fi

# --- Проверка библиотек ---------------------------------------------------
if command -v ldd >/dev/null 2>&1; then
  MISSING=$(ldd "$OUT/$EXE_NAME" 2>/dev/null | grep "not found" || true)
  if [ -n "$MISSING" ]; then
    echo "ВНИМАНИЕ: нет библиотек:"
    echo "$MISSING"
  fi
fi
echo "Готово: $OUT ($(du -sh "$OUT" | cut -f 1))"
