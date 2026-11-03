#!/usr/bin/env python3
# -*- coding: utf-8 -*-
r"""
uniFAR: copy uniFAR sources from the unIDE repository into the standalone
diakin/uniFAR repository.

The file list is built automatically:
  - uniFAR/uniFAR.lpr and every unit it uses, recursively (uses clauses),
    searched in uniFAR\, uniFAR\vcl\ and the unIDE root - the same paths as
    -Fuvcl -Fu.. in uniFAR.lpi;
  - include files ({$I name}) and resources ({$R name.res}) of those units;
  - fixed extras from EXTRA_PATHS below (schemes, 7-Zip, fonts, icon...).

The layout of the unIDE repository is kept as is (UnFar.pas in the root,
uniFAR.lpr in uniFAR\), so uniFAR.lpi and the build command do not change.

Files copied by the previous run are listed in .unide-sync in the target
repository. A file from that list that is no longer needed is deleted.
Other files of the target (README.md, .github, legacy) are not touched.

Usage:
  python sync_unifar.py <unIDE folder> <uniFAR folder>   - copy
  python sync_unifar.py <unIDE folder> --list            - only print the list
"""

import os
import re
import shutil
import subprocess
import sys

# Project file of uniFAR inside unIDE
MAIN_PROGRAM = 'uniFAR/uniFAR.lpr'
# Unit search paths, as in uniFAR.lpi (OtherUnitFiles = vcl;..)
UNIT_DIRS = ['uniFAR', 'uniFAR/vcl', '.']
# Copied always: folders are copied with all tracked files inside
EXTRA_PATHS = [
    '.gitattributes',          # cp1251 <-> UTF-8 rules for .pas/.clr/.ini
    'LICENSE',
    'uniFAR/uniFAR.lpi',
    'uniFAR/res',              # icon and make_icon.py
    'uniFAR/sync',             # this script (for a local run from uniFAR too)
    'schemes',                 # highlight schemes for the F4 editor
    'fonts',                   # source of farfont.res (make_farfont.py)
    'tools/7zip',              # 7z.exe / 7z.dll for archives
]
# Manifest of synced files in the target repository
MANIFEST_NAME = '.unide-sync'
SOURCE_ENCODING = 'cp1251'

RE_INCLUDE = re.compile(r'\{\$(?:I|INCLUDE)\s+([^}%][^}]*)\}', re.I)
RE_RESOURCE = re.compile(r'\{\$(?:R|RESOURCE)\s+([^}*][^}]*)\}', re.I)
RE_COMMENTS = re.compile(r'\{[^}]*\}|\(\*.*?\*\)|//[^\n]*', re.S)
RE_STRINGS = re.compile(r"'[^'\n]*'")
RE_USES = re.compile(r'\buses\b(.*?);', re.S | re.I)


def tracked_files(repo_dir):
    """Files tracked by git (so ignored build output is never copied)."""
    try:
        output = subprocess.run(
            ['git', '-C', repo_dir, '-c', 'core.quotepath=off', 'ls-files',
             '-z'], check=True, capture_output=True).stdout
        names = [name for name in output.decode('utf-8').split('\0') if name]
        if names:
            return set(names)
    except (OSError, subprocess.CalledProcessError):
        pass
    # Not a git clone - take every file
    result = set()
    for dir_path, dir_names, file_names in os.walk(repo_dir):
        dir_names[:] = [name for name in dir_names if name != '.git']
        for name in file_names:
            full = os.path.join(dir_path, name)
            result.add(os.path.relpath(full, repo_dir).replace(os.sep, '/'))
    return result


class SourceIndex:
    """Case-insensitive lookup of tracked files (Windows file names)."""

    def __init__(self, files):
        self.by_lower = {name.lower(): name for name in files}

    def get(self, rel_path):
        rel_path = os.path.normpath(rel_path).replace(os.sep, '/')
        return self.by_lower.get(rel_path.lower())

    def find_unit(self, unit_name):
        for unit_dir in UNIT_DIRS:
            for ext in ('.pas', '.pp'):
                found = self.get(os.path.join(unit_dir, unit_name + ext))
                if found:
                    return found
        return None


def read_source(full_path):
    with open(full_path, 'rb') as stream:
        return stream.read().decode(SOURCE_ENCODING, errors='replace')


