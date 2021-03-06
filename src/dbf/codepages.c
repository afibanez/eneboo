/**********************************************************************
 *	CODEPAGES.H
 * 	Header file with codepage definitions for dbf
 *  using ISO-8559-1 definitions (Latin 1) to encode
 *  Author: Bjoern Berg, September 2002
 *  Email: clergyman@gmx.de
 *  dbf Reader and converter for dBase
 *  Version 0.3
 *
 *  History:
 *  - Post 0.6
 *	  unified cp850 and ascii conversions to speed things up
 *  - Version 0.3 - 2003-04-20
 *	  splitted to codepages.h and codepages.c
 *  - Version 0.2 - 2003-01-30
 *	  included patch by Christian Vogel:
 *	  changes all occurences of "char" to "unsigned char"
 *    This avoids many warnings about "case statement out of range"
 *  - Version 0.1 - 14.09.2002
 *	  first implementation, using iso-definitions
 ********************************************************************/

#include "codepages.h"

static const unsigned char CP850andASCIItable[] = {
	/*        	0/8	1/9	2/A	3/B	4/C	5/D	6/E	7/F	*/
	/* 0x80: */	0x0,	0xFC,	0xE9,	0xE2,	0xE4,	0xE9,	0x0,	0x0,
	/* 0x88: */	0xEA,	0x0,	0xE8,	0x0,	0xEE,	0xEC,	0xC4,	0x0,
	/* 0x90: */	0xC9,	0x0,	0x0,	0xF4,	0xF6,	0xF2,	0xFB,	0xF9,
	/* 0x98: */	0x0,	0xD6,	0xDC,	0x0,	0x0,	0x0,	0x0,	0x0,
	/* 0xA0: */	0xE1,	0xED,	0xF3,	0xFA,	0x0,	0x0,	0x0,	0x0,
	/* 0xA8: */	0x0,	0x0,	0x0,	0x0,	0x0,	0x0,	0x0,	0x0,
	/* 0xB0: */	0x0,	0x0,	0x0,	0x0,	0x0,	0xC1,	0xC2,	0xC0,
	/* 0xB8: */	0x0,	0x0,	0x0,	0x0,	0x0,	0x0,	0x0,	0x0,
	/* 0xC0: */	0x0,	0xC1,	0xC2,	0x0,	0xC4,	0x0,	0x0,	0x0,
	/* 0xC8: */	0xC8,	0xC9,	0xCA,	0x0,	0xCC,	0xCD,	0xCE,	0x0,
	/* 0xD0: */	0x0,	0x0,	0xCA,	0xDA,	0xD4,	0x0,	0xCD,	0xCE,
	/* 0xD8: */	0x0,	0xD9,	0xDA,	0xDB,	0xDC,	0x0,	0xCC,	0xDF,
	/* 0xE0: */	0xE9,	0xDF,	0xD4,	0xD2,	0xE4,	0x0,	0x0,	0x0,
	/* 0xE8: */	0xE8,	0xD3,	0xDB,	0xD9,	0xEC,	0xED,	0xEE,	0x0,
	/* 0xF0: */	0x0,	0x0,	0xF2,	0xF3,	0xF4,	0x0,	0xF6,	0x0,
	/* 0xF8: */	0x0,	0xF9,	0xFA,	0xFB,	0xFC,	0x0
};

void
cp850andASCIIconvert(unsigned char *src)
{
	int index;
	for (; *src; src++) {
		index = *src - 0x80;
		if ((index >= 0 || index < sizeof(CP850andASCIItable))
		    && CP850andASCIItable[index])
			*src = CP850andASCIItable[index];
	}
}
