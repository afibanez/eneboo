#!/bin/bash

VER="2.4"

OPT_PREFIX=""
OPT_QMAKESPEC=""
OPT_DEBUG=no
OPT_SQLLOG=no
OPT_HOARD=yes
OPT_QWT=yes
OPT_DIGIDOC=yes
OPT_MULTICORE=yes
OPT_AQ_DEBUG=no
QT_DEBUG="-release -DQT_NO_CHECK"
QSADIR=qsa

if [ "$BUILD_NUMBER" == "" ]; then
  BUILD_NUMBER="$(svnversion . -n)"
fi

VERSION="$VER User Build $BUILD_NUMBER"
BUILD_KEY="$VER-Build-$BUILD_NUMBER"

for a in "$@"; do
  case "$a" in
    -debug)
      OPT_DEBUG=yes
    ;;
    -aqdebug)
      OPT_AQ_DEBUG=yes
    ;;
    -qtdebug)
      QT_DEBUG="-debug -DQT_NO_CHECK"
    ;;
    -sqllog)
      OPT_SQLLOG=yes
    ;;
    -hoard)
      OPT_HOARD=yes
    ;;
    -no-hoard)
      OPT_HOARD=no
    ;;
    -qwt)
      OPT_QWT=yes
    ;;
    -digidoc)
      OPT_DIGIDOC=yes
    ;;
    -no-digidoc)
      OPT_DIGIDOC=no
    ;;
    -prefix|-platform)
      VAR=`echo $a | sed "s,^-\(.*\),\1,"`
      shift
      VAL="yes"
    ;;
    *)
    if [ "$VAL" == "yes" ];then
      VAL=$a
    fi
    ;;
  esac
  case "$VAR" in
    prefix)
    if  [ $VAL != "yes" ];then
      OPT_PREFIX=$VAL
    fi
    ;;
    platform)
    if  [ $VAL != "yes" ];then
      OPT_QMAKESPEC=$VAL
      export QMAKESPEC=$OPT_QMAKESPEC
    fi
    ;;
  esac
done

CMD_MAKE="make -s "
MAKE_INSTALL=""

BUILD_MACX="no"
if [ "$OPT_QMAKESPEC" == "macx-g++" -o "$OPT_QMAKESPEC" == "macx-g++-cross" ]; then
  BUILD_MACX="yes"
fi

if [ "$OPT_MULTICORE" == "yes" ]; then
  PROCESSORS=$(expr  $(cat /proc/cpuinfo | grep processor | tail -n 1 | sed "s/.*:\(.*\)/\1/") + 1)
  CMD_MAKE="make -k -j $PROCESSORS -s "
fi
  
if [ "$BUILD_MACX" == "no" ]; then
  QT_DEBUG="$QT_DEBUG -DQT_NO_COMPAT"
  ln -s libmysql_std src/libmysql
else
  ln -s libmysql_macosx src/libmysql
fi

if [ "$OPT_QMAKESPEC" == "" ]; then
  case `uname -m` in
  amd64 | x86_64)
    OPT_QMAKESPEC="linux-g++-64"
    export QMAKESPEC=$OPT_QMAKESPEC
  ;;
  *)
    OPT_QMAKESPEC="linux-g++"
    export QMAKESPEC=$OPT_QMAKESPEC
  ;;
  esac
fi

echo -e "\nUtilidad de compilaci�n e instalaci�n de AbanQ $VERSION"
echo -e "(C) 2003-2011 InfoSiAL, S.L. http://infosial.com - http://abanq.org\n"

if  [ "$OPT_QMAKESPEC" == "win32-g++-cross" ];then
  export CC=${CROSS}gcc
  export CXX=${CROSS}g++
  export LD=${CROSS}ld
  export AR=${CROSS}ar
  export AS=${CROSS}as
  export NM=${CROSS}nm
  export STRIP=${CROSS}strip
  export RANLIB=${CROSS}ranlib
  export DLLTOOL=${CROSS}dlltool
  export OBJDUMP=${CROSS}objdump
  export RESCOMP=${CROSS}windres
  export WINDRES=${CROSS}windres

  OPT_PREFIX="$PWD/src/qt"
  BUILD_KEY="$VER-Build-mingw32-4.2"
  CMD_MAKE="make -k -j $PROCESSORS "
