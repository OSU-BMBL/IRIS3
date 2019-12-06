/************************************************************************/
/* Author: Qin Ma <maqin@uga.edu>, Step. 19, 2013
 * Biclustering procedure, greedy heuristic by picking an edge with highest
 * score and then dynamically adding vertices into the block and see if
 * the block score can be improved.
 */

#include "cluster.h"
#include "make_graph.h"
#include "read_array.h"
#include "write_block.h"
#include <algorithm>
#include <cassert>
#include <vector>

static void update_colcand(std::vector<discrete> &colcand, discrete *g2) {
  for (int col = 0; col < cols; col++)
    if (colcand[col] != 0 && colcand[col] != g2[col])
      colcand[col] = 0;
}

std::vector<discrete> get_intersect_row(const std::vector<discrete> &colcand,
                                        discrete *g2, const int cnt) {
  std::vector<discrete> array;
  array.reserve(cnt);
  for (int col = 0; col < cols; col++)
    if (colcand[col] != 0 && (colcand[col] == g2[col]))
      array.push_back(colcand[col]);
  return array;
}

std::vector<discrete>
get_intersect_reverse_row(const std::vector<discrete> &colcand, discrete *g2,
                          const int cnt) {
  std::vector<discrete> array;
  array.reserve(cnt);
  for (int col = 0; col < cols; col++)
    if (colcand[col] != 0 && (symbols[colcand[col]] == -symbols[g2[col]]))
      array.push_back(colcand[col]);
  return array;
}

static int intersect_row(const std::vector<discrete> &colcand, discrete *g2)
/*caculate the weight of the edge with two vertices g1 and g2*/
{
  int cnt = 0;
  for (int col = 0; col < cols; col++)
    if (colcand[col] != 0 && colcand[col] == g2[col])
      cnt++;
  return cnt;
}

static int reverse_row(const std::vector<discrete> &colcand, discrete *g2) {
  int cnt = 0;
  for (int col = 0; col < cols; col++) {
    if (colcand[col] != 0 && symbols[colcand[col]] == -symbols[g2[col]])
      cnt++;
  }
  return cnt;
}

// calculate the coverage of any row to the current consensus
// cnt = # of valid consensus columns
static int seed_current_modify(const std::vector<int> &genes,
                               const std::vector<std::vector<bits16>> &profile,
                               std::vector<discrete> &colcand) {
  const discrete *s = arr_c[genes[genes.size() - 1]];
  const int components = genes.size();
  const int threshold =
      ceil(components * (components < 10 ? 0.95 : po->TOLERANCE));
  int cnt = 0;
  for (int col = 0; col < cols; col++) {
    for (int k = 1; k < sigma; k++) {
      if (profile[col][k] >= threshold) {
        cnt++;
        colcand[col] = s[col];
        break;
      }
    }
  }
  return cnt;
}

static std::vector<bool> init_candidates(const std::vector<int> &genes,
                                         const std::vector<discrete> colcand) {
  std::vector<bool> candidates = std::vector<bool>(rows, true);

  /* maintain a candidate list to avoid looping through all rows */
  for (auto gene : genes) {
    candidates[gene] = false;
  }
  int *arr_rows = new int[rows];
  std::vector<int> arr_rows_b(rows);
  for (int row = 0; row < rows; row++) {
    arr_rows[row] = intersect_row(colcand, arr_c[row]);
    arr_rows_b[row] = arr_rows[row];
  }
  /*we just get the largest 100 rows when we initial a bicluster because we
   * believe that the 100 rows can characterize the structure of the bicluster
   * btw, it can reduce the time complexity*/
  if (rows > 100) {
    std::sort(arr_rows_b.begin(), arr_rows_b.end());
    const int top = arr_rows_b[rows - 100];
    for (int row = 0; row < rows; row++)
      if (arr_rows[row] < top)
        candidates[row] = false;
  }
  delete[] arr_rows;

  return candidates;
}

