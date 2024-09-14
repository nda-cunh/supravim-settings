
srcs = [
  files('Color.vala'),
  files('main.vala'),
  files('Markdown.vala'),
  files('Options.vala'),
  files('Plugins.vala'),
  files('Themes.vala'),
  files('WikiPage.vala'),
  files('window.vala'),
]

deps = [
  dependency('gtk4'),
  dependency('libadwaita-1'),
]

executable('supravim-gui',
  srcs,
  asresources,
  c_args: '-w',
  dependencies : deps,
  install : true)
