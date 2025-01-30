project('supravim-gui', ['c', 'vala'],
  version : '1.11',
  default_options : ['warning_level=3', 'optimization=2'])

gnome = import('gnome')

blueprints = custom_target('blueprints',
  input: files('window.blp', 'wiki.blp'),
  output: 'ui',
  command: [find_program('blueprint-compiler'), 'batch-compile', '@OUTPUT@', '@CURRENT_SOURCE_DIR@', '@INPUT@'],
)

asresources = gnome.compile_resources(
    'as-resources', 'gresource.xml',
    dependencies: [blueprints],
    source_dir: 'ui',
    c_name: 'as'
)


# Suprapack
conf_data = configuration_data()
conf_data.set('version', meson.project_version())
info_file = configure_file(input : 'data/info.in', output : 'info', configuration : conf_data)

install_data(info_file, install_dir: '.')
install_data(files('data/supravim.desktop'), install_dir: get_option('datadir') / 'applications')
install_data(files('data/supravim.svg'), install_dir: get_option('datadir') / 'pixmaps')
meson.add_install_script('suprapack_build.sh')

subdir('src')
