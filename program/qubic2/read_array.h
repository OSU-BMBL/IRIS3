#ifndef _READ_ARRAY_H
#define _READ_ARRAY_H

/************************************************************************/

#include "struct.h"

/***********************************************************************/

/* prototypes  */
continuous **alloc2d(int rr, int cc);
discrete **alloc2c(int rr, int cc);
void write_imported(const char *stream_nm);
void get_matrix_size(FILE *fp);
void read_labels(FILE *fp);
void read_discrete(FILE *fp);
void read_continuous(FILE *fp);
void discretize(const char *stream_nm);
void discretize_new(const char *stream_nm);
void discretize_rpkm(const char *stream_nm);

discrete dis_value(float current, int divided, float *small, int cntl,
                   float *big, int cntu);
void read_list(FILE *fp);
continuous get_KL(const std::vector<discrete> &array,
                  discrete *array_background, int a, int b);
int compare_continuous(const void *a, const void *b);
double densityFuction(double x, double a, double d);
double NormSDist(double x, double a, double b);
/***********************************************************************/

#endif
