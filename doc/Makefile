PROJECT = TestTUI

.SUFFIXES:
.SUFFIXES: .mdwn .pdf .html .3

COMMONOPTIONS = --listings --number-sections --normalize --smart --toc --chapters

.mdwn.3:
	pandoc --self-contained $< -t man ${COMMONOPTIONS} -o $@

.mdwn.html:
	pandoc --self-contained $< -t html5 ${COMMONOPTIONS} -o $@

.mdwn.pdf:
	pandoc ${COMMONOPTIONS} $< -o $@

#all: ${PROJECT}.3 ${PROJECT}.html ${PROJECT}.pdf
all: ${PROJECT}.3

clean:
	rm -f ${PROJECT}.3 ${PROJECT}.pdf ${PROJECT}.html *~

.PHONY: all clean
