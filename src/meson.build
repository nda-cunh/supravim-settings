
srcs = [
  files('main.vala',
  'Color.vala',
  'Options.vala',
  'OptionsRow.vala',
  'OptionsNode.vala',
  'Plugins.vala',
  'Themes.vala',
  'WikiPage.vala',
  'window.vala',
  'UpdateWindow.vala',
  'ClearCacheWindow.vala',
  'UninstallWindow.vala',
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