else
  MAKE_INSTALL="install"
fi

if [ "$OPT_PREFIX" == "" ]
then
  echo -e "AVISO : No se ha especificado directorio de instalaci�n"
  echo -e "Uso :  $0 directorio_de_instalacion\n"
  DIRINST=$PWD/abanq-build
  echo -e "Utilizando por defecto el directorio $DIRINST\n"
else
  DIRINST=$OPT_PREFIX
fi

mkdir -p $DIRINST

if [ ! -w $DIRINST ]
then
  echo -e "ERROR : Actualmente no tienes permisos de escritura en el directorio de instalaci�n ($DIRINST)."
  echo -e "Soluci�n : Cambia los permisos o ejecuta este script como un usuario que tenga permisos de escritura en ese directorio.\n"
  exit 1
fi

BASEDIR=$PWD
PREFIX=$DIRINST

echo -e "Directorio de instalaci�n : $PREFIX\n"

echo -e "Estableciendo configuraci�n...\n"

rm -f $HOME/.qmake.cache

export QTDIR=$BASEDIR/src/qt

if [ ! -f $QTDIR/include/qglobal.h ]
then
  cd $QTDIR
  make -s -f Makefile.cvs
  cd $BASEDIR
fi

version=$(cat $QTDIR/include/qglobal.h | grep "QT_VERSION_STR" | sed "s/.*\"\(.*\)\"/\1/g")
echo -e "Versi�n de Qt... $version\n"
echo -e "Compilando qmake y moc...\n"
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$QTDIR/lib
export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$QTDIR/lib
cd $QTDIR

if [ "$OPT_HOARD" = "yes" ]
then
  echo "CONFIG *= enable_hoard" >> tools/designer/app/hoard.pri
fi

if  [ "$OPT_QMAKESPEC" == "win32-g++-cross" ];then
  cd $BASEDIR
  TMP_QTDIR=$(echo $QTDIR | sed "s/\//\\\\\\\\\\\\\\//g")
  cat qconfig/qconfig.h.in | sed "s/@BKEY@/$BUILD_KEY/" > qconfig/qconfig.h
  cp -fv qconfig/qconfig.h src/qt/include
  cp -fv qconfig/qmodules.h src/qt/include
  cd $QTDIR
  ./configure --win32 -prefix $PREFIX -L$PREFIX/lib $QT_DEBUG -thread -stl -no-pch -no-exceptions -platform linux-g++ \
              -xplatform win32-g++-cross -buildkey $BUILD_KEY -disable-opengl -no-cups -no-nas-sound \
              -no-nis -qt-libjpeg -qt-gif -qt-libmng -qt-libpng -qt-imgfmt-png -qt-imgfmt-jpeg -qt-imgfmt-mng
else
  cp -vf Makefile.qt Makefile
  if [ "$BUILD_MACX" == "yes" ]; then
    mkdir -p $DIRINST/lib
    if [ "$OPT_QMAKESPEC" == "macx-g++" ]; then
      ./configure -platform $OPT_QMAKESPEC $QT_DEBUG -prefix $PREFIX -thread -stl -no-pch -no-exceptions \
                  -buildkey $BUILD_KEY -disable-opengl -no-cups -no-ipv6 -no-nas-sound -no-nis -qt-libjpeg \
                  -qt-gif -qt-libmng -qt-libpng -qt-imgfmt-png -qt-imgfmt-jpeg -qt-imgfmt-mng
    else
      ./configure -platform linux-g++ -xplatform $OPT_QMAKESPEC $QT_DEBUG -prefix $PREFIX -thread -stl -no-pch \
                  -no-exceptions -buildkey $BUILD_KEY -disable-opengl -no-cups -no-ipv6 -no-nas-sound -no-nis -qt-libjpeg \
                  -qt-gif -qt-libmng -qt-libpng -qt-imgfmt-png -qt-imgfmt-jpeg -qt-imgfmt-mng
    fi
  else
    export ORIGIN=\\\$\$ORIGIN
    ./configure -platform $OPT_QMAKESPEC -prefix $PREFIX -R'$$(ORIGIN)/../lib' -L$PREFIX/lib $QT_DEBUG -thread -stl \
                -no-pch -no-exceptions -buildkey $BUILD_KEY -xinerama -disable-opengl -no-cups \
                -no-nas-sound -no-nis -qt-libjpeg -qt-gif -qt-libmng -qt-libpng -qt-imgfmt-png -qt-imgfmt-jpeg -qt-imgfmt-mng
  fi
