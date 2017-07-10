ifeq ($(OS),Windows_NT)
    MAKEPDF=texify.exe --pdf --synctex=1 --clean
else
    MAKEPDF=pdflatex
endif

.PHONY: slides handout all

slides:
	$(MAKEPDF) 20170727_stata_conference.tex
	@echo HELP: Also helpful targets: handout, all
#Nice to list on the default target some helpful stuff.

handout: 
	$(MAKEPDF) 20170727_stata_conference_handout.tex

check: 
	chktex -n26 -n36 -n34 -n18 -n9 -n39 20170727_stata_conference.tex
  @echo Still some false-positives.
#all are about puncutation in code (TODO try to fix).

all: slides handout
