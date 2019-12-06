/* #ifndef checks whether the given token has been #defined earlier in the file
 * or in an included file; if not, it includes the code between it and the
 * closing #else or, if no #else is present, #endif statement. #ifndef is often
 * used to make header files idempotent by defining a token once the file has
 * been included and checking that the token was not set at the top of that
 * file.*/

#ifndef _MAIN_H
#define _MAIN_H

#include "struct.h"

#endif
