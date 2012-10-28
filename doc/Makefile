MANUALS = Test-TUI.3 Test-TUI.html Test-TUI.pdf

.SUFFIXES:
.SUFFIXES: .mdwn .pdf .html .3

COMMONOPTIONS = --self-contained --number-sections --normalize --smart --toc

TEX_META = -V author="Frank Terbeck" -V title="Test::TUI(3) Reference Manual"
TEX_META += --highlight-style=monochrome
HTML_META = ${TEX_META}
TEX_META += -V date='\today'

MAN_META = -V title="Test::TUI" -V section="3" -V date="Oct, 2012"

.mdwn.3:
	pandoc -t man ${COMMONOPTIONS} ${MAN_META} -o $@ $<

.mdwn.html:
	pandoc -t html5 ${COMMONOPTIONS} ${HTML_META} -o $@ $<

.mdwn.pdf:
	pandoc --template template.latex ${COMMONOPTIONS} ${TEX_META} -o $@ $<

all: ${MANUALS}

clean:
	rm -f ${MANUALS} *~

.PHONY: all clean
