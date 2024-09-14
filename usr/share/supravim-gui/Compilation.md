# Supramake

`supramake` est une commande q'utilise supravim pour compiler vos projets.

> **F5** executera la commande: `supramake run`
>
> **F6** executera `supramake run2`
>
> **F7** `supramake run3`


Ce qui veut dire que vous pouvez également utiliser **supramake** en dehors de supravim il a d'ailleurs l'alias **`smake`**

si aucun makefile est trouvé il essaiera d'executer votre projet par lui meme et executera le a.out crée

# :Make

la commande `:Make` permet d'executer une règle de votre makefile (il se chargera de retrouvé le makefile lié à votre projet.) `:Make clean` lancera la regle **clean** et ainsi de suite...

Si votre projet contient un fichier Makefile, vous pourrez compiler votre programme avec la touche **F5**, celui-ci le détectera et exécutera **la règle run**. 

**(Voir l'exemple)** (Ajoutez **all** en dependance pour que **run** compile votre projet avant).

exemple d'un makefile:

```make
NAME=hello

all:
    gcc main.c -o $(NAME)

run: all
    ./$(NAME)
```

# Les interet de Supramake

Il fonctionne comme la commande make, sauf qu'il cherchera ou se trouve le makefile pour executer votre règle.

si vous êtes ici: `~/Desktop/Projets/src/folder1/folder2/`

et que votre Makefile est ici: `~/Desktop/Projets/Makefile`

`supramake rule` le lancera, tandis que

`make rule` ne le trouvera pas.

# Arguments

il est possible d'ajouter des arguments a executer pour run avec la variable $(ARG) avec la commande

supramake run --args \<vos argument\>

```make
all:
    echo coucou $(ARGS)
```

supramake --args Samantha

output: `coucou Samantha`




# meson.build

supramake prend en charge les fichiers meson.build
un simple supramake suffit pour compiler/executer le meson.build