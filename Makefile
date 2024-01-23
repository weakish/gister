NAME=gister

PREFIX?=/usr/local
BINDIR=${PREFIX}/bin

install: ${NAME}
	@mkdir -p ${BINDIR}
	@install -c -m 755 bin/${NAME}  ${BINDIR}/${NAME}

uninstall:
	@rm -f ${BINDIR}/${NAME}
