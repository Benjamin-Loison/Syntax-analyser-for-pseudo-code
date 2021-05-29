# Syntax analyser for pseudo code

Court devoir de langages formels (dans le cadre du L3 Informatique de l'ENS Paris Saclay). Il s'agit d'un travail commun avec Arnaud DABY-SEESARAM.

Vous trouverez:
  - un Makefile
  - ast.{c,h}
    | ces fichiers permettent d'écrire l'arbre syntaxique
  - executer.{c,h}
    | ces fichiers ne sont pas aboutis
  - lang.y langlex.l
    | fichiers principaux permettant de parser des options dans la ligne de
    | commande 
  - printer.{c,h}
    | les fichiers liés à l'impression de l'AST
    
La syntaxe de la commande lang générée est :
	lang [-no-exec] [-f] file [-p]

-f
	introduit le fichier à parser.
-no-exec
	demande de ne pas executer le programme.
-p
	demande l'affichege de l'AST.
toute option non reconnue est vue comme le nom du fichier à parser.

Nous nous sommes arrêtés au niveau 1, n'ayant pas eut le temps de terminer les fonctions liés à l'éxécution.

Notre idée d'éxécution était la suivante :\
 * initialiser un verrou L\
 * pour chaque processus, effectuer dans des processus différents les étapes suivantes :\
    -> Initialiser une pile contenant le statement du processus.\
    -> Executer le processus étape par étape, de la manière suivante:\
         | vérouiller L\
         | dépiler un statement.\
         | si c'est un ';', empiler right, puis left et relancer la fonction (pour éxécuter left)\
         | si c'est un do :\
                 -> Si une condition est évaluée à vraie, empiler le statemenrt\
                      do et un statement associé à l'une des conditions vraies.\
                 -> Si aucune condition n'est évaluée à vraie, passer (ne rien\
                      faire) ou empiler le statement du else s'il est présent.\
         | le cas du if est analogue au do, à l'exception que le statement\
             correspondant au if lui même n'est pas empilé.\
         | si c'est un autre type de statement, l'effectuer.\
         | si on arrive sur une pile vide, arrêter l'exécution avec exit(0).\
         | déverouiller L\
 * Attendre les processus enfants et s'arrêter.
