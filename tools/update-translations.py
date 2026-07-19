#!/usr/bin/env python3
"""Met à jour les catalogues de traduction (po/supravim-gui.pot et po/*.po).

xgettext ne connaît pas le format Blueprint. Comme les .blp utilisent la même
syntaxe _("...") que le C, ils sont extraits dans une seconde passe en
--language=C, puis fusionnés avec les chaînes des sources Vala.

Usage: python3 tools/update-translations.py
"""

import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
PO_DIR = os.path.join(ROOT, 'po')
POT = os.path.join(PO_DIR, 'supravim-gui.pot')

PACKAGE = 'supravim-gui'
VERSION = '1.29'
BUGS_ADDRESS = 'nathan.dacunha.nd@gmail.com'

COMMON = [
    '--from-code=UTF-8',
    '--keyword=_',
    '--keyword=N_',
    '--add-comments',
    '--package-name=' + PACKAGE,
    '--package-version=' + VERSION,
    '--msgid-bugs-address=' + BUGS_ADDRESS,
    '--copyright-holder=SupraVim',
]


def sources(extension):
    out = []
    for base in ('src', 'ui'):
        for dirpath, _dirs, names in os.walk(os.path.join(ROOT, base)):
            for name in sorted(names):
                if name.endswith(extension):
                    path = os.path.join(dirpath, name)
                    rel = os.path.relpath(path, ROOT)
                    with open(path, encoding='utf-8') as fp:
                        if '_("' in fp.read():
                            out.append(rel)
    return sorted(out)


def run(cmd):
    result = subprocess.run(cmd, cwd=ROOT)
    if result.returncode != 0:
        raise SystemExit('échec: %s' % ' '.join(cmd))


def extract(files, output, language=None):
    cmd = ['xgettext'] + COMMON
    if language:
        cmd.append('--language=' + language)
    cmd += ['-o', output] + files
    run(cmd)


def main():
    vala = sources('.vala')
    blp = sources('.blp')
    print('%d sources Vala, %d Blueprint' % (len(vala), len(blp)))

    tmp = tempfile.mkdtemp()
    vala_pot = os.path.join(tmp, 'vala.pot')
    blp_pot = os.path.join(tmp, 'blp.pot')

    extract(vala, vala_pot)
    extract(blp, blp_pot, language='C')

    run(['msgcat', '--use-first', '-o', os.path.relpath(POT, ROOT), vala_pot, blp_pot])
    print('%s régénéré' % os.path.relpath(POT, ROOT))

    for name in sorted(os.listdir(PO_DIR)):
        if not name.endswith('.po'):
            continue
        rel = os.path.join('po', name)
        run(['msgmerge', '--quiet', '--update', '--backup=none', rel,
             os.path.relpath(POT, ROOT)])
        stats = subprocess.run(['msgfmt', '--statistics', '-o', os.devnull, rel],
                               cwd=ROOT, capture_output=True, text=True)
        sys.stdout.write('%s : %s' % (rel, stats.stderr))


if __name__ == '__main__':
    main()
