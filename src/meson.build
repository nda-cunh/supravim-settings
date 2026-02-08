
srcs = [
  files(
    'main.vala',
  'Color.vala',
  'DialogPopup.vala',
  'HomePage.vala',
  'Options.vala',
  'OptionsNode.vala',
  'OptionsRow.vala',
  'PluginExternalRow.vala',
  'PluginsDownloadWindow.vala',
  'PluginsPage.vala',
  'PluginsRow.vala',
  'SupraParser.vala',
  'ThemeButton.vala',
  'ThemeGrid.vala',
  'ThemeInit.vala',
  'Themes.vala',
  'WikiPage.vala',
  'Window.vala',
  'WindowClearCache.vala',
  'WindowUninstall.vala',
  'WindowUpdate.vala',
  'DataColor.vala',
  'Utils.vala'
  ),
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
