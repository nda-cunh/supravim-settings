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

deps = [
  dependency('gtk4'),
  dependency('libadwaita-1'),
  dependency('gtk4-markdown')
]

executable('supravim-gui',
  srcs,
  asresources,
  c_args: '-w',
  dependencies : [deps],
  install : true
)
