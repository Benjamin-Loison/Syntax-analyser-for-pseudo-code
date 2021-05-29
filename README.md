# Syntax analyser for pseudo code

Court devoir (effectué en 5 jours) de langages formels (dans le cadre du L3 Informatique de l'ENS Paris Saclay).\
Il s'agit d'un travail commun avec Arnaud DABY-SEESARAM.

Vous trouverez:\
- un Makefile\
- ast.{c,h}\
&nbsp;| ces fichiers permettent d'écrire l'arbre syntaxique\
- executer.{c,h}\
&nbsp;| ces fichiers ne sont pas aboutis\
- lang.y langlex.l\
&nbsp;| fichiers principaux permettant de parser des options dans la ligne de commande\
- printer.{c,h}\
&nbsp;| les fichiers liés à l'impression de l'AST
    
La syntaxe de la commande lang générée est :
&nbsp;lang [-no-exec] [-f] file [-p]

-f\
&nbsp;introduit le fichier à parser.\
-no-exec\
&nbsp;demande de ne pas executer le programme.\
-p\
&nbsp;demande l'affichege de l'AST.\
toute option non reconnue est vue comme le nom du fichier à parser.\

Nous nous sommes arrêtés au niveau 1, n'ayant pas eut le temps de terminer les fonctions liés à l'éxécution.

Notre idée d'éxécution était la suivante :\
* initialiser un verrou L\
* pour chaque processus, effectuer dans des processus différents les étapes suivantes :\
&nbsp;-> Initialiser une pile contenant le statement du processus.\
&nbsp;-> Executer le processus étape par étape, de la manière suivante:\
&nbsp;&nbsp;| vérouiller L\
&nbsp;&nbsp;| dépiler un statement.\
&nbsp;&nbsp;| si c'est un ';', empiler right, puis left et relancer la fonction (pour éxécuter left)\
&nbsp;&nbsp;| si c'est un do :\
&nbsp;&nbsp;&nbsp;-> Si une condition est évaluée à vraie, empiler le statemenrt\
&nbsp;&nbsp;&nbsp;&nbsp;do et un statement associé à l'une des conditions vraies.\
&nbsp;&nbsp;&nbsp;-> Si aucune condition n'est évaluée à vraie, passer (ne rien\
&nbsp;&nbsp;&nbsp;&nbsp;faire) ou empiler le statement du else s'il est présent.\
&nbsp;&nbsp;| le cas du if est analogue au do, à l'exception que le statement\
&nbsp;&nbsp;&nbsp;correspondant au if lui même n'est pas empilé.\
&nbsp;&nbsp;| si c'est un autre type de statement, l'effectuer.\
&nbsp;&nbsp;| si on arrive sur une pile vide, arrêter l'exécution avec exit(0).\
&nbsp;&nbsp;| déverouiller L\
* Attendre les processus enfants et s'arrêter.
