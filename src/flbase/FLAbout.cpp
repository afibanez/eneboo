/***************************************************************************
                            FLAbout.cpp
                         -------------------
begin                : Sat Jan 26 2002
copyright            : (C) 2002-2005 by InfoSiAL S.L.
                           2011 by Gestiweb
email                : mail@infosial.com 
                       info@gestiweb.com
***************************************************************************/
/***************************************************************************
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; version 2 of the License.               *
 ***************************************************************************/
/***************************************************************************
   Este  programa es software libre. Puede redistribuirlo y/o modificarlo
   bajo  los  t�rminos  de  la  Licencia  P�blica General de GNU   en  su
   versi�n 2, publicada  por  la  Free  Software Foundation.
 ***************************************************************************/

#include <qlabel.h>

#include "FLAbout.h"
#include "AQConfig.h"

FLAbout::FLAbout(const QString &v,
                 QWidget *parent,
                 const char *name) :
  FLWidgetAbout(parent, name)
{
  labelVersion->setText(v);
  lblCreditos->setText("<p align=\"center\"><b>Eneboo</b><br>"
                       "<b>Open Source ERP Software</b><br><br>"
                       "Publicado bajo los t�rminos de la<br>"
                       "<b>GNU GENERAL PUBLIC LICENSE<br>(version 2)</b><br>"
                       "Este software se distribuye \"como est�\", <br>"
                       "<b>sin garant�as de ninguna clase</b><br>"
                       );
 lblCompilacion->setText(ENB_DATOS_COMP);
}

FLAbout::~FLAbout() {}
