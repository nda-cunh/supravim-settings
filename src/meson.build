srcs = files(
  'main.vala',
  'Window.vala'
)

subdir('homepage')
subdir('options')
subdir('plugins')
subdir('popup')
subdir('wiki')
subdir('utils')

cc = meson.get_compiler('c')

deps = [
  dependency('gtk4'),
  dependency('libadwaita-1'),
  dependency('gtk4-markdown'),
  cc.find_library('m'),
]

executable('supravim-gui',
  srcs,
  asresources,
  c_args: '-w',
  vala_args: supravim_vala_args,
  dependencies: [deps, supravim_dep],
  install: true
)