def collect_sources(src_root, index):
    """MAIN_PROGRAM and everything it needs to compile."""
    needed = set()
    queue = [MAIN_PROGRAM]
    unknown_units = set()
    while queue:
        rel_path = queue.pop()
        if rel_path in needed:
            continue
        needed.add(rel_path)
        text = read_source(os.path.join(src_root, rel_path))
        base_dir = os.path.dirname(rel_path)
        # {$I} and {$R} are searched next to the unit, then in unit paths
        for regex in (RE_INCLUDE, RE_RESOURCE):
            for match in regex.finditer(text):
                ref_name = match.group(1).strip().strip("'").replace('\\', '/')
                for search_dir in [base_dir] + UNIT_DIRS:
                    found = index.get(os.path.join(search_dir, ref_name))
                    if found:
                        queue.append(found)
                        break
        code = RE_COMMENTS.sub(' ', RE_STRINGS.sub("''", text))
        for uses_block in RE_USES.findall(code):
            for item in uses_block.split(','):
                words = item.split()
                if not words:
                    continue
                found = index.find_unit(words[0])
                if found:
                    queue.append(found)
                else:
                    unknown_units.add(words[0])
    return needed, unknown_units


def build_file_list(src_root):
    files = tracked_files(src_root)
    index = SourceIndex(files)
    needed, unknown_units = collect_sources(src_root, index)
    for extra in EXTRA_PATHS:
        prefix = extra.rstrip('/') + '/'
        matched = [name for name in files
                   if name == extra or name.startswith(prefix)]
        if not matched:
            print('warning: not found in unIDE: ' + extra)
        needed.update(matched)
    # .res/.ico/.py found via {$R} are files, .pas sources too: all tracked
    return sorted(needed), sorted(unknown_units)


def read_manifest(dst_root):
    path = os.path.join(dst_root, MANIFEST_NAME)
    if not os.path.exists(path):
        return []
    with open(path, encoding='utf-8') as stream:
        return [line.rstrip('\n') for line in stream
                if line.strip() and not line.startswith('#')]


def write_manifest(dst_root, file_list, source_commit):
    with open(os.path.join(dst_root, MANIFEST_NAME), 'w', encoding='utf-8',
              newline='\n') as stream:
        stream.write('# Files copied from diakin/unIDE by '
                     'uniFAR/sync/sync_unifar.py - edit them in unIDE.\n')
        stream.write('# unIDE commit: %s\n' % source_commit)
        for name in file_list:
            stream.write(name + '\n')


def source_commit_of(src_root):
    try:
        return subprocess.run(['git', '-C', src_root, 'rev-parse', 'HEAD'],
                              check=True, capture_output=True,
                              text=True).stdout.strip()
    except (OSError, subprocess.CalledProcessError):
        return 'unknown'


def remove_empty_dirs(dst_root, rel_path):
    dir_path = os.path.dirname(os.path.join(dst_root, rel_path))
    while os.path.abspath(dir_path) != os.path.abspath(dst_root):
        if os.path.isdir(dir_path) and not os.listdir(dir_path):
            os.rmdir(dir_path)
            dir_path = os.path.dirname(dir_path)
        else:
            break


def sync(src_root, dst_root):
    file_list, unknown_units = build_file_list(src_root)
    old_list = read_manifest(dst_root)
    copied = 0
    for rel_path in file_list:
        src_path = os.path.join(src_root, rel_path)
        dst_path = os.path.join(dst_root, rel_path)
        os.makedirs(os.path.dirname(dst_path) or dst_root, exist_ok=True)
        # Byte copy: the working tree of unIDE is cp1251 + CRLF (.gitattributes)
        same = (os.path.exists(dst_path) and
                os.path.getsize(dst_path) == os.path.getsize(src_path) and
                open(dst_path, 'rb').read() == open(src_path, 'rb').read())
        if not same:
            shutil.copyfile(src_path, dst_path)
            copied += 1
    removed = 0
    new_set = set(file_list)
    for rel_path in old_list:
        if rel_path not in new_set:
            dst_path = os.path.join(dst_root, rel_path)
            if os.path.isfile(dst_path):
                os.remove(dst_path)
                remove_empty_dirs(dst_root, rel_path)
                removed += 1
    write_manifest(dst_root, file_list, source_commit_of(src_root))
    print('uniFAR sync: %d files, %d copied, %d removed' %
          (len(file_list), copied, removed))
    print('units outside unIDE (RTL/FPC): ' + ' '.join(unknown_units))


def main(args):
    if len(args) != 2:
        print(__doc__)
        return 2
    src_root = os.path.abspath(args[0])
    if args[1] == '--list':
        file_list, unknown_units = build_file_list(src_root)
        for name in file_list:
            print(name)
        print('units outside unIDE (RTL/FPC): ' + ' '.join(unknown_units))
        return 0
    dst_root = os.path.abspath(args[1])
    if os.path.abspath(dst_root) == src_root:
        print('error: target is the unIDE folder itself')
        return 2
    sync(src_root, dst_root)
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
