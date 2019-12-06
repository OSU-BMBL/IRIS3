#ifndef _STRUCT_H
#define _STRUCT_H

#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

#include <ctype.h>
#include <errno.h>
#include <limits.h>
#include <math.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <time.h>
#include <type_traits> // std::remove_reference
#include <vector>

/***** Useful macros *****/

/* Compatibility of __attribute__ with non-GNU */
#ifndef __GNUC__
#define __attribute__(x) /* Nothing */
#endif

/* Pretend that C has boolean type */
#define TRUE 1
#define FALSE 0
#define boolean unsigned char
#ifndef __cplusplus
#ifndef bool
#define bool unsigned char
#endif
#endif

/* Strings */
/* strcmp: a zero value indicates that both strings are equal.
 * a value greater than zero indicates that the first character that does not
 * match has a greater value in str1 than in str2; And a value less than zero
 * indicates the opposite.
 */
#define sameString(a, b) (strcmp((a), (b)) == 0)
/* Returns TRUE if two strings are same */

/* Constants */
#define LABEL_LEN 64

#ifndef NULL
#define NULL 0
#endif

/* Two major data types */
typedef float continuous;
typedef short discrete;

/* global data */
extern continuous **arr;
extern discrete **arr_c;
extern discrete *symbols;
extern char **genes_n;
extern char **conds_n;
extern char **sub_genes;
extern bool *sublist;
extern int rows, cols, sigma;
extern int sub_genes_row;

/***** Structures *****/

typedef int edge_scroe_t;

/* edge between two genes */
typedef struct Edge {
  Edge(const int gene_one, const int gene_two, const edge_scroe_t score)
      : gene_one(gene_one), gene_two(gene_two), score(score) {}
  int gene_one;
  int gene_two;
  edge_scroe_t score;
} Edge;

/* biclustering block */
struct BlockBase {
  std::vector<int> genes;
  std::vector<int> conds;
  double score;
  int block_rows_pre;
  int core_rownum;
  int core_colnum;
};

/* KL biclustering block */
struct Block : BlockBase {
  double significance;
};

/* biclustering block in version 1*/
struct Block1 : BlockBase {};

/* holds running options */
typedef struct Prog_options {
  char FN[LABEL_LEN];
  char BN[LABEL_LEN];
  bool IS_SWITCH;
  bool IS_DISCRETE;
  bool IS_cond;
  bool IS_spearman;
  bool IS_new_discrete;
  bool IS_MaxMin;
  bool IS_rpkm;
  bool IS_Fast;
  int COL_WIDTH;
  int DIVIDED;
  std::size_t SCH_BLOCK;
  std::size_t RPT_BLOCK;
  int EM;
  double FILTER;
  double QUANTILE;
  double TOLERANCE;
  FILE *FP;
  FILE *FB;
} Prog_options;

typedef unsigned short int bits16;
enum { UP = 1, DOWN = 2, IGNORE = 3 };

extern Prog_options *po;
/***** Helper functions *****/

void progress(const char *format, ...)
    /* Print progress message */
    __attribute__((format(printf, 1, 2)));

void verboseDot();
/* Print "i-am-alive" dot */

void err(const char *format, ...)
    /* Print error message but do not exit */
    __attribute__((format(printf, 1, 2)));

void errAbort(const char *format, ...)
    /* Print error message to stderr and exit */
    __attribute__((noreturn, format(printf, 1, 2)));

void uglyTime(const char *label, ...);
/* Print label and how long it's been since last call.  Call with
 * a NULL label to initialize. */

void *xmalloc(int size);
/* Wrapper for memory allocations */

void *xrealloc(void *ptr, int size);
/* Wrapper for memory re-allocations */

/* Stack-related operations */
void dsPrint(const std::vector<int> &ds);

#define dsSize(pds) (pds.size())
/* Return the size of the stack */

#define dsItem(pds, j) (pds[j])
/* Return the j-th item in the stack */

bool isInStack(const std::vector<int> &ds, int element);
int dsIntersect(const std::vector<int> &ds1, const std::vector<int> &ds2);

/* File-related operations */
FILE *mustOpen(const char *fileName, const char *mode);
/* Open a file or die */

#endif