static std::vector<discrete> init_colcand(const std::vector<int> &genes) {
  std::vector<discrete> colcand = std::vector<discrete>(cols, 0);
  discrete *g1 = arr_c[dsItem(genes, 0)];
  discrete *g2 = arr_c[dsItem(genes, 1)];

  /*update intial colcand*/
  for (int col = 0; col < cols; col++) {
    if (g1[col] != 0 && g1[col] == g2[col]) {
      colcand[col] = g1[col];
    }
  }
  return colcand;
}

static void update_block(std::unique_ptr<Block> &b,
                         std::vector<discrete> &colcand,
                         std::vector<bool> &candidates, const int min_width,
                         const int cand_threshold) {
  std::vector<int> &genes = b->genes;
  int col_num = 0;
  std::vector<continuous> KL_score(cols);
  continuous KL_score_c = 0;
  for (int col = 0; col < cols; col++) {
    if (colcand[col]) {
      std::vector<discrete> col_all(rows);
      for (int row = 0; row < rows; row++)
        col_all[row] = arr_c[row][col];
      const std::vector<discrete> col_array(2, colcand[col]);
      KL_score[col] = get_KL(col_array, &col_all[0], 2, rows);
      KL_score_c += KL_score[col];
      col_num++;
    }
  }

  int k = 1;
  while (genes.size() < static_cast<std::size_t>(rows)) {
    int max_cnt = -1;
    int max_row = -1;

    for (int row = 0; row < rows; row++) {
      if (candidates[row]) {
        const int cnt = intersect_row(colcand, arr_c[row]);
        if (cnt < cand_threshold)
          candidates[row] = false;
        if (cnt > max_cnt) {
          max_cnt = cnt;
          max_row = row;
        }
      }
    }
    if (max_cnt < min_width)
      break;
    /* reconsider the genes with cnt=max_cnt when expand current bicluster base
     * on the cwm-like significant of each row */
    const std::vector<discrete> sub_array =
        get_intersect_row(colcand, arr_c[max_row], max_cnt);
    continuous KL_score_r = get_KL(sub_array, arr_c[max_row], max_cnt, cols);
    for (auto gene : genes)
      KL_score_r += get_KL(sub_array, arr_c[gene], max_cnt, cols);
    const double significance = KL_score_r / (genes.size() + 1);
    for (int col = 0; col < cols; col++) {
      if (colcand[col] && (arr_c[max_row][col] != arr_c[genes[0]][col])) {
        KL_score_c -= KL_score[col];
        col_num--;
      }
    }

    const double current_score = 100 *( significance > KL_score_c / col_num ?  KL_score_c / col_num : significance);  /* add 0201 xiej */
    if (current_score >= b->score) {
      b->score = current_score;
      b->significance = significance;
      // the best score
      k = genes.size();
    }
    genes.push_back(max_row);
    update_colcand(colcand, arr_c[max_row]);
    candidates[max_row] = false;
  }

  genes.resize(k + 1);
}

static void update_block(std::unique_ptr<Block1> &b,
                         std::vector<discrete> &colcand,
                         std::vector<bool> &candidates, const int min_width,
                         const int cand_threshold) {
  std::vector<int> &genes = b->genes;

  int k = 1;
  while (genes.size() < static_cast<std::size_t>(rows)) {
    int max_cnt = -1;
    int max_row = -1;

    for (int row = 0; row < rows; row++) {
      if (candidates[row]) {
        const int cnt = intersect_row(colcand, arr_c[row]);
        if (cnt < cand_threshold)
          candidates[row] = false;
        if (cnt > max_cnt) {
          max_cnt = cnt;
          max_row = row;
        }
      }
    }
    if (max_cnt < min_width)
      break;

    const std::size_t size = genes.size();
    const double current_score =
        static_cast<std::size_t>(max_cnt) > size ? size : max_cnt;
    if (current_score >= b->score) {
      b->score = current_score;
      // the best score
      k = genes.size();
    }
    genes.push_back(max_row);
    update_colcand(colcand, arr_c[max_row]);
    candidates[max_row] = false;
  }

  genes.resize(k + 1);
}