fi

make -s qmake-install || exit 1
make -s moc-install || exit 1

cd $BASEDIR

export PATH=$PREFIX/bin:$PATH
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PREFIX/lib
export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$PREFIX/lib

echo -e "\nComprobando qmake...\n"
$QTDIR/bin/qmake -v > /dev/null
if [ $? = 154 ]
then
  echo -e "OK : qmake encontrado\n"
else
  echo -e "ERROR : No se encuentra qmake, esta utilidad se proporciona con las Qt."
  exho -e "        Comprueba que se encuentra en la ruta de b�squeda (variable $PATH).\n"
    exit 1
fi

cd $BASEDIR

mkdir -p $PREFIX/share/abanq/forms
mkdir -p $PREFIX/share/abanq/tables
mkdir -p $PREFIX/share/abanq/translations
mkdir -p $PREFIX/share/abanq/scripts
mkdir -p $PREFIX/share/abanq/queries
mkdir -p $PREFIX/share/abanq/reports
mkdir -p $PREFIX/share/abanq/tmp
mkdir -p $PREFIX/share/abanq/doc
mkdir -p $PREFIX/share/abanq/packages
mkdir -p $PREFIX/lib
mkdir -p $PREFIX/bin

if [ "$AQ_CIN" == "" ]; then
  AQ_CIN="C = C"
fi

if [ "$AQ_PACK_VER" == "" ]; then
    AQ_PACK_VER="(qstrlen(V) > 0 && qstrcmp(AQPACKAGER_VERSION, V) == 0)"
fi

cat > AQConfig.h <<EOF
// ** $(date +%d%m%Y):$PREFIX -> AQConfig.h
// ** AQConfig.h  Generated by $0
// ** WARNING!    All changes made in this file will be lost!

#ifndef AQCONFIG_H_
#define AQCONFIG_H_

#include "qplatformdefs.h"

#define AQ_DIRAPP                   AQConfig::aqDirApp
#define AQ_PREFIX                   AQ_DIRAPP
#define AQ_QTDIR                    AQ_DIRAPP
#define AQ_KEYBASE                  AQConfig::aqKeyBase
#define AQ_DATA                     AQConfig::aqData
#define AQ_LIB                      AQConfig::aqLib
#define AQ_BIN                      AQConfig::aqBin
#define AQ_USRHOME                  AQConfig::aqUsrHome
#define AQ_VERSION                  "$VERSION"
#define AQ_CIN(C)                   $AQ_CIN
#define AQPACKAGER_VERSION_CHECK(V) $AQ_PACK_VER

class QApplication;
class FLApplication;

class AQConfig
{
public:
  static QString aqDirApp;
  static QString aqKeyBase;
  static QString aqData;
  static QString aqLib;
  static QString aqBin;
  static QString aqUsrHome;
      
private:

  static void init(QApplication *);
  friend class FLApplication;
};

#endif /*AQCONFIG_H_*/
EOF

cat > AQConfig.cpp <<EOF
// ** $(date +%d%m%Y):$PREFIX -> AQConfig.cpp
// ** AQConfig.cpp  Generated by $0
// ** WARNING!    All changes made in this file will be lost!

#include <qapplication.h>
#include <qdir.h>

#include "AQConfig.h"

QString AQConfig::aqDirApp;
QString AQConfig::aqKeyBase;
QString AQConfig::aqData;
QString AQConfig::aqLib;
QString AQConfig::aqBin;
QString AQConfig::aqUsrHome;

