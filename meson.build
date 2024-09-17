project('supravim-gui', ['c', 'vala'],
  version : '1.02',
  default_options : ['warning_level=3', 'optimization=2'])

gnome = import('gnome')

blueprints = custom_target('blueprints',
  input: files('window.blp'),
  output: 'ui',
  command: [find_program('blueprint-compiler'), 'batch-compile', '@OUTPUT@', '@CURRENT_SOURCE_DIR@', '@INPUT@'],
)

asresources = gnome.compile_resources(
    'as-resources', 'gresource.xml',
    dependencies: [blueprints],
    source_dir: 'ui',
    c_name: 'as'
)

subdir('src')
