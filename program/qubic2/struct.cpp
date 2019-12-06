#include "struct.h"
#include <algorithm>

/* global data */
continuous **arr;
discrete **arr_c;
discrete *symbols;
char **genes_n;
char **conds_n;
char **sub_genes;
bool *sublist;
int rows, cols, sigma;
int sub_genes_row;

Prog_options *po;

/**************************************************************************/
/* helper functions for error msgs for allocating memory */

void progress(const char *format, ...)
/* Print progress message */
{
  va_list args;
  va_start(args, format);
  vfprintf(stdout, format, args);
  fprintf(stdout, "\n");
  va_end(args);
}

void verboseDot()
/* Print "i-am-alive" dot */
{
  putchar('.');
  fflush(stdout);
}

void err(const char *format, ...)
/* Print error message but do not exit */
{
  va_list args;
  va_start(args, format);
  fprintf(stderr, "[Error] ");
  vfprintf(stderr, format, args);
  fprintf(stderr, "\n");
  va_end(args);
}

void errAbort(const char *format, ...)
/* Print error message and exit */
{
  va_list args;
  va_start(args, format);
  fprintf(stderr, "[Error] ");
  vfprintf(stderr, format, args);
  fprintf(stderr, "\n");
  va_end(args);
  exit(1);
}

long clock1000()
/* A millisecond clock. */
{
  struct timeval tv;
  static long origSec;
  gettimeofday(&tv, NULL);
  if (origSec == 0)
    origSec = tv.tv_sec;
  return (tv.tv_sec - origSec) * 1000 + tv.tv_usec / 1000;
}

void uglyTime(const char *label, ...)
/* Print label and how long it's been since last call.  Call with
 * a NULL label to initialize. */
{
  static long lastTime = 0;
  const long time = clock1000();
  va_list args;
  va_start(args, label);
  if (label != NULL) {
    vfprintf(stdout, label, args);
    fprintf(stdout, " [%.3f seconds elapsed]\n", (time - lastTime) / 1000.);
  }
  lastTime = time;
  va_end(args);
}

void *xmalloc(int size)
/* Wrapper for standard mallc */
{
  /*malloc: The function malloc() returns a pointer to a chunk of memory of size
   *size, or NULL if there is an error. The memory pointed to will be on the
   *heap, not the stack, so make sure to free it when you are done with it.*/
  register void *value = malloc(size);
  if (value == NULL)
    errAbort("Memory exhausted (xmalloc)");
  return value;
}

void *xrealloc(void *ptr, int size)
/* Wrapper for standard reallc */
/* realloc may move the memory block to a new location, in which case the new
 * location is returned. The content of the memory block is preserved up to the
 * lesser of the new and old sizes, even if the block is moved. If the new size
 * is larger, the value of the newly allocated portion is indeterminate.*/
{
  register void *value = realloc(ptr, size);
  if (value == NULL)
    errAbort("Memory exhausted (xrealloc)");
  return value;
}

/**************************************************************************/
/* Print out the stack elements */
void dsPrint(const std::vector<int> &ds) {
  printf("Stack contains %zu elements\n", ds.size());
  for (auto d : ds)
    printf("%d ", d);
  putchar('\n');
}

/* Test whether an item is in stack */
bool isInStack(const std::vector<int> &ds, const int item) {
  return std::find(ds.begin(), ds.end(), item) != ds.end();
}

/* Return the number of common components between two arrays */
int dsIntersect(const std::vector<int> &ds1, const std::vector<int> &ds2) {
  int cnt = 0;

  for (auto d : ds1)
    if (isInStack(ds2, d))
      cnt++;

  return cnt;
}

/**************************************************************************/
/* file-related operations */
FILE *mustOpen(const char *fileName, const char *mode)
/* Open a file or die */
{
  FILE *f;

  if (sameString(fileName, "stdin"))
    return stdin;
  if (sameString(fileName, "stdout"))
    return stdout;
  if ((f = fopen(fileName, mode)) == NULL) {
    const char *modeName = "";
    if (mode) {
      if (mode[0] == 'r')
        modeName = " to read";
      else if (mode[0] == 'w')
        modeName = " to write";
      else if (mode[0] == 'a')
        modeName = " to append";
    }
    errAbort("Can't open %s%s: %s", fileName, modeName, strerror(errno));
  }
  return f;
}

/**************************************************************************/