void AQConfig::init(QApplication *aqApp)
{
#if defined(Q_OS_MACX)
  aqDirApp = QDir::cleanDirPath(aqApp->applicationDirPath() + QString::fromLatin1("/../../../.."));
#else
  aqDirApp = QDir::cleanDirPath(aqApp->applicationDirPath() + QString::fromLatin1("/.."));
#endif
  aqKeyBase = QString::fromLatin1("AbanQ/");
  aqData = aqDirApp + QString::fromLatin1("/share/abanq");
  aqLib = aqDirApp + QString::fromLatin1("/lib");
  aqBin = aqDirApp + QString::fromLatin1("/bin");
  aqUsrHome = QDir::cleanDirPath(QDir::home().absPath());
}
EOF

echo "include(./includes.pri)" > settings.pro
echo "PREFIX = $PREFIX" >> settings.pro
echo "ROOT = $BASEDIR" >> settings.pro
echo "DEFINES *= FL_EXPORT=" >> settings.pro
echo "INCLUDEPATH *= $PREFIX/include" >> settings.pro
echo "INCLUDEPATH *= $BASEDIR/src/qt/src/tmp" >> settings.pro
echo "CONFIG += warn_off" >> settings.pro

if  [ "$OPT_QMAKESPEC" == "win32-g++-cross" ];then
  if [ "$OPT_DEBUG" == "yes" ];then
    echo "OBJECTS_DIR = .o/debug-shared-mt/" >> settings.pro
    echo "MOC_DIR = .moc/debug-shared-mt/" >> settings.pro
  else
    echo "OBJECTS_DIR = .o/release-shared-mt/" >> settings.pro
    echo "MOC_DIR = .moc/release-shared-mt/" >> settings.pro
  fi
fi

if [ "$OPT_DEBUG" = "yes" ]
then
  echo "CONFIG *= debug" >> settings.pro
  echo "DEFINES *= FL_DEBUG" >> settings.pro
fi

if [ "$OPT_AQ_DEBUG" = "yes" ]
then
  echo "DEFINES *= AQ_DEBUG" >> settings.pro
fi

if [ "$OPT_SQLLOG" = "yes" ]
then
  echo "DEFINES *= FL_SQL_LOG" >> settings.pro

fi

if [ "$OPT_QWT" = "yes" ]
then
  echo "CONFIG *= enable_qwt" >> settings.pro
  echo "DEFINES *= FL_QWT" >> settings.pro
fi

if [ "$OPT_DIGIDOC" = "yes" ]
then
  echo "CONFIG *= enable_digidoc" >> settings.pro
  echo "DEFINES *= FL_DIGIDOC" >> settings.pro
fi

if  [ "$OPT_QMAKESPEC" == "win32-g++-cross" ];then
  # pthread
  cd $BASEDIR/src/pthreads
  $QTDIR/bin/qmake pthreads.pro
  $CMD_MAKE || exit 1
  mkdir -p $BASEDIR/src/qt/src/tmp/
  cp -fv pthread.h $BASEDIR/src/qt/src/tmp/
  cp -fv semaphore.h $BASEDIR/src/qt/src/tmp/
  cp -fv sched.h $BASEDIR/src/qt/src/tmp/
  cd $BASEDIR
fi

if [ "$OPT_HOARD" = "yes" ]
then
  echo "CONFIG *= enable_hoard" >> settings.pro
  echo "DEFINES *= FL_HOARD" >> settings.pro
  echo -e "\nCompilando Hoard...\n"
  cd $BASEDIR/src/hoard
  $QTDIR/bin/qmake hoard.pro
  $CMD_MAKE || exit 1
  cd $BASEDIR
fi

echo -e "\nCompilando Qt ($QTDIR) ...\n"
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$QTDIR/lib:$PREFIX/lib
export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$QTDIR/lib:$PREFIX/lib

if  [ "$OPT_QMAKESPEC" == "win32-g++-cross" ];then
  export QTDIR=$BASEDIR/src/qt
  cd $QTDIR/src
  $QTDIR/bin/qmake -spec $QTDIR/mkspecs/win32-g++-cross -o Makefile.main qtmain.pro
  $CMD_MAKE -f Makefile.main || exit 1
fi
if  [ "$OPT_QMAKESPEC" == "win32-g++-cross" ];then
  cd $QTDIR/tools/designer/uic
  $CMD_MAKE || exit 1
