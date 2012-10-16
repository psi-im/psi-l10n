#!/bin/sh
set -e

rm -rf dist
mkdir dist

for lang in `cat langs`; do
	cp $lang/psi_$lang.ts dist
	cp $lang/psi_$lang.html dist

	if [ -f $QTDIR/translations/qt_$lang.qm ]; then
		cp $QTDIR/translations/qt_$lang.qm dist
	fi

	if [ -f $lang/qt_$lang.ts ]; then
		lrelease $lang/qt_$lang.ts -qm dist/qt_$lang.qm
	fi

	lrelease $lang/psi_$lang.ts -qm dist/psi_$lang.qm
done