template <typename Block>
static void block_init(std::unique_ptr<Block> &b, const int min_width,
                       const int cand_threshold) {
  std::vector<discrete> colcand = init_colcand(b->genes);
  std::vector<bool> candidates = init_candidates(b->genes, colcand);
  update_block(b, colcand, candidates, min_width, cand_threshold);
}

bool are_genes_in_blocks(const std::unique_ptr<Edge> &e,
                         const std::vector<bool> &allincluster) {
  return allincluster[e->gene_one] && allincluster[e->gene_two];
}

/**************************************************************************/
void seed_update(const discrete *s, std::vector<std::vector<bits16>> &profile) {
  for (int i = 0; i < cols; i++)
    profile[i][s[i]]++;
}

std::vector<std::vector<bits16>> get_profile(const std::vector<int> &gene_set) {
  std::vector<std::vector<bits16>> profile =
      std::vector<std::vector<bits16>>(cols, std::vector<bits16>(sigma, 0));
  for (auto gene : gene_set)
    seed_update(arr_c[gene], profile);
  return profile;
}

/******************************************************************/
/* scan through all columns and identify the set within threshold,
 * "fuzziness" of the block is controlled by TOLERANCE (-c)
 */
template <typename Block> void scan_block(std::unique_ptr<Block> &b_ptr) {
  std::vector<std::vector<bits16>> profile = get_profile(b_ptr->genes);

  const int btolerance = ceil(po->TOLERANCE * b_ptr->genes.size());
  for (int col = 0; col < cols; col++) {
    /* See if this column satisfies tolerance */
    /* here i start from 1 because symbols[0]=0 */
    for (int symbol_index = 1; symbol_index < sigma; symbol_index++) {
      if (profile[col][symbol_index] >= btolerance) {
        b_ptr->conds.push_back(col);
        break;
      }
    }
  }
}

bool kl_ok(std::unique_ptr<Block> &b, const std::vector<discrete> &colcand,
           const int row, const int m_cnt) {
  const std::vector<discrete> sub_array =
      get_intersect_row(colcand, arr_c[row], m_cnt);
  const continuous KL_score = get_KL(sub_array, arr_c[row], m_cnt, cols);
  return KL_score >= b->significance * po->TOLERANCE;
}

bool kl_ok_r(std::unique_ptr<Block> &b, const std::vector<discrete> &colcand,
             const int row, const int m_cnt) {
  const std::vector<discrete> sub_array =
      get_intersect_reverse_row(colcand, arr_c[row], m_cnt);
  const continuous KL_score = get_KL(sub_array, arr_c[row], m_cnt, cols);
  return KL_score >= b->significance * po->TOLERANCE;
}

bool kl_ok(std::unique_ptr<Block1> & /*b*/,
           const std::vector<discrete> & /*colcand*/, int /*row*/,
           int /*m_cnt*/) {
  return true;
}

bool kl_ok_r(std::unique_ptr<Block1> & /*b*/,
             const std::vector<discrete> & /*colcand*/, int /*row*/,
             int /*m_cnt*/) {
  return true;
}

template <typename Block>
void add_possible_genes(std::unique_ptr<Block> &b,
                        const std::vector<discrete> &colcand,
                        const double tolerance, std::vector<bool> &candidates) {
  /* add some new possible genes */
  for (int row = 0; row < rows; row++) {
    int m_cnt = intersect_row(colcand, arr_c[row]);
    if (candidates[row] && m_cnt >= tolerance) {
      if (kl_ok(b, colcand, row, m_cnt)) {
        b->genes.push_back(row);
        candidates[row] = false;
      }
    }
  }
}

template <typename Block>
void add_negative_genes(std::unique_ptr<Block> &b,
                        const std::vector<discrete> &colcand,
                        const double tolerance, std::vector<bool> &candidates) {
  /* add genes that negative regulated to the consensus */
  for (int row = 0; row < rows; row++) {
    int m_cnt = reverse_row(colcand, arr_c[row]);
    if (candidates[row] && m_cnt >= tolerance) {
      if (kl_ok_r(b, colcand, row, m_cnt)) {
        b->genes.push_back(row);
        candidates[row] = false;
      }
    }
  }
}

template <typename Block> void block_expand(std::unique_ptr<Block> &b) {
  std::vector<int> &genes = b->genes;
  const std::vector<std::vector<bits16>> profile = get_profile(genes);
  std::vector<discrete> colcand(cols, 0);

  /* add columns satisfy the conservative r */
  const int cnt = seed_current_modify(genes, profile, colcand);
  double tolerance = floor(cnt * po->TOLERANCE);

  b->core_rownum = b->genes.size();  /* row number of core */
  b->core_colnum = cnt; /* col number of core */

  std::vector<bool> candidates(rows, true);
  for (auto gene : genes) {
    candidates[gene] = false;
  }
  add_possible_genes(b, colcand, tolerance, candidates);

  b->block_rows_pre = b->genes.size();
  scan_block(b);

  add_negative_genes(b, colcand, tolerance, candidates);
}

template <typename Block>
std::vector<discrete> get_common_genes(const std::unique_ptr<Block> &b) {
  std::vector<discrete> common_genes(rows, 0);
  for (auto gene : b->genes) {
    common_genes[gene] = arr_c[gene][b->conds[0]];
  }
  return common_genes;
}

template <typename Block>
std::vector<discrete> get_common_conds(const std::unique_ptr<Block> &b) {
  std::vector<discrete> common_conds(cols, 0);
  for (auto cond : b->conds) {
    common_conds[cond] = arr_c[b->genes[0]][cond];
  }
  return common_conds;
}

template <typename Block>
std::vector<std::size_t>
get_possible_genes_in_dual_core(const std::unique_ptr<Block> &b,
                                const std::vector<discrete> &common_conds,
                                const double x) {
  std::vector<std::size_t> genes;
  for (int row = 0; row < rows; row++) {
    int count = intersect_row(common_conds, arr_c[row]);
    if (count > b->conds.size() * x &&
        std::find(b->genes.begin(), b->genes.end(), row) == b->genes.end())
      genes.push_back(row);
  }
  return genes;
}

template <typename Block>
std::vector<std::size_t>
get_possible_conds_in_dual_core(const std::unique_ptr<Block> &b,
                                const std::vector<discrete> &common_genes,
                                const double x) {
  std::vector<std::size_t> conds;
  for (int col = 0; col < cols; col++) {
    int count = 0;
    for (int row = 0; row < rows; row++)
      if (common_genes[row] != 0 && common_genes[row] == arr_c[row][col])
        count++;
    if (count > b->genes.size() * x &&
        std::find(b->conds.begin(), b->conds.end(), col) == b->conds.end())
      conds.push_back(col);
  }
  return conds;
}

std::vector<discrete>
init_common_colcand(const std::vector<int> &genes,
                    const std::vector<bool> &possible_conds) {
  std::vector<discrete> colcand = init_colcand(genes);

  for (int col = 0; col < cols; col++) {
    if (!possible_conds[col])
      colcand[col] = 0;
  }

  return colcand;
}

struct {
  bool operator()(const std::unique_ptr<Edge> &a,
                  const std::unique_ptr<Edge> &b) const {
    return a->score > b->score;
  }
} scoreGreater;

template <typename Block>
std::unique_ptr<Block1> get_dual_core(const std::unique_ptr<Block> &b) {
  std::vector<discrete> common_conds = get_common_conds(b);
  std::vector<discrete> common_genes = get_common_genes(b);
  double cutoff = 0.80;
  std::vector<std::size_t> possible_genes_vector =
      get_possible_genes_in_dual_core(b, common_conds, cutoff);

  std::vector<std::size_t> possible_conds_vector =
      get_possible_conds_in_dual_core(b, common_genes, cutoff);

  std::vector<bool> possible_genes(rows);

  for (auto index : possible_genes_vector) {
    possible_genes[index] = true;
  }

  std::vector<bool> possible_conds(cols);

  for (auto index : possible_conds_vector) {
    possible_conds[index] = true;
  }

  if (possible_genes_vector.size() < 2)
    return nullptr;

  std::vector<std::unique_ptr<Edge>> edge_list;
  for (auto it = possible_genes_vector.begin();
       it != std::prev(possible_genes_vector.end()); ++it) {
    for (auto jt = std::next(it); jt != possible_genes_vector.end(); ++jt) {
      int count = 0;
      for (auto index : possible_conds_vector) {
        if (arr_c[*it][index] != 0 && arr_c[*it][index] == arr_c[*jt][index])
          count++;
      }
      edge_list.emplace_back(new Edge(*it, *jt, count));
    }
  }

  std::stable_sort(edge_list.begin(), edge_list.end(), scoreGreater);

  int best_score = -1;
  std::unique_ptr<Block1> best_dual = nullptr;
  int max = 50;
  for (const auto &edge : edge_list) {
    std::unique_ptr<Block1> block(new Block1());

    /*initial the b->score*/
    block->score = std::min(2, static_cast<int>(edge->score));
    block->genes.push_back(edge->gene_one);
    block->genes.push_back(edge->gene_two);

    auto &genes = block->genes;

    std::vector<discrete> colcand = init_common_colcand(genes, possible_conds);

    std::vector<bool> candidates(possible_genes);
    candidates[edge->gene_one] = false;
    candidates[edge->gene_two] = false;

    update_block(block, colcand, candidates, 1, 2);

    if (block->score > best_score) {
      best_score = block->score;
      if (best_dual != nullptr)
        best_dual.reset();
      best_dual = std::move(block);
    } else {
      block.reset();
    }
    max--;
    if (max == 0)
      break;
  }

  if (best_dual != nullptr) {
    assert(best_dual->conds.size() == 0);
    assert(best_dual->genes.size() > 0);
    block_expand(best_dual);
    best_dual->genes.erase(
        std::remove_if(best_dual->genes.begin(), best_dual->genes.end(),
                       [&possible_genes](int x) { return !possible_genes[x]; }),
        best_dual->genes.end());
    best_dual->conds.erase(
        std::remove_if(best_dual->conds.begin(), best_dual->conds.end(),
                       [&possible_conds](int x) { return !possible_conds[x]; }),
        best_dual->conds.end());
    if (best_dual->conds.size() == 0)
      return nullptr;
    assert(best_dual->genes.size() > 0);
  }

  return best_dual;
}

/************************************************************************/
/* Core algorithm */
template <typename Block>
int cluster(FILE *fw, const std::vector<std::unique_ptr<Edge>> &edge_list) {
  std::vector<std::unique_ptr<Block>> bb;
  std::size_t allocated = po->SCH_BLOCK;
  bb.reserve(allocated);

  std::vector<bool> allincluster(rows, false);

  /* branch-and-cut condition for seed expansion */
  int cand_threshold = floor(po->COL_WIDTH * po->TOLERANCE);
  if (cand_threshold < 2)
    cand_threshold = 2;

  for (const auto &e : edge_list) {
    if (are_genes_in_blocks(e, allincluster))
      continue;

    /*you must allocate a struct if you want to use the pointers related to it*/
    std::unique_ptr<Block> b(new Block());

    /*initial the b->score*/
    b->score = std::min(2, static_cast<int>(e->score));
    b->genes.push_back(e->gene_one);
    b->genes.push_back(e->gene_two);

    /* expansion step, generate a bicluster without noise */
    block_init(b, po->COL_WIDTH, cand_threshold);

    block_expand(b);

    if (po->IS_cond) {
      std::unique_ptr<Block1> best_dual = std::move(get_dual_core(b));

      if (best_dual != nullptr) {
        b->genes.insert(b->genes.end(), best_dual->genes.begin(),
                        best_dual->genes.end());
        b->conds.insert(b->conds.end(), best_dual->conds.begin(),
                        best_dual->conds.end());

        best_dual.reset();
      }
    }

    for (auto gene : b->genes)
      allincluster[gene] = true;
    /*save the current block b to the block list bb so that we can sort the
     * blocks by their score*/
    bb.push_back(std::move(b));

    /* reaching the results number limit */
    if (bb.size() == po->SCH_BLOCK)
      break;
    verboseDot();
  }
  /* writes character to the current position in the standard output (stdout)
   * and advances the internal file position indicator to the next position. It
   * is equivalent to putc(character,stdout).*/
  putchar('\n');

  sort_block_list(bb);
  const int blocks = report_blocks(fw, bb, bb.size());
  return blocks;
}

