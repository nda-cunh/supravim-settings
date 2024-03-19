
# Vous faites une autre langue que C, C++, Vala ?

il suffit de faire ``:LspInstallServer <optionel: non dun server>``

la listes des serveur est ici https://github.com/mattn/vim-lsp-settings#supported-languages


je recommande egalement d'ajouter dans votre balise YourConfig:
```
if expand('%:e') == '.py'                     
    var lsp_diagnostics_enabled = 1
	g:lsp_diagnostics_signs_priority = 1
	g:lsp_diagnostics_signs_insert_mode_enabled = 1
    g:lsp_diagnostics_signs_enabled = 1
endif                                       
```
remplacer .py par l'extension de votre fichier
## Python
pour un support python:

```
//dans vim:
 :LspInstallServer

//dans votre .vimrc a la fin dans YOUR CONFIG:

if expand('%:e') == '.py'                     
    var lsp_diagnostics_enabled = 1
    g:lsp_diagnostics_signs_priority = 1
    g:lsp_diagnostics_signs_insert_mode_enabled = 1
    g:lsp_diagnostics_signs_enabled = 1
endif

```

## TypeScript

pour un support typescript plus interessant:
```
//terminal:
git clone https://github.com/Quramy/tsuquyomi/ ~/.vim/bundle/tsc

//dans vim:
 :LspInstallServer

//dans votre .vimrc a la fin dans YOUR CONFIG:
g:syntastic_typescript_checkers = ['tsuquyomi']
g:tsuquyomi_disable_quickfix = 1

if expand('%:e') == '.ts'                     
    var lsp_diagnostics_enabled = 1
    g:lsp_diagnostics_signs_priority = 1
    g:lsp_diagnostics_signs_insert_mode_enabled = 1
    g:lsp_diagnostics_signs_enabled = 1
endif

```
