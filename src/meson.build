
srcs = [
  files('main.vala',
  'Window.vala',
  'WindowUpdate.vala',
  'WindowClearCache.vala',
  'WindowUninstall.vala',
  'Options.vala',
  'OptionsRow.vala',
  'OptionsNode.vala',
  'PluginsPage.vala',
  'PluginsRow.vala',
  'PluginsDownloadWindow.vala',
  'Color.vala',
  'WikiPage.vala',
  'Themes.vala',
  'ThemeGrid.vala',
  'ThemeButton.vala',
  'ThemeInit.vala',
  'DataColor.vala',
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
