/* Author: Qin Ma <maqin@uga.edu>, Sept. 19, 2013
 * Usage: This is part of bicluster package. Use, redistribution, modify without
 * limitations show how does the whole program work
 */

/***********************************************************************/

#include "main.h"
#include "expand.h"
#include "get_options.h"
#include "make_graph.h"
#include "read_array.h"

/***********************************************************************/

int main(const int argc, char *argv[]) {
  /* Start the timer */
  uglyTime(NULL);
  printf("\nQUBIC %.1f: greedy biclustering (compiled " __DATE__ " " __TIME__
         ")\n\n",
         VER);
  rows = cols = 0;

  /* get the program options defined in get_options.c */
  get_options(argc, argv);

  /*get the size of input expression matrix*/
  get_matrix_size(po->FP);
  progress("File %s contains %d genes by %d conditions", po->FN, rows, cols);
  if (rows < 3 || cols < 3) {
    /*neither rows number nor cols number can be too small*/
    if (!po->IS_Fast)
      errAbort("Not enough genes or conditions to make inference");
  }
  genes_n = reinterpret_cast<char **>(alloc2c(rows, LABEL_LEN));
  conds_n = reinterpret_cast<char **>(alloc2c(cols, LABEL_LEN));

  /* Read in the gene names and condition names */
  read_labels(po->FP);

  /* Read in the expression data */
  if (po->IS_DISCRETE)
    read_discrete(po->FP);
  else {
    read_continuous(po->FP);
    char stream_nm[LABEL_LEN + 20];
    strcpy(stream_nm, po->FN);
    strcat(stream_nm, ".rules");
    /* formatting rules */
    if (po->IS_new_discrete)
      discretize_new(stream_nm);
    else if (po->IS_rpkm)
      discretize_rpkm(stream_nm);
    else
      discretize(stream_nm);
    for (auto row = 0; row < rows; row++) {
      delete[] arr[row];
    }
    delete[] arr;
  }
  fclose(po->FP);

  /*we can do expansion by activate po->IS_SWITCH*/
  if (po->IS_SWITCH) {
    char dest[LABEL_LEN + 20];
    strcpy(dest, po->BN);
    strcat(dest, ".expansion");
    read_and_solve_blocks(po->FB, dest);
  } else {
    char stream_nm[LABEL_LEN + 20];
    strcpy(stream_nm, po->FN);
	if (po->IS_new_discrete || po->IS_rpkm)
      strcat(stream_nm, ".original.chars");
	else
      strcat(stream_nm, ".chars");
    /* formatted file */
    write_imported(stream_nm);
    /* exit the program without biclustering analysis*/
    if (po->IS_Fast)
      exit(1);
    /* the file that stores all blocks */
	if (po->IS_new_discrete || po->IS_rpkm)	{
		strcpy(stream_nm, argv[0]);		
		strcat(stream_nm, " -i ");
		strcat(stream_nm, po->FN);
		strcat(stream_nm, ".chars -d");
		system(stream_nm); // This ugly call should be fixed.
		exit(1);
	}
	char dest[LABEL_LEN + 20];
    strcpy(dest, po->FN);
    strcat(dest, ".blocks");
    make_graph(dest);
  } /* end of main else */
  for (auto row = 0; row < rows; row++) {
    delete[] arr_c[row];
  }
  delete[] arr_c;
  for (auto row = 0; row < rows; row++) {
    delete[] genes_n[row];
  }
  delete[] genes_n;
  for (auto col = 0; col < cols; col++) {
    delete[] conds_n[col];
  }
  delete[] conds_n;
  delete po;
  delete[] sublist;
  delete[] symbols;
  return 0;
}

/***********************************************************************/
