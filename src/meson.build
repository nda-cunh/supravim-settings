
srcs = [
  files('Color.vala',
  'main.vala',
  'Options.vala',
  'Plugins.vala',
  'Themes.vala',
  'WikiPage.vala',
  'window.vala',
  'Utils.vala'),
]

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
  install : true)
