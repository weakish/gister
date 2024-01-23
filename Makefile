NAME=gister

PREFIX?=/usr/local
BINDIR=${PREFIX}/bin
MANDIR=${PREFIX}/man/man1
DOCDIR=${PREFIX}/share/doc/${NAME}

install: man/${NAME}.1.gz
	@mkdir -p ${BINDIR}
	@install -c -m 755 bin/${NAME}  ${BINDIR}/${NAME}
	@mkdir -p ${MANDIR}
	@install -c -m 644 man/${NAME}.1.gz ${MANDIR}/${NAME}.1.gz
	@mkdir -p ${DOCDIR}
	@install -c -m 644 README.md ${DOCDIR}/README.md

man/${NAME}.1.gz:
	@gzip -k man/${NAME}.1

uninstall:
	@rm -f ${BINDIR}/${NAME}
	@rm -f ${MANDIR}/${NAME}.1.gz
	@rm -rf ${DOCDIR}