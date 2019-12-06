/******************************************************************/
/* Author: Qin Ma <maqin@uga.edu>, Step. 19, 2013
 * Output the identified bicluster block.
 */

#include "write_block.h"

/*************************************************************************/

/* Identified clusters are backtraced to the original data, by
 * putting the clustered vectors together, identify common column
 */
template <typename Block>
void print_bc(FILE *fw, const std::unique_ptr<Block> &b, const int num) {
  /* block height (genes) */
  const int block_rows = b->genes.size();
  /* block_width (conditions) */
  const int block_cols = b->conds.size();
  
  const int core_rows = b->core_rownum;  /* core height*/
  const int core_cols = b->core_colnum;  /* core width*/
  fprintf(fw, "BC%03d\tS=%d\tEnrichment:%.2f\tRow=%d\tCol=%d\tCore_Row=%d\tCore_Col=%d\t\n", num, block_rows * block_cols,
          b->score / 100.0,block_rows,block_cols,core_rows,core_cols);

  fprintf(fw, " Genes [%d]: ", block_rows);
  for (auto gene : b->genes)
    fprintf(fw, "%s ", genes_n[gene]);
  fprintf(fw, "\n");

  fprintf(fw, " Conds [%d]: ", block_cols);
  for (auto cond : b->conds)
    fprintf(fw, "%s ", conds_n[cond]);
  fprintf(fw, "\n");
  /* the complete block data output */
  int i = 0;
  for (auto gene : b->genes) {
    fprintf(fw, "%10s:", genes_n[gene]);
    for (auto cond : b->conds) {
      fprintf(fw, "\t%d", symbols[arr_c[gene][cond]]);
    }
    fputc('\n', fw);
    if (i == b->block_rows_pre - 1)
      fputc('\n', fw);
    i++;
  }
}

template void print_bc<Block>(FILE *fw, const std::unique_ptr<Block> &b,
                              int num);
template void print_bc<Block1>(FILE *fw, const std::unique_ptr<Block1> &b,
                               int num);
