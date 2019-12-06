/* Author: Qin Ma <maqin@uga.edu>, Step. 19, 2013
 * Usage: This is part of the bicluster package. Use, redistribute, modify
 *        without limitations.
 *
 * Produces two graphs sequentially, derived from microarray data.
 *
 * The first graph is generated from the raw data where an edge is defined
 * as two genes having common components from same condition, the score on
 * the edge being the number of the same components. The edges in the first
 * graph, are used as vertices in the second graph, where edges are defined
 * as the common columns between two co-vertex edges in the first graph,
 * with scores defined as the number of same columns for all three genes.
 *
 */

#include "make_graph.h"
#include "cluster.h"
#include "read_array.h"
#include <algorithm>
#include <vector>

static const int DEFAULT_SEED_CAPACITY = 20000000;

/**************************************************************************/
/* String intersection function without string copying, only numbers */
/*caculate the weight of the edge in the first graph*/
static int str_intersect_r(const discrete *s1, const discrete *s2) {
  int common_cnt = 0;
  for (int i = 0; i < cols; i++) {
    if (*s1 == *s2 && *s1 != 0)
      common_cnt++;
    s1++;
    s2++;
  }
  return common_cnt;
}

/**************************************************************************/
continuous get_pearson(const discrete *s1, const discrete *s2, const int row_1,
                       const int row_2, int cnt) {
  continuous ss1[cnt], ss2[cnt];
  continuous score = 0, ave1 = 0, ave2 = 0, var1 = 0, var2 = 0;
  const continuous cntc = cnt;
  int index = 0;
  for (int i = 0; i < cols; i++) {
    if (s1[i] == s2[i] && (s1[i] != 0)) {
      ss1[index] = arr[row_1][i];
      ss2[index] = arr[row_2][i];
      index++;
    }
    i++;
  }
  /*get var and ave*/
  for (int j = 0; j < cnt; j++) {
    ave1 += ss1[j];
    ave2 += ss2[j];
  }
  ave1 = ave1 / cntc;
  ave2 = ave2 / cntc;
  for (int j = 0; j < cnt; j++) {
    var1 += (ss1[j] - ave1) * (ss1[j] - ave1);
    var2 += (ss2[j] - ave2) * (ss2[j] - ave2);
  }
  var1 = sqrt(var1);
  var2 = sqrt(var2);
  for (int i = 0; i < cnt; i++)
    score += (ss1[i] - ave1) * (ss2[i] - ave2);
  score = fabs(score / (var1 * var2));
  return score;
}
/**************************************************************************/
continuous get_spearman(discrete *s1, discrete *s2, const int row_1,
                        const int row_2, int cnt) {
  discrete ss1[cnt], ss2[cnt];
  continuous ss11[cnt], ss22[cnt], temp1[cnt], temp2[cnt];
  continuous score = 0, ave1 = 0, ave2 = 0, var1 = 0, var2 = 0;
  const continuous cntc = cnt;
  int index = 0;
  for (int i = 0; i < cols; i++) {

    if (symbols[s1[i]] == symbols[s2[i]] && (s1[i] != 0)) {
      ss11[index] = arr[row_1][i];
      ss22[index] = arr[row_2][i];
      temp1[index] = arr[row_1][i];
      temp2[index] = arr[row_2][i];
      index++;
    }
  }
  qsort(temp1, cnt, sizeof *temp1, compare_continuous);
  for (int i = 0; i < cnt; i++) {
    ss1[i] = 0;
    for (int j = 0; j < cnt; j++) {
      if (ss11[i] == temp1[j])
        ss1[i] = j;
    }
  }
  qsort(temp2, cnt, sizeof *temp2, compare_continuous);
  for (int i = 0; i < cnt; i++) {
    ss2[i] = 0;
    for (int j = 0; j < cnt; j++)
      if (ss22[i] == temp2[j])
        ss2[i] = j;
  }
  /*get var and ave*/
  for (int j = 0; j < cnt; j++) {
    ave1 += ss1[j];
    ave2 += ss2[j];
  }
  ave1 = ave1 / cntc;
  ave2 = ave2 / cntc;
  for (int j = 0; j < cnt; j++) {
    var1 += (ss1[j] - ave1) * (ss1[j] - ave1);
    var2 += (ss2[j] - ave2) * (ss2[j] - ave2);
  }
  var1 = sqrt(var1);
  var2 = sqrt(var2);
  for (int i = 0; i < cnt; i++)
    score += (ss1[i] - ave1) * (ss2[i] - ave2);
  score = fabs(score / (var1 * var2));
  return score;
}

/*****************************************************************************/

/* sort using a custom function object */
struct {
  bool operator()(const std::unique_ptr<Edge> &a,
                  const std::unique_ptr<Edge> &b) const {
    return a->score > b->score;
  }
} scoreGreater;

/*calculate the F-score*/
continuous get_f_socre(const continuous a, const continuous b,
                       const continuous c) {
  const continuous z1 = a / b;
  const continuous z2 = a / c;
  return 2 * z1 * z2 / (z1 + z2);
}

/**************************************************************************/

void make_graph(const char *fn) {
  std::vector<std::unique_ptr<Edge>> edge_list;
  FILE *fw = mustOpen(fn, "w");
  if (po->COL_WIDTH == 2)
    po->COL_WIDTH = std::max(cols / 20, 2);

  /* edge_ptr describe edges */
  edge_list.reserve(DEFAULT_SEED_CAPACITY);

  /* Generating seed list and push into heap */
  progress("Generating seed list (minimum weight %d)", po->COL_WIDTH);

  Edge __cur_min = {0, 0, static_cast<edge_scroe_t>(po->COL_WIDTH)};
  Edge *_cur_min = &__cur_min;
  Edge **cur_min = &_cur_min;
  /* iterate over all genes to retrieve all edges */
  for (int row1 = 0; row1 < rows; row1++) {
    for (int row2 = row1 + 1; row2 < rows; row2++) {
      int cnt = str_intersect_r(arr_c[row1], arr_c[row2]);
      const int cnt1 = str_intersect_r(arr_c[row1], arr_c[row1]);
      const int cnt2 = str_intersect_r(arr_c[row2], arr_c[row2]);
      if (po->IS_spearman && cnt > 5) {
        /*get spearman rank corelation*/
        const continuous spearman =
            get_spearman(arr_c[row1], arr_c[row2], row1, row2, cnt);
        const continuous fscore = get_f_socre(cnt, cnt1, cnt2);
        const int cnt3 = cnt;
        cnt = ceil(2 * cnt3 * spearman * fscore);
        const continuous final = 2 * cnt3 * spearman * fscore;
        printf("%s\t%s\t%d\t%d\t%d\t%.2f\t%.2f\t%.2f\n", genes_n[row1],
               genes_n[row2], cnt3, cnt1, cnt2, fscore, spearman, final);
      }

      if (cnt < (*cur_min)->score)
        continue;

      edge_list.emplace_back(new Edge(row1, row2, cnt));
    }
  }
  const int rec_num = edge_list.size();
  if (rec_num == 0)
    errAbort("Not enough overlap between genes");

  /* sort the seeds */
  uglyTime("%d seeds generated", rec_num);
  std::stable_sort(edge_list.begin(), edge_list.end(), scoreGreater);

  /* bi-clustering */
  int n_blocks;
  progress("Clustering started");
  if (po->IS_MaxMin)
    n_blocks = cluster<Block1>(fw, edge_list);
  else
    n_blocks = cluster<Block>(fw, edge_list);
  fclose(fw);
  uglyTime("%d clusters are written to %s", n_blocks, fn);
}

/***************************************************************************/