fi
if  [ "$OPT_QMAKESPEC" == "macx-g++-cross" ];then
  cd $QTDIR/tools/designer/uic
  make clean
  rm -f Makefile
  $QTDIR/bin/qmake -spec $QTDIR/mkspecs/linux-g++
  $CMD_MAKE || exit 1
fi
cd $QTDIR
$CMD_MAKE $MAKE_INSTALL || exit 1

export QTDIR=$PREFIX

echo "Compilando QSA..."
cd $BASEDIR/src/$QSADIR
cp -fv ../qt/.qmake.cache .qmake.cache
cp -fv ../qt/.qmake.cache src/$QSADIR/
cp -fv ../qt/.qmake.cache src/plugin/
if  [ "$OPT_QMAKESPEC" == "win32-g++-cross" -o "$OPT_QMAKESPEC" == "macx-g++-cross" ];then
  cd configure2
  export QTDIR=/usr/share/qt3
  /usr/bin/qmake -nocache -spec linux-g++ configure2.pro
  make || exit 1
  export QTDIR=$PREFIX
  cd $BASEDIR/src/qt
  rm -fr LICENSE.*
  touch LICENSE
  svn up 2> /dev/null
  cd $BASEDIR/src/$QSADIR
  ./configure2/configure2
  $QTDIR/bin/qmake CONFIG+="shared"
  rm -fr $BASEDIR/src/qt/LICENSE
else
  ./configure
fi
$CMD_MAKE
make -s $MAKE_INSTALL
$CMD_MAKE
make -s $MAKE_INSTALL
$CMD_MAKE
make -s $MAKE_INSTALL

cd $BASEDIR

echo -e "Creando Makefiles con qmake...\n"

cp -f src/qt/.qmake.cache .qmake.cache
cp -f src/qt/.qmake.cache src/advance/
cp -f src/qt/.qmake.cache src/qwt/
cp -f src/qt/.qmake.cache src/qwt/designer
cp -f src/qt/.qmake.cache src/barcode/
cp -f src/qt/.qmake.cache src/flbase/
cp -f src/qt/.qmake.cache src/fllite/
cp -f src/qt/.qmake.cache src/flbase/
cp -f src/qt/.qmake.cache src/kugar/
cp -f src/qt/.qmake.cache src/sqlite/
cp -f src/qt/.qmake.cache src/libpq/
cp -f src/qt/.qmake.cache src/dbf/
cp -f src/qt/.qmake.cache src/plugins/designer/flfielddb/
cp -f src/qt/.qmake.cache src/plugins/designer/fltabledb/
cp -f src/qt/.qmake.cache src/plugins/sqldrivers/sqlite/
cp -f src/qt/.qmake.cache src/plugins/sqldrivers/psql/
cp -f src/qt/.qmake.cache src/plugins/styles/bluecurve/

$QTDIR/bin/qmake user.pro

echo -e "Compilando...\n"
cd src/flbase
$QTDIR/bin/qmake flbase.pro
if  [ "$OPT_QMAKESPEC" == "win32-g++-cross" ];then
  make mocables || exit 1
else
  make uicables || exit 1
fi
cd $BASEDIR
$CMD_MAKE
make -s $MAKE_INSTALL
$CMD_MAKE
make -s $MAKE_INSTALL
$CMD_MAKE || exit 1
make -s $MAKE_INSTALL