template int
cluster<Block>(FILE *fw, const std::vector<std::unique_ptr<Edge>> &edge_list);
template int
cluster<Block1>(FILE *fw, const std::vector<std::unique_ptr<Edge>> &edge_list);

/************************************************************************/
static void print_params(FILE *fw) {
  char filedesc[LABEL_LEN];
  strcpy(filedesc, "continuous");
  if (po->IS_DISCRETE)
    strcpy(filedesc, "discrete");
  fprintf(fw, "# QUBIC version %.1f output\n", VER);
  fprintf(fw, "# Datafile %s: %s type\n", po->FN, filedesc);
  fprintf(fw, "# Parameters: -k %d -f %.2f -c %.2f -o %zu", po->COL_WIDTH,
          po->FILTER, po->TOLERANCE, po->RPT_BLOCK);
  if (!po->IS_DISCRETE)
    fprintf(fw, " -q %.2f -r %d", po->QUANTILE, po->DIVIDED);
  fprintf(fw, "\n\n");
}

/************************************************************************/
template <typename Block>
int report_blocks(FILE *fw, const std::vector<std::unique_ptr<Block>> &bb,
                  const std::size_t num) {
  print_params(fw);

  const int n = std::min(num, po->RPT_BLOCK);

  std::size_t *output = new std::size_t[n];

  std::size_t *bb_ptr = output;

  /* the major post-processing here, filter overlapping blocks*/
  std::size_t i = 0;
  int j = 0;
  while (i < num && j < n) {
    int index = i;
    const double cur_rows = bb[index]->genes.size();
    const double cur_cols = bb[index]->conds.size();

    bool flag = TRUE;
    int k = 0;
    while (k < j) {
      const double inter_rows =
          dsIntersect(bb[output[k]]->genes, bb[index]->genes);
      const double inter_cols =
          dsIntersect(bb[output[k]]->conds, bb[index]->conds);

      if (inter_rows * inter_cols > po->FILTER * cur_rows * cur_cols) {
        flag = FALSE;
        break;
      }
      k++;
    }
    i++;
    if (flag) {
      print_bc(fw, bb[index], j++);
      *bb_ptr++ = index;
    }
  }
  delete[] output;
  return j;
}

/************************************************************************/
template <typename Block>
void sort_block_list(std::vector<std::unique_ptr<Block>> &el) {
  struct {
    bool operator()(const std::unique_ptr<Block> &a,
                    const std::unique_ptr<Block> &b) const {
      return (a->genes.size()> a->conds.size()? a->conds.size():a->genes.size()) > (b->genes.size()> b->conds.size()? b->conds.size():b->genes.size()) ;
    }
  } scoreGreater;
  std::stable_sort(el.begin(), el.end(), scoreGreater);
}

/************************************************************************/

long double get_pvalue(const continuous a, const int b) {
  const long double one = 1;
  long double pvalue = 0;
  long double poisson = one / exp(a);
  for (int i = 0; i < b + 300; i++) {
    if (i > (b - 1))
      pvalue = pvalue + poisson;
    else
      poisson = poisson * a / (i + 1);
  }
  return pvalue;
}
