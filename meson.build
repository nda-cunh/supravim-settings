project('supravim-gui', ['c', 'vala'],
  version : '1.21',
  default_options : ['warning_level=0', 'optimization=2'])

add_project_arguments('--enable-experimental', language: 'vala')


vapi_dir = meson.current_source_dir() / 'vapi'

add_project_arguments(['--vapidir', vapi_dir], language: 'vala')

gnome = import('gnome')


# Blueprints
srcs_blueprint = files(
  'ui/window.blp',
  'ui/wiki.blp',
  'ui/options.blp',
  'ui/plugins.blp',
  'ui/theme.blp',
  'ui/homepage.blp',
  'ui/DialogPopup.blp',
  'ui/plugins/externalrow.blp',
)


blueprints = custom_target('blueprints',
  input: srcs_blueprint,
  output: '.',
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
meson.add_install_script('suprapack_build.sh')

subdir('src')
