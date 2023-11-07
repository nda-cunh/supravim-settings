SRC=Body.vala Doc.vala General.vala main.vala Parser.vala
all:
	valac -g $(SRC) -X -w  --pkg=gtk4 --pkg=libadwaita-1 -o out

run: all
	./out

run2: all
	GTK_DEBUG=interactive ./out