if  [ "$BUILD_MACX" == "yes" ];then
	echo -e "\nConfigurando packete app ...\n"
	CMD_INST_NAME_TOOL=${CROSS}install_name_tool
  
	${CROSS}install_name_tool -change libqsa.1.dylib @executable_path/../../../../lib/libqsa.1.dylib $PREFIX/bin/AbanQ.app/Contents/MacOS/AbanQ
	${CROSS}install_name_tool -change libqt-mt.3.dylib @executable_path/../../../../lib/libqt-mt.3.dylib $PREFIX/bin/AbanQ.app/Contents/MacOS/AbanQ
	${CROSS}install_name_tool -change libqwt.5.dylib @executable_path/../../../../lib/libqwt.5.dylib $PREFIX/bin/AbanQ.app/Contents/MacOS/AbanQ
	${CROSS}install_name_tool -change libflbase.2.dylib @executable_path/../../../../lib/libflbase.2.dylib $PREFIX/bin/AbanQ.app/Contents/MacOS/AbanQ
	${CROSS}install_name_tool -change libadvance.0.dylib @executable_path/../../../../lib/libadvance.0.dylib $PREFIX/bin/AbanQ.app/Contents/MacOS/AbanQ
	${CROSS}install_name_tool -change libflmail.1.dylib @executable_path/../../../../lib/libflmail.1.dylib $PREFIX/bin/AbanQ.app/Contents/MacOS/AbanQ
	
	for i in $(find $PREFIX -type f -name "*.dylib" -print)
	do
		${CROSS}install_name_tool -change libqsa.1.dylib @executable_path/../../../../lib/libqsa.1.dylib $i
		${CROSS}install_name_tool -change libqt-mt.3.dylib @executable_path/../../../../lib/libqt-mt.3.dylib $i
		${CROSS}install_name_tool -change libqwt.5.dylib @executable_path/../../../../lib/libqwt.5.dylib $i
		${CROSS}install_name_tool -change libflbase.2.dylib @executable_path/../../../../lib/libflbase.2.dylib $i
		${CROSS}install_name_tool -change libadvance.0.dylib @executable_path/../../../../lib/libadvance.0.dylib $i
		${CROSS}install_name_tool -change libkdefxx.1.dylib @executable_path/../../../../lib/libkdefxx.1.dylib $i
		${CROSS}install_name_tool -change libpq.4.dylib @executable_path/../../../../lib/libpq.4.dylib $i
		${CROSS}install_name_tool -change libsqlite.2.dylib @executable_path/../../../../lib/libsqlite.2.dylib $i
		${CROSS}install_name_tool -change libmysqlclient.15.dylib @executable_path/../../../../lib/libmysqlclient.15.dylib $i
		${CROSS}install_name_tool -change libflmail.1.dylib @executable_path/../../../../lib/libflmail.1.dylib $i
	done
fi
if [ "$OPT_QMAKESPEC" == "win32-g++-cross" ]; then
  ${CROSS}strip --strip-unneeded $PREFIX/bin/* 2> /dev/null
  ${CROSS}strip --strip-unneeded $PREFIX/lib/* 2> /dev/null
  ${CROSS}strip --strip-unneeded $PREFIX/plugins/designer/* 2> /dev/null
  ${CROSS}strip --strip-unneeded $PREFIX/plugins/sqldrivers/* 2> /dev/null
  ${CROSS}strip --strip-unneeded $PREFIX/plugins/styles/* 2> /dev/null
fi
if [ "$OPT_DEBUG" = "no" -a "$OPT_QMAKESPEC" != "win32-g++-cross" -a "$BUILD_MACX" == "no" ]
then
  strip --strip-unneeded $PREFIX/bin/* 2> /dev/null
  strip --strip-unneeded $PREFIX/lib/* 2> /dev/null
  strip --strip-unneeded $PREFIX/plugins/designer/* 2> /dev/null
  strip --strip-unneeded $PREFIX/plugins/sqldrivers/* 2> /dev/null
  strip --strip-unneeded $PREFIX/plugins/styles/* 2> /dev/null
  cd src/translations
  ./update.sh 2> /dev/null
  cd ../..
fi

echo -e "\nTerminando compilaci�n...\n"
cp -f ./src/forms/*.ui $PREFIX/share/abanq/forms 2> /dev/null
cp -f ./src/tables/*.mtd $PREFIX/share/abanq/tables 2> /dev/null
cp -f ./src/translations/*.ts $PREFIX/share/abanq/translations 2> /dev/null
cp -f ./src/scripts/*.qs $PREFIX/share/abanq/scripts 2> /dev/null
cp -f ./src/docs/*.html $PREFIX/share/abanq/doc 2> /dev/null
cp -f ./src/*.xml $PREFIX/share/abanq 2> /dev/null
cp -f ./src/*.xpm $PREFIX/share/abanq 2> /dev/null
cp -f ./packages/*.abanq $PREFIX/share/abanq/packages 2> /dev/null

echo -e "\nAbanQ $VERSION\n(C) 2003-2011 InfoSiAL, S.L. http://infosial.com - http://abanq.org\n"
echo -e "Compilaci�n terminada.\n"
