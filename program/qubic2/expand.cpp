/************************************************************************/
/* Author: Qin Ma <maqin@uga.edu>, Step. 19, 2013
 * Biclustering expansion, greedy add the possible genes and negatively
 * regulated genes from outside of the current bicluster in a given background
 */

#include "expand.h"
#include "cluster.h"
#include "read_array.h"
#include "write_block.h"

discrete **another_arr_c;
char **another_genes;
char **another_conds;
int another_rows;
int another_cols;

/**********************************************************************************/
static char *atom = NULL;
static char delims[] = " \t\r\n";

static int intersect_row(const std::vector<discrete> &colcand, discrete *g2,
                         const int cols) {
  int cnt = 0;
  for (int col = 0; col < cols; col++)
    if (colcand[col] != 0 && colcand[col] == g2[col])
      cnt++;
  return cnt;
}
static int reverse_row(const std::vector<discrete> &colcand, discrete *g2,
                       const int cols) {
  int cnt = 0;
  for (int col = 0; col < cols; col++) {
    if (colcand[col] != 0 && symbols[colcand[col]] == -symbols[g2[col]])
      cnt++;
  }
  return cnt;
}

void store_block(std::unique_ptr<Block> &b_ptr, const std::vector<int> &ge,
                 const std::vector<int> &co) {
  b_ptr->genes = ge;
  b_ptr->conds = co;
}
static void init_expand() {
  another_genes = genes_n;
  another_conds = conds_n;
  another_arr_c = arr_c;
  another_rows = rows;
  another_cols = cols;
}
/* Read the .block file, get components and colcand */
void read_and_solve_blocks(FILE *fb, const char *fn) {
  init_expand();
  std::size_t n;
  char *line = NULL;
  int bnumber = 0;
  int i, components, m_cnt;
  std::vector<discrete> colcand(another_cols);
  std::vector<bool> candidates(another_rows);
  std::unique_ptr<Block> b(new Block);
  FILE *fo = mustOpen(fn, "w");

  /* main course starts here */
  while (getline(&line, &n, fb) != -1) {
    /* fast forward to a line that contains BC*/
    /* strncmp compares up to num characters of the C string str1 to those of
     * the C string str2 strncmp ( const char * str1, const char * str2,
     * std::size_t num )*/
    while (strncmp(line, "BC", 2) != 0) {
      if (getline(&line, &n, fb) == -1) {
        uglyTime("expanded biclusters are written to %s", fn);
        exit(0);
      }
    }
    components = 0;
    int col = 0;
    std::vector<int> ge, co;
    ge.reserve(another_rows);
    co.reserve(another_cols);
    for (i = 0; i < another_cols; i++)
      colcand[i] = 0;
    for (i = 0; i < another_rows; i++)
      candidates[i] = TRUE;
    /* read genes from block */
    if (getline(&line, &n, fb) == -1) {
      errAbort("Error in read_and_solve_blocks() "
               "while reading genes from block");
    }
    atom = strtok(line, delims);
    atom = strtok(NULL, delims);
    while ((atom = strtok(NULL, delims)) != NULL) {
      /* look up for genes number */
      if (strlen(atom) == 0)
        continue;
      for (i = 0; i < another_rows; i++) {
        if (strcmp(atom, another_genes[i]) == 0)
          break;
      }
      candidates[i] = FALSE;
      ge.push_back(i);
      components++;
    }
    /* read conditions from block */
    if (getline(&line, &n, fb) == -1) {
      errAbort("Error in read_and_solve_blocks() "
               "while reading conditions from block");
    }
    atom = strtok(line, delims);
    atom = strtok(NULL, delims);
    while ((atom = strtok(NULL, delims)) != NULL) {
      if (strlen(atom) == 0)
        continue;
      for (i = 0; i < another_cols; i++)
        if (strcmp(atom, another_conds[i]) == 0)
          break;
      colcand[i] = another_arr_c[dsItem(ge, 0)][i];
      co.push_back(i);
      col++;
    }

    b->block_rows_pre = components;
    /* add some possible genes */
    continuous KL_score;
    std::vector<discrete> sub_array = get_intersect_row(
        colcand, another_arr_c[dsItem(ge, components - 1)], col);
    const continuous KL_score_ave =
        get_KL(sub_array, another_arr_c[dsItem(ge, components - 1)], col,
               another_cols);
    for (i = 0; i < another_rows; i++) {
      m_cnt = intersect_row(colcand, another_arr_c[i], another_cols);
      if (candidates[i] &&
          (m_cnt >=
           static_cast<int>(floor(static_cast<double>(col) * po->TOLERANCE)))) {
        sub_array = get_intersect_row(colcand, another_arr_c[i], m_cnt);
        KL_score = get_KL(sub_array, another_arr_c[i], m_cnt, another_cols);
        if (KL_score >= KL_score_ave * po->TOLERANCE) {
          ge.push_back(i);
          components++;
          candidates[i] = FALSE;
        }
      }
    }
    /* add genes that negative regulated to the consensus */
    for (i = 0; i < another_rows; i++) {
      m_cnt = reverse_row(colcand, another_arr_c[i], another_cols);
      if (candidates[i] &&
          (m_cnt >=
           static_cast<int>(floor(static_cast<double>(col) * po->TOLERANCE)))) {
        sub_array = get_intersect_reverse_row(colcand, another_arr_c[i], m_cnt);
        KL_score = get_KL(sub_array, another_arr_c[i], m_cnt, another_cols);
        if (KL_score >= KL_score_ave * po->TOLERANCE) {
          ge.push_back(i);
          components++;
          candidates[i] = FALSE;
        }
      }
    }
    if (dsSize(ge) > 1) {
      store_block(b, ge, co);
      print_bc(fo, b, bnumber++);
    }
  }
}
