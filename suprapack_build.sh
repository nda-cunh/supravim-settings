#!/bin/bash

git clone https://gitlab.com/nda-cunh/SupraVim.wiki.git $MESON_INSTALL_DESTDIR_PREFIX/share/supravim-gui --depth 1
pushd ..
suprapack build $MESON_INSTALL_DESTDIR_PREFIX
popd
