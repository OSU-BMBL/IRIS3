/*
 * Author:Qin Ma <maqin@csbl.bmb.uga.edu>, Jan. 24, 2010
 * Usage: This is part of the bicluster package. Use, redistribute, modify
 * without limitations.
 *
 * Include two procedures for file input:
 * o read_continuous() would read a file with this format:
 * ----------------------------------------
 * 	 	cond1	 cond2	 cond3
 * 	gene1    3.14	  -1.2     0.0
 * 	gene2      nd      2.8     4.5
 * ----------------------------------------
 *   values may possibly be any continuous value, e.g. log-ratio of
 *   lumin intensity for two channels. The procedure then, for each
 *   row, produces a distribution using method similar to outlier algorithm,
 *   base on two tails of values (6%),
 *   the middle part, is regarded as insignificant. This would discretize
 *   the continuous value into classes. (If you want divide the data into
 *   more levels, you can adjust the parameter r and q) See below.
 *
 * o read_discrete() would read a file with format like:
 * ----------------------------------------
 *  		cond1	 cond2	 cond3
 *  	gene1	    1        1       0
 *  	gene2       1       -1       0
 * ----------------------------------------
 *   the symbols could be any integers (-32768~+32767) and represent distinct
 * classes. '0', however, will be ignored, and uncounted in the alter
 * algorithms. since they would represent a no-change class.
 */

#include "read_array.h"

/************************************************************************/
/* Helper variables for tokenizer function */

static char *atom = NULL;
static char delims[] = "\t\r\n";
#define MAXC 100000
/* record the position of each discretized symbol in _symbols_ */
/* an unsigned short can hold all the values between 0 and  USHRT_MAX inclusive.
 * USHRT_MAX must be at least 65535*/
static int bb[USHRT_MAX];

/***********************************************************************/

/* Comparison function for GNU qsort */
int compare_continuous(const void *a, const void *b) {
  const continuous *da = static_cast<const continuous *>(a);
  const continuous *db = static_cast<const continuous *>(b);
  /*make qsort in the increasing order*/
  return (*da < *db) ? -1 : (*da != *db);
}
/* emulate gnu gsl quantile function */
/*divide by the number of the data*/
static continuous quantile_from_sorted_data(const continuous sorted_data[],
                                            const std::size_t n,
                                            const double f) {
  /*floor function returns the largest integral value less than or equal to x*/
  const int i = floor((n - 1) * f);
  const continuous delta = (n - 1) * f - i;
  return (1 - delta) * sorted_data[i] + delta * sorted_data[i + 1];
}
/***********************************************************************/

static int charset_add(discrete *ar, const discrete s) {
  /*A signed short can hold all the values between SHRT_MIN  and SHRT_MAX
   * inclusive.SHRT_MIN is required to be -32767 or less,SHRT_MAX must be at
   * least 32767*/
  const int ps = s + SHRT_MAX;
  if (bb[ps] < 0) {
    bb[ps] = sigma;
    ar[sigma++] = s;
  }
  return bb[ps];
}

/***********************************************************************/

/* Matrix allocations (continuous and discrete 2d array) */

continuous **alloc2d(const int rr, const int cc) {
  continuous **result = new continuous *[rr];
  for (int i = 0; i < rr; i++)
    result[i] = new continuous[cc];
  return result;
}

discrete **alloc2c(const int rr, const int cc) {
  discrete **result = new discrete *[rr];
  for (int i = 0; i < rr; i++)
    result[i] = new discrete[cc];
  return result;
}

/***********************************************************************/

/* Pre-read the datafile, retrieve gene labels and condition labels
 * as well as determine the matrix size
 */
void get_matrix_size(FILE *fp) {
  /*std::size_t is the best type to use if you want to represent sizes of
   * objects. Using int to represent object sizes is likely to work on most
   * modern systems, but it isn't guaranteed.
   */
  std::size_t n = 0;
  char *line = NULL;
  /*getline() reads an entire line, storing the address of the buffer containing
   *the text into *line. the buffer is null-terminated and includes the newline
   *character, if a newline delimiter was found.
   */
  if (getline(&line, &n, fp) >= 0) {
    /*strtok function returns a pointer to the next token in str1, where str2
     * contains the delimiters that determine the token*/
    atom = strtok(line, delims);
    /*delete the first element in atom because the first element corresponding
     * to description column*/
    atom = strtok(NULL, delims);
    while (atom != NULL) {
      /*if we do not set atom = strtok(NULL, delims), here is a infinite loop*/
      atom = strtok(NULL, delims);
      cols++;
    }
  }
  while (getline(&line, &n, fp) >= 0) {
    atom = strtok(line, delims);
    rows++;
  }
  /*fseed sets the position indicator associated with the stream to a new
   * position defined by adding offset to a reference position specified by
   * origin*/
  fseek(fp, 0, 0);
  free(line);
}

/* Read in the labels on x and y, in microarray terms, genes(rows) and
 * conditions(cols)*/
void read_labels(FILE *fp) {
  int row = 0;
  std::size_t n = 0;
  char *line = NULL;
  while (getline(&line, &n, fp) >= 0) {
    atom = strtok(line, delims);
    /*currently the first element in atom is the gene name of each row when
     * row>=1, the 0 row corresponding to the line of condition names*/
    if (row >= 1) {
      strcpy(genes_n[row - 1], atom);
    }
    /*delete the first element in atom because the first element corresponding
     * to description column*/
    atom = strtok(NULL, delims);
    int col = 0;
    while (atom != NULL) {
      if (row == 0)
        strcpy(conds_n[col], atom);
      atom = strtok(NULL, delims);
      if (++col == cols)
        break;
    }
    if (++row == rows + 1)
      break;
  }
  fseek(fp, 0, 0);
  free(line);
}

/*read in the sub-gene list*/
void read_list(FILE *fp) {
  int i;
  sub_genes_row = 0;
  char line[MAXC];
  while (fgets(line, MAXC, fp) != NULL) {
    atom = strtok(line, delims);
    strcpy(sub_genes[sub_genes_row], atom);
    sub_genes_row++;
  }

  /*update the sub_list*/
  sublist = new bool[rows];
  for (i = 0; i < rows; i++)
    sublist[i] = FALSE;
  for (i = 0; i < sub_genes_row; i++)
    for (int j = 0; j < rows; j++)
      if (strcmp(sub_genes[i], genes_n[j]) == 0)
        sublist[j] = TRUE;
}

/* initialize data for discretization */
void init_dis() {
  /* store discretized values */
  symbols = new discrete[USHRT_MAX];
  /* memset sets the first num bytes of the block of memory pointed by ptr to
   * the specified value memset ( void * ptr, int value, std::size_t num )*/
  memset(bb, -1, USHRT_MAX * sizeof(*bb));
  /* always add an 'ignore' index so that symbols[0]==0*/
  charset_add(symbols, 0);
  /*initialize for arr_c*/
  arr_c = alloc2c(rows, cols);
  for (int row = 0; row < rows; row++)
    for (int col = 0; col < cols; col++)
      arr_c[row][col] = 0;
}

void read_discrete(FILE *fp) {
  init_dis();
  /* import data */
  std::size_t n = 0;
  char *line = NULL;
  int row = 1;
  /* Skip first line with condition labels */
  if (getline(&line, &n, fp) == -1) {
    errAbort("Error in read_discrete() "
             "while reading the first line");
  }
  /* read the discrete data from the second line */
  while (getline(&line, &n, fp) >= 0) {
    atom = strtok(line, delims);
    /*skip the first column*/
    atom = strtok(NULL, delims);
    int col = 0;
    while (atom != NULL) {
      arr_c[row - 1][col] = charset_add(symbols, atoi(atom));
      atom = strtok(NULL, delims);
      if (++col == cols)
        break;
    }
    if (++row == rows + 1)
      break;
  }
  /* trim the leading spaceholder */
  printf("Discretized data contains %d classes with charset [ ", sigma);
  for (int i = 0; i < sigma; i++)
    /*printf("%d ", symbols[i]); printf("]\n");*/
    printf("%d ", i);
  printf("]\n");
  fseek(fp, 0, 0);
  free(line);
}

void read_continuous(FILE *fp) {
  arr = alloc2d(rows, cols);
  /* import data */
  std::size_t n = 0;
  char *line = NULL;
  int row = 1;
  /* ignore header line */
  if (getline(&line, &n, fp) == -1) {
    errAbort("Error in read_continuous() "
             "while reading the first line");
  }
  while (getline(&line, &n, fp) >= 0) {
    atom = strtok(line, delims);
    /*skip the first column*/
    atom = strtok(NULL, delims);
    int col = 0;
    while (atom != NULL) {
      /*we set all the aplha to ignore value 0*/
      /*Checks if parameter atom is either an uppercase or a lowercase
       * alphabetic letter*/
      if (isalpha(*atom))
        arr[row - 1][col] = 0.0;
      else
        arr[row - 1][col] = atof(atom);
      atom = strtok(NULL, delims);
      if (++col == cols)
        break;
    }
    if (++row == rows + 1)
      break;
  }
  fseek(fp, 0, 0);
  free(line);
}

/***********************************************************************/

/* Discretize continuous values by revised outlier detection algorithm
 * see details in Algorithm Design section in paper
 */
discrete dis_value(const float current, const int divided, float *small,
                   const int cntl, float *big, const int cntu) {
  const float d_space = 1.0 / divided;
  for (int i = 0; i < divided; i++) {
    if ((cntl > 0) &&
        (current <= quantile_from_sorted_data(small, cntl, d_space * (i + 1))))
      return -i - 1;
    if ((cntu > 0) && (current >= quantile_from_sorted_data(
                                      big, cntu, 1.0 - d_space * (i + 1))))
      return i + 1;
  }
  return 0;
}

void discretize(const char *stream_nm) {
  FILE *fw = mustOpen(stream_nm, "w");
  init_dis();
#pragma omp parallel for
  for (int row = 0; row < rows; row++) {
    int col;
    continuous rowdata[cols];
    float big[cols], small[cols];
    float upper, lower;
    for (col = 0; col < cols; col++)
      rowdata[col] = arr[row][col];
    qsort(rowdata, cols, sizeof *rowdata, compare_continuous);
    const float f1 = quantile_from_sorted_data(rowdata, cols, 1 - po->QUANTILE);
    const float f2 = quantile_from_sorted_data(rowdata, cols, po->QUANTILE);
    const float f3 = quantile_from_sorted_data(rowdata, cols, 0.5);
    if ((f1 - f3) >= (f3 - f2)) {
      upper = 2 * f3 - f2;
      lower = f2;
    } else {
      upper = f1;
      lower = 2 * f3 - f1;
    }
    int cntu = 0;
    int cntl = 0;
    for (int i = 0; i < cols; i++) {
      if (rowdata[i] < lower) {
        small[cntl] = rowdata[i];
        cntl++;
      }
      if (rowdata[i] > upper) {
        big[cntu] = rowdata[i];
        cntu++;
      }
    }
    for (col = 0; col < cols; col++)
      arr_c[row][col] =
          charset_add(symbols, dis_value(arr[row][col], po->DIVIDED, small,
                                         cntl, big, cntu));
    if (abs(cntl - cntu) <= 1)
      fprintf(fw,
              "%s_unexpressed :low=%2.5f, up=%2.5f; %d down-regulated,%d "
              "up-regulated\n",
              genes_n[row], lower, upper, cntl, cntu);
    else
      fprintf(fw,
              "%s :low=%2.5f, up=%2.5f; %d down-regulated,%d up-regulated\n",
              genes_n[row], lower, upper, cntl, cntu);
  }
  progress("Discretization rules are written to %s", stream_nm);
  fclose(fw);
}

/* output the formatted matrix */
void write_imported(const char *stream_nm) {
  int col;
  FILE *fw = mustOpen(stream_nm, "w");
  fprintf(fw, "o");
  for (col = 0; col < cols; col++)
    fprintf(fw, "\t%s", conds_n[col]);
  fputc('\n', fw);
  for (int row = 0; row < rows; row++) {
    fprintf(fw, "%s", genes_n[row]);
    for (col = 0; col < cols; col++)
      fprintf(fw, "\t%d", symbols[arr_c[row][col]]);
    fputc('\n', fw);
  }
  progress("Formatted data are written to %s", stream_nm);
  fclose(fw);
}

/***********************************************************************/
continuous get_KL(const std::vector<discrete> &array,
                  discrete *array_background, const int a, const int b) {
  int i, j;
  std::vector<continuous> num(sigma, 0), num_b(sigma, 0);
  continuous IC = 0;
  for (i = 0; i < sigma; i++) {
    for (j = 0; j < a; j++)
      if (symbols[array[j]] == symbols[i])
        num[i]++;
    for (j = 0; j < b; j++)
      if (symbols[array_background[j]] == symbols[i])
        num_b[i]++;
  }
  for (i = 0; i < sigma; i++) {
    if (num[i] == 0)
      continue;
    if (num_b[i] == 0)
      continue;
    IC += (num[i] / a) * log2((num[i] * b) / (num_b[i] * a));
  }
  return IC;
}
/***********************************************************************/
/*new descretization way based on mixture normal distribution*/
double NormSDist(double x, double a, const double b) {
  /* Cumulative Distribution Function */
  x -= a;
  x /= b;
  if (x > 6)
    return 1;
  if (x < -6)
    return 0.000001;
  ;
  static const double gamma = 0.231641900, a1 = 0.319381530, a2 = -0.356563782,
                      a3 = 1.781477973, a4 = -1.821255978, a5 = 1.330274429;
  const double k = 1.0 / (1 + fabs(x) * gamma);
  double n = k * (a1 + k * (a2 + k * (a3 + k * (a4 + k * a5))));
  a = x;
  a = exp((-1) * a * a / 2) * 0.39894228040143267793994605993438;
  n = 1 - a * n;
  if (x < 0)
    return 1.0 - n;
  return n;
}

double densityFuction(double x, const double a, const double d) {
  /* Probability Density Function */
  x = -1 * (x - a) * (x - a) / (2 * d * d);
  x = exp(x);
  x *= 0.39894228040143267793994605993438;
  x /= d;
  return x;
}

FILE *open(const char *src) {
  char filename[84];
  strcpy(filename, po->FN);
  strcat(filename, src);
  return fopen(filename, "w");
}

void discretize_new(const char *stream_nm) {
  FILE *F1 = open(".em.chars");    /*qualitative rows, integers denote the most
                                      likely distribution*/
  FILE *F2 = open(".chars"); /*qualitative matrix MR*/
  FILE *F3 = open(".original.chars"); /*qualitative rows consisting of -1,0,1, denoting
                                lowly, normally and highly expressed */
  FILE *F4 = open(".rules"); /*store BIC,weight, mean and standard deviation*/
  init_dis();

  discrete **arr_c_d = alloc2c(rows, cols);
  discrete **arr_c_F2 = alloc2c(rows, cols);
  discrete **arr_c_F3 = alloc2c(rows, cols);
  for (auto row = 0; row < rows; row++) {
    for (auto col = 0; col < cols; col++) {
      arr_c_d[row][col] = 0;
      arr_c_F2[row][col] = 0;
      arr_c_F3[row][col] = 0;
    }
  }

  int col;
  fprintf(F1, "o");
  for (col = 0; col < cols; col++)
    fprintf(F1, "\t%s", conds_n[col]);
  fputc('\n', F1);
  fprintf(F2, "o");
  for (col = 0; col < cols; col++)
    fprintf(F2, "\t%s", conds_n[col]);
  fputc('\n', F2);
  fprintf(F3, "o");
  for (col = 0; col < cols; col++)
    fprintf(F3, "\t%s", conds_n[col]);
  fputc('\n', F3);

  /*  distribution based discretization */
#pragma omp parallel for
  for (long long id = 0; id < rows;
       id++) { /*the outmost loop, loop through each gene*/
    double results[10][3][10], table_theta_t1[cols][9], temp, temp1, temp3,
        c[10][cols], BIC2[10], EMold[3];
    int i, j, t[cols], tint, k, EMReason[10], EMBreak[10]; /* <0.001 break */
    int UP = 9, num_d;
    const int DOWN = 1;
    UP++;
    int EM = 9999; /* parameter with default value being 20 or 150 */
    EM--;
    for (i = 0; i < cols; i++)
      t[i] = i; /* sort by natural numbers */
    for (i = 0; i < cols; i++) {
      for (j = i; j < cols; j++) {
        if (arr[id][t[i]] > arr[id][t[j]]) {
          tint = t[i];
          t[i] = t[j];
          t[j] = tint;
        }
      }
    }
    for (j = 0; j < 10; j++) {
      EMBreak[j] = -1;
      EMReason[j] = 1;
      BIC2[j] = -1;
      for (i = 0; i < 10; i++) {
        results[j][0][i] = -1;
        results[j][1][i] = -1;
        results[j][2][i] = -1;
      }
    }

    /*
    This num_d loop fit data using mixutre of 1~9 normal distribution,
    respectively. num_d is the # of distributions In each loop, use EM algorithm
    to calculate the weight,mean and sd for each component distribution e.g.,
    num_d=4, fit data using mixture of 4 normal distributions, then the interest
    is the weight,mean and sd for every component distribution
    */

    for (num_d = DOWN; num_d < UP; num_d++) {
      double m = 0;
      for (i = 0; i < cols; i++)
        m += arr[id][t[i]]; /* the sum of one row */
      m /= cols;            /* the mean of one row */
      double temp2 = 0;
      for (i = 0; i < cols; i++) {
        /* the square of the difference between the sample and the expectation
         */
        temp1 = arr[id][t[i]]; /*xi-mean(x)*/
        temp1 -= m;
        temp1 *= temp1;
        temp2 += temp1;
      }
      temp2 /= (cols - 1); /* unbiased estimated variance */
      const double d =
          sqrt(temp2); /* unbiased estimated standard deviation of one row */
      for (j = num_d; j < 10; j++)
        for (i = 0; i < 10; i++) {
          results[j][0][i] = 1;
          results[j][0][i] /= num_d; /* default weights */
          tint = cols * (i + 1) / (num_d + 1) - 1;
          if (tint >= cols)
            tint = cols - 1;
          results[j][1][i] = arr[id][t[tint]];
          /* Divide-and-Conquer */
          results[j][2][i] = d; /* default standard deviation */
        }
      if (num_d > 2) {
        results[num_d][1][0] = arr[id][t[0]];
        for (i = num_d - 1; i < 10; i++)
          results[num_d][1][i] = arr[id][t[cols - 1]];
      }
      for (int INDEX = 0; INDEX < EM; INDEX++) {
        EMold[0] = -1;
        EMold[1] = -1;
        EMold[2] = -1;
        for (i = 0; i < 10; i++)
          results[0][1][i] = results[num_d][1][i];
        EMold[0] += 1;
        EMold[1] += 1;
        EMold[2] += 1;
        for (i = 0; i < 10; i++) {
          if (results[num_d][0][i] < 0)
            EMold[0] -= results[num_d][0][i];
          else if (results[num_d][0][i] > 0)
            EMold[0] += results[num_d][0][i];
          if (results[num_d][1][i] < 0)
            EMold[1] -= results[num_d][1][i];
          else if (results[num_d][1][i] > 0)
            EMold[1] += results[num_d][1][i];
          if (results[num_d][2][i] < 0)
            EMold[2] -= results[num_d][2][i];
          else if (results[num_d][2][i] > 0)
            EMold[2] += results[num_d][2][i];
        }
        EMBreak[num_d] = INDEX;
        /* ROUNDs 20 or ROUNDs 150 */
        for (i = 0; i < cols; i++)
          for (j = 0; j < num_d; j++) {
            temp = densityFuction(arr[id][t[i]], results[num_d][1][j],
                                  results[num_d][2][j]);
            temp *= results[num_d][0][j];
            temp2 = 0;
            for (tint = 0; tint < num_d; tint++) {
              temp1 = densityFuction(arr[id][t[i]], results[num_d][1][tint],
                                     results[num_d][2][tint]);
              temp1 *= results[num_d][0][tint];
              temp2 += temp1;
            }
            temp /= temp2;
            table_theta_t1[i][j] = temp;
          }
        for (i = 0; i < num_d; i++) {
          temp = 0;
          for (j = 0; j < cols; j++) {
            temp += table_theta_t1[j][i];
          }
          temp /= cols;
          results[num_d][0][i] = temp; /* calculate weight*/
          temp = 0;
          for (j = 0; j < cols; j++)
            temp += (arr[id][t[j]] * table_theta_t1[j][i]);
          temp /= cols;
          temp /= results[num_d][0][i];
          results[num_d][1][i] = temp; /* calculate mean*/
          temp = 0;
          for (j = 0; j < cols; j++) {
            temp1 = arr[id][t[j]];
            temp1 -= results[0][1][i];
            temp1 *= temp1;
            temp1 *= table_theta_t1[j][i];
            temp += temp1;
          }
          temp /= cols;
          temp /= results[num_d][0][i];
          temp = sqrt(temp);
          results[num_d][2][i] = temp; /* calculate standard deviation*/
        }

        EMold[0] *= -1;
        EMold[1] *= -1;
        EMold[2] *= -1;
        for (i = 0; i < 10; i++) {
          if (results[num_d][0][i] < 0)
            EMold[0] -= results[num_d][0][i];
          else if (results[num_d][0][i] > 0)
            EMold[0] += results[num_d][0][i];
          if (results[num_d][1][i] < 0)
            EMold[1] -= results[num_d][1][i];
          else if (results[num_d][1][i] > 0)
            EMold[1] += results[num_d][1][i];
          if (results[num_d][2][i] < 0)
            EMold[2] -= results[num_d][2][i];
          else if (results[num_d][2][i] > 0)
            EMold[2] += results[num_d][2][i];
        }
        temp = 0;
        for (i = 0; i < 3; i++)
          temp += EMold[i];
        if (temp < 0)
          temp *= -1;
        EMBreak[num_d] = INDEX + 1;
        if ((INDEX > 150) && (temp < 0.000001)) {
          EMReason[num_d] = 3;
          break;
        }
      }
      /*#################################################################*/
      /*###############     calculate  BIC2   ###########################*/
      temp3 = 0;
      k = num_d * 3;
      for (i = 0; i < cols; i++) {
        temp2 = 0;
        for (j = 0; j < num_d; j++) {
          if (results[num_d][2][j] > 0.000001)
            temp1 = densityFuction(arr[id][i], results[num_d][1][j],
                                   results[num_d][2][j]) *
                    results[num_d][0][j];
          else
            temp1 = 0.000001;
          temp2 += temp1;
        }
        temp3 += log(temp2);
      }
      const double kk = k * log(cols);
      temp3 *= 2;
      temp3 -= kk;
      BIC2[num_d] = temp3;
    }
    /*###############################################################*/
    /*###########  find the num_d that maximize BIC2  ################*/
    temp = BIC2[1];
    int tint2 = 1;
    for (num_d = DOWN + 1; num_d < UP; num_d++)
      if (temp < BIC2[num_d]) {
        temp = BIC2[num_d];
        tint2 = num_d;
      }
    num_d = tint2;
    /*########################################################*/
    /*##################### New sort part for predicted mean */
    /* sort results[num_d][1][i] in increasing order, and adjust the orders of
     * corresponding weight and sd accordingly */
    double zc_m;
    /*if (num_d > 2) {  */ /*comment out 0730 xiej*/
    if (num_d > 1) {       /*add 0730 xiej*/
      for (i = (num_d - 1); i > 0; i--) {
        for (j = 0; j <= i; j++) {
          if (results[num_d][1][j] > results[num_d][1][j + 1]) {
            zc_m = results[num_d][1][j + 1];
            results[num_d][1][j + 1] = results[num_d][1][j];
            results[num_d][1][j] = zc_m;
            zc_m = results[num_d][2][j + 1];
            results[num_d][2][j + 1] = results[num_d][2][j];
            results[num_d][2][j] = zc_m;
            zc_m = results[num_d][0][j + 1];
            results[num_d][0][j + 1] = results[num_d][0][j];
            results[num_d][0][j] = zc_m;
          }
        }
      }
    }
    /*##############################################################*/
    /*   .rules   */
    fprintf(F4, "\n#%s\tK=%d\tIteration=%d_%d\tM\tBIC=%lf\n", genes_n[id],
            num_d, EMBreak[num_d], EMReason[num_d], BIC2[num_d]);
    /*print the weight, mean and sd for each i, i =1,...9 */
    for (i = 1; i < 10; i++) {
      fprintf(F4, "The number of Null dist : %d\t\n", i);
      fprintf(F4, "A or proportion : \t");
      for (j = 0; j < i; j++)
        fprintf(F4, "%lf\t", results[i][0][j]);
      fprintf(F4, "\nu or mean : \t");
      for (j = 0; j < i; j++)
        fprintf(F4, "%lf\t", results[i][1][j]);
      fprintf(F4, "\nsig or sigma : \t");
      for (j = 0; j < i; j++)
        fprintf(F4, "%lf\t", results[i][2][j]);
      fprintf(F4, "\n");
    }
    /*print 9 BIC and the optimum one and corresponding A,u,sig*/
    fprintf(F4, "\nBIC results : \t");
    for (i = 1; i < 10; i++)
      fprintf(F4, "%lf\t", BIC2[i]);
    fprintf(F4, "\nWhich BIC We Choose : \t%d\n", num_d);
    fprintf(F4, "A or proportion : \t");
    for (i = 0; i < num_d; i++)
      fprintf(F4, "%lf\t", results[num_d][0][i]);
    fprintf(F4, "\nu or mean : \t");
    for (i = 0; i < num_d; i++)
      fprintf(F4, "%lf\t", results[num_d][1][i]);
    fprintf(F4, "\nsig or sigma : \t");
    for (i = 0; i < num_d; i++)
      fprintf(F4, "%lf\t", results[num_d][2][i]);
    fprintf(F4, "\n");

    printf("%d\t%d\n", num_d, cols);

    /*##############################################################*/
    /*store the qubic1.0 discretization output for further use*/
    continuous rowdata[cols];
    float big[cols], small[cols];
    float upper, lower;

    for (int row = 0; row < rows; row++) {
      for (col = 0; col < cols; col++)
        rowdata[col] = arr[row][col];
      qsort(rowdata, cols, sizeof *rowdata, compare_continuous);
      const float f1 =
          quantile_from_sorted_data(rowdata, cols, 1 - po->QUANTILE);
      const float f2 = quantile_from_sorted_data(rowdata, cols, po->QUANTILE);
      const float f3 = quantile_from_sorted_data(rowdata, cols, 0.5);
      if ((f1 - f3) >= (f3 - f2)) {
        upper = 2 * f3 - f2;
        lower = f2;
      } else {
        upper = f1;
        lower = 2 * f3 - f1;
      }
      int cntu = 0;
      int cntl = 0;
      for (i = 0; i < cols; i++) {
        if (rowdata[i] < lower) {
          small[cntl] = rowdata[i];
          cntl++;
        }
        if (rowdata[i] > upper) {
          big[cntu] = rowdata[i];
          cntu++;
        }
      }
      for (col = 0; col < cols; col++) {
        arr_c[row][col] =
            charset_add(symbols, dis_value(arr[row][col], po->DIVIDED, small,
                                           cntl, big, cntu));
        arr_c_d[row][col] = symbols[arr_c[row][col]];
      }
    }
    /*############################################################################
     */
    /* F1 em.chars */
    for (i = 0; i < num_d; i++) {
      for (j = 0; j < cols; j++) {
        c[i][j] = arr[id][j] - results[num_d][1][i];
        c[i][j] *= c[i][j];
        c[i][j] *= -1;
        temp3 = 2 * results[num_d][2][i] * results[num_d][2][i];
        c[i][j] =
            c[i][j] / temp3 + log(results[num_d][0][i] / results[num_d][2][i]);
      }
    } /*c[][] be log(f(x)) for each xj in a row */
    for (i = 0; i < cols; i++) {
      temp1 = c[0][i];
      tint = 1;
      arr_c[id][i] =
          charset_add(symbols, 0); /*initially assign 0 to arr_c[][]*/
      for (j = 0; j < num_d;
           j++) { /* find the distribution with highest likelihood */
        if (temp1 < c[j][i]) {
          temp1 = c[j][i];
          tint = j + 1;
        }
      }
      arr_c[id][i] =
          charset_add(symbols, tint); /*assign to the most likely distribution*/
      if (arr[id][i] < results[num_d][1][0]) /*adjust the assignment based on
                                                relationship with first peak*/
        arr_c[id][i] = charset_add(symbols, 1);
      if (arr[id][i] > results[num_d][1][num_d - 1]) /*adjust the assignment
                                                        based on relationship
                                                        with last peak*/
        arr_c[id][i] = charset_add(symbols, num_d);
    }
    fprintf(F1, "%s", genes_n[id]);
    for (i = 0; i < cols; i++) {
      arr_c_F2[id][i] = arr_c[id][i]; /*arr_c_F2[][] store the output for F2*/
      fprintf(F1, "\t%d", arr_c[id][i]); /*arr_c[][] store the output for F1*/
    }
    fprintf(F1, "\n");
    /*############################################################################*/
    /* F2 split.chars */
    int arr_c_id[10]; /* store the unique nonzero intergers */
    int arr_c_count[10];

    for (i = 0; i < 10; i++) {
      arr_c_id[i] = 0;
      arr_c_count[i] = 0;
    }
    int zc_k = 0;
    for (i = 0; i < cols; i++) {
      zc_m = 0;
      for (j = 0; j < 10; j++) {
        if (arr_c_F2[id][i] == arr_c_id[j]) {
          zc_m++;
        }
      }
      if (zc_m == 0) {
        arr_c_id[zc_k] =
            arr_c_F2[id][i]; /*arr_c_id [] store the unique nonzero integers */
        zc_k++;
      }
      if (arr_c_F2[id][i] != 0) {
        for (j = 0; j < 10; j++) {
          if (arr_c_F2[id][i] == arr_c_id[j]) {
            arr_c_count[j]++; /*arr_c_count store the # of elements for each
                                 nonzero integer*/
          }
        }
      }
    }

    float zc_max = 0;
    int zc_k_F3 = 0; /*zc_k_F3 is the most abundant nonzero integers */
    for (k = 0; k < 10;
         k++) { /* find the # of elements for the most abundant integer*/
      if (arr_c_count[k] > zc_max) {
        zc_max = arr_c_count[k];
        zc_k_F3 = arr_c_id[k];
      }
    }

    if (zc_max >= cols / 2) { /* if one peak is too abundant, use qubic1.0
                                 discretization results to generate
                                 split.chars*/
      for (i = 0; i < 10; i++) {
        arr_c_id[i] = 0;
        arr_c_count[i] = 0;
      }
      zc_k = 0;
      for (i = 0; i < cols; i++) {
        arr_c_F2[id][i] = arr_c_d[id][i];
        if (arr_c_F2[id][i] != 0) {
          zc_m = 0;
          for (j = 0; j < 10; j++) {
            if (arr_c_F2[id][i] == arr_c_id[j]) {
              zc_m++;
            }
          }
          if (zc_m == 0) {
            arr_c_id[zc_k] = arr_c_F2[id][i];
            zc_k++;
          }
        }
      }
    }

    for (i = 0; i < 10; i++) {
      if (arr_c_id[i] != 0) {
        fprintf(F2, "%s_%d", genes_n[id], arr_c_id[i]);
        for (j = 0; j < cols; j++) {
          if (arr_c_F2[id][j] == arr_c_id[i])
            fprintf(F2, "\t1");
          else
            fprintf(F2, "\t0");
        }
        fprintf(F2, "\n");
      }
    }
    printf("\n");
    /*############################################################################*/
    /*   .chars    */
    if (num_d == 1) {
      for (i = 0; i < cols; i++)
        arr_c_F3[id][i] = arr_c_d[id][i]; /*arr_c_F3[][] store F3 output */
    } else {
      for (j = 0; j < cols; j++) {
        if (arr_c[id][j] < zc_k_F3)
          arr_c_F3[id][j] = -1;
        if (arr_c[id][j] == zc_k_F3)
          arr_c_F3[id][j] = 0;
        if (arr_c[id][j] > zc_k_F3)
          arr_c_F3[id][j] = 1;
      }
    }
    fprintf(F3, "%s", genes_n[id]);
    for (j = 0; j < cols; j++)
      fprintf(F3, "\t%d", arr_c_F3[id][j]);
    fprintf(F3, "\n");
  }

  fclose(F1);
  fclose(F2);
  fclose(F3);
  fclose(F4);

  for (auto row = 0; row < rows; row++) {
    delete[] arr_c_d[row];
    delete[] arr_c_F2[row];
    delete[] arr_c_F3[row];
  }
  delete[] arr_c_d;
  delete[] arr_c_F2;
  delete[] arr_c_F3;
}

void discretize_rpkm(const char *stream_nm) {
  FILE *F1 = open(".em.chars");
  FILE *F2 = open(".chars");
  FILE *F3 = open(".original.chars");
  FILE *F4 = open(".rules");
  init_dis();

  discrete **arr_c_d = alloc2c(rows, cols);
  discrete **arr_c_F2 = alloc2c(rows, cols);
  discrete **arr_c_F3 = alloc2c(rows, cols);
  for (auto row = 0; row < rows; row++) {
    for (auto col = 0; col < cols; col++) {
      arr_c_d[row][col] = 0;
      arr_c_F2[row][col] = 0;
      arr_c_F3[row][col] = 0;
    }
  }
  int col;
  fprintf(F1, "o");
  for (col = 0; col < cols; col++)
    fprintf(F1, "\t%s", conds_n[col]);
  fputc('\n', F1);
  fprintf(F2, "o");
  for (col = 0; col < cols; col++)
    fprintf(F2, "\t%s", conds_n[col]);
  fputc('\n', F2);
  fprintf(F3, "o");
  for (col = 0; col < cols; col++)
    fprintf(F3, "\t%s", conds_n[col]);
  fputc('\n', F3);

/*  store qubic1.0 discretization output */
 continuous rowdata[cols];
    float big[cols], small[cols];
    float upper, lower;

    for (int row = 0; row < rows; row++) {
      for (col = 0; col < cols; col++)
        rowdata[col] = arr[row][col];
      qsort(rowdata, cols, sizeof *rowdata, compare_continuous);
      const float f1 =
          quantile_from_sorted_data(rowdata, cols, 1 - po->QUANTILE);
      const float f2 = quantile_from_sorted_data(rowdata, cols, po->QUANTILE);
      const float f3 = quantile_from_sorted_data(rowdata, cols, 0.5);
      if ((f1 - f3) >= (f3 - f2)) {
        upper = 2 * f3 - f2;
        lower = f2;
      } else {
        upper = f1;
        lower = 2 * f3 - f1;
      }
      int cntu = 0;
      int cntl = 0;
      for (int i = 0; i < cols; i++) {
        if (rowdata[i] < lower) {
          small[cntl] = rowdata[i];
          cntl++;
        }
        if (rowdata[i] > upper) {
          big[cntu] = rowdata[i];
          cntu++;
        }
      }
      for (col = 0; col < cols; col++) {
        arr_c[row][col] =
            charset_add(symbols, dis_value(arr[row][col], po->DIVIDED, small,
                                           cntl, big, cntu));
        arr_c_d[row][col] = symbols[arr_c[row][col]];
      }
    } 
   
#pragma omp parallel for
  for (long long id = 0; id < rows; id++) {
    double results[10][3][10], table_theta_t1[cols][10],
        m = 0, d, temp, temp1, temp2, temp3, c[10][cols], cc[10], te[10],
        BIC5[10], EMold[3];
    int i, j, t[cols], tint, k, EMReason[10], EMBreak[10]; /* <0.001 break */
    int UP = 9, num_d;
    const int DOWN = 1;
    UP++;
    int EM = 9999; /* parameter with default value being 20 or 150 */
    EM--;
    for (i = 0; i < cols; i++)
      t[i] = i; /* sort by natural numbers */
    for (i = 0; i < cols; i++) {
      for (j = i; j < cols; j++) {
        if (arr[id][t[i]] > arr[id][t[j]]) {
          tint = t[i];
          t[i] = t[j];
          t[j] = tint;
        }
      }
    }
    double cut = 0;
    int i_cut = 0;
    for (i = 0; i < cols; i++) {
      if (arr[id][t[i]] > 0) {
        cut = log(arr[id][t[i]]);
        break;
      }
      i_cut++;
    }
    for (i = 0; i < cols; i++) {
      if (arr[id][t[i]] > 0)
        arr[id][t[i]] = log(arr[id][t[i]]);
      else
        arr[id][t[i]] = cut - 2;
    }
    for (j = 0; j < 10; j++) {
      EMBreak[j] = -1;
      EMReason[j] = 1;
      for (i = 0; i < 10; i++) {
        results[j][0][i] = -1;
        results[j][1][i] = -1;
        results[j][2][i] = -1;
      }
    }
    for (num_d = DOWN; num_d < UP; num_d++) {
      cc[num_d] = 0;
      m = 0;
      for (i = i_cut; i < cols; i++)
        m += arr[id][t[i]]; /* the summation of one row */
      m /= (cols - i_cut);  /* the mean of one row */
      temp2 = 0;
      for (i = i_cut; i < cols; i++) {
        /* the squared of the difference between the sample and the expectation
         */
        temp1 = arr[id][t[i]];
        temp1 -= m;
        temp1 *= temp1;
        temp2 += temp1;
      }
      temp2 /= (cols - i_cut - 1); /* unbiased estimated variance */
      d = sqrt(temp2); /* unbiased estimated standard deviation of one row */
      for (j = num_d; j < 10; j++)
        for (i = 0; i < 10; i++) {
          results[j][0][i] = 1; /* default weights */
          results[j][0][i] /= num_d;
          tint = (cols - i_cut) * (i + 1) / (num_d + 1) - 1;
          tint += i_cut;
          if (tint >= cols)
            tint = cols - 1;
          results[j][1][i] = arr[id][t[tint]];
          /* Divide-and-Conquer */
          results[j][2][i] = d; /* default standard deviation */
        }
      if (num_d > 2) {
        results[num_d][1][0] = arr[id][t[0]];
        for (i = num_d - 1; i < 10; i++)
          results[num_d][1][i] = arr[id][t[cols - 1]];
      }
      for (int INDEX = 0; INDEX < EM; INDEX++) {
        EMold[0] = -1;
        EMold[1] = -1;
        EMold[2] = -1;
        for (i = 0; i < 10; i++)
          results[0][1][i] = results[num_d][1][i];
        EMold[0] += 1;
        EMold[1] += 1;
        EMold[2] += 1;
        for (i = 0; i < 10; i++) {
          if (results[num_d][0][i] < 0)
            EMold[0] -= results[num_d][0][i];
          else if (results[num_d][0][i] > 0)
            EMold[0] += results[num_d][0][i];
          if (results[num_d][1][i] < 0)
            EMold[1] -= results[num_d][1][i];
          else if (results[num_d][1][i] > 0)
            EMold[1] += results[num_d][1][i];
          if (results[num_d][2][i] < 0)
            EMold[2] -= results[num_d][2][i];
          else if (results[num_d][2][i] > 0)
            EMold[2] += results[num_d][2][i];
        }
        EMBreak[num_d] = INDEX;
        /* ROUNDs 20 or ROUNDs 150 */
        for (i = i_cut; i < cols; i++)
          for (j = 0; j < num_d; j++) {
            temp = densityFuction(arr[id][t[i]], results[num_d][1][j],
                                  results[num_d][2][j]);
            temp *= results[num_d][0][j];
            temp2 = 0;
            for (tint = 0; tint < num_d; tint++) {
              temp1 = densityFuction(arr[id][t[i]], results[num_d][1][tint],
                                     results[num_d][2][tint]);
              temp1 *= results[num_d][0][tint];
              temp2 += temp1;
            }
            temp /= temp2;
            table_theta_t1[i][j] = temp;
          }
        temp = 0;
        for (i = 0; i < num_d; i++) {
          cc[i] = NormSDist(cut, results[num_d][1][i], results[num_d][2][i]);
          cc[i] *= results[num_d][0][i];
          temp += cc[i];
        }
        for (i = 0; i < num_d; i++) {
          cc[i] /= temp;
          cc[i] *= i_cut;
        }
        temp3 = 0;
        for (i = 0; i < num_d; i++) {
          temp = 0;
          for (j = i_cut; j < cols; j++)
            temp += table_theta_t1[j][i];
          temp += cc[i];
          temp2 = temp;
          temp /= cols;
          te[i] = temp;
          temp3 += temp;
          temp = 0;
          for (j = i_cut; j < cols; j++)
            temp += (arr[id][t[j]] * table_theta_t1[j][i]);
          double temp4 = cut - results[num_d][1][i];
          temp4 /= results[num_d][2][i];
          temp1 = densityFuction(temp4, 0, 1);
          temp1 /= NormSDist(temp4, 0, 1);
          temp1 *= results[num_d][2][i];
          temp1 = results[num_d][1][i] - temp1;
          temp1 *= cc[i];
          temp += temp1;
          temp /= temp2;
          results[num_d][1][i] = temp; /* calculate */
          temp4 = cut - results[0][1][i];
          temp4 /= results[num_d][2][i];
          temp1 = densityFuction(temp4, 0, 1);
          temp1 /= NormSDist(temp4, 0, 1);
          temp1 *= (cut - results[0][1][i]);
          temp1 /= results[num_d][2][i];
          temp1 = 1 - temp1;
          temp1 *= results[num_d][2][i];
          temp1 *= results[num_d][2][i];
          temp1 *= cc[i];
          temp = 0;
          for (j = i_cut; j < cols; j++) {
            temp4 = arr[id][t[j]];
            temp4 -= results[0][1][i];
            temp4 *= temp4;
            temp4 *= table_theta_t1[j][i];
            temp += temp4;
          }
          temp += temp1;
          temp /= temp2;
          temp = sqrt(temp);
          results[num_d][2][i] = temp; /* calculate */
        }
        for (i = 0; i < num_d; i++)
          results[num_d][0][i] = te[i] / temp3; /* calculate */
        EMold[0] *= -1;
        EMold[1] *= -1;
        EMold[2] *= -1;
        for (i = 0; i < 10; i++) {
          if (results[num_d][0][i] < 0)
            EMold[0] -= results[num_d][0][i];
          else if (results[num_d][0][i] > 0)
            EMold[0] += results[num_d][0][i];
          if (results[num_d][1][i] < 0)
            EMold[1] -= results[num_d][1][i];
          else if (results[num_d][1][i] > 0)
            EMold[1] += results[num_d][1][i];
          if (results[num_d][2][i] < 0)
            EMold[2] -= results[num_d][2][i];
          else if (results[num_d][2][i] > 0)
            EMold[2] += results[num_d][2][i];
        }
        temp = 0;
        for (i = 0; i < 3; i++)
          temp += EMold[i];
        if (temp < 0)
          temp *= -1;
        EMBreak[num_d] = INDEX + 1;
        if ((INDEX > 250) && (temp < 0.000001)) {
          EMReason[num_d] = 3;
          break;
        }
      }
      /*#################################################################*/
      temp3 = 0;
      k = num_d * 3;
      for (i = i_cut; i < cols; i++) {
        temp2 = 0;
        for (j = 0; j < num_d; j++) {
          if (results[num_d][2][j] > 0.000001)
            temp1 = densityFuction(arr[id][t[i]], results[num_d][1][j],
                                   results[num_d][2][j]) *
                    results[num_d][0][j];
          else
            temp1 = 0.000001;
          temp2 += temp1;
        }
        temp3 += log(temp2);
      }
      const double kk = k * log(cols);
      temp3 *= 2;
      temp3 -= kk;
      BIC5[num_d] = temp3;
    }

    /*#################################################################*/
    temp = BIC5[1];
    int tint3 = 1;
    for (num_d = DOWN + 1; num_d < UP; num_d++)
      if (temp < BIC5[num_d]) {
        temp = BIC5[num_d];
        tint3 = num_d;
      }
    num_d = tint3;
    /*################################################## New sort part for
     * predicted mean */
    double zc_m;
    if (num_d > 1) {
      for (i = (num_d - 1); i > 0; i--) {
        for (j = 0; j <= i; j++) {
          if (results[num_d][1][j] > results[num_d][1][j + 1]) {
            zc_m = results[num_d][1][j + 1];
            results[num_d][1][j + 1] = results[num_d][1][j];
            results[num_d][1][j] = zc_m;
            zc_m = results[num_d][2][j + 1];
            results[num_d][2][j + 1] = results[num_d][2][j];
            results[num_d][2][j] = zc_m;
            zc_m = results[num_d][0][j + 1];
            results[num_d][0][j + 1] = results[num_d][0][j];
            results[num_d][0][j] = zc_m;
          }
        }
      }
    }

    fprintf(F4, "\n#%s\tK=%d\tIteration=%d_%d\tZCUT\tBIC=%lf\n", genes_n[id],
            num_d, EMBreak[num_d], EMReason[num_d], BIC5[num_d]);
    for (i = 1; i < 10; i++) {
      fprintf(F4, "The number of Null dist : %d\t\n", i);
      fprintf(F4, "A or proportion : \t");
      for (j = 0; j < i; j++) {
        fprintf(F4, "%lf\t", results[i][0][j]);
      }
      fprintf(F4, "\nu or mean : \t");
      for (j = 0; j < i; j++) {
        fprintf(F4, "%lf\t", results[i][1][j]);
      }
      fprintf(F4, "\nsig or sigma : \t");
      for (j = 0; j < i; j++) {
        fprintf(F4, "%lf\t", results[i][2][j]);
      }
      fprintf(F4, "\n");
    }

    /*##############################################################*/
    fprintf(F4, "BIC results : \t");
    for (i = DOWN; i < UP; i++)
      fprintf(F4, "%lf\t", BIC5[i]);
    fprintf(F4, "\nWhich BIC We Choose : \t%d\n", num_d);
    fprintf(F4, "A or proportion : \t");
    for (i = 0; i < num_d; i++)
      fprintf(F4, "%lf\t", results[num_d][0][i]);
    fprintf(F4, "\nu or mean : \t");
    for (i = 0; i < num_d; i++)
      fprintf(F4, "%lf\t", results[num_d][1][i]);
    fprintf(F4, "\nsig or sigma : \t");
    for (i = 0; i < num_d; i++)
      fprintf(F4, "%lf\t", results[num_d][2][i]);
    fprintf(F4, "\n");

    printf("%d\t%d\n", num_d, cols);
    /*############################################################################
     */
    /*F1 em.chars*/
    for (i = 0; i < num_d; i++) {
      for (j = 0; j < cols; j++) {
        c[i][j] = arr[id][j] - results[num_d][1][i];
        c[i][j] *= c[i][j];
        c[i][j] *= -1;
        temp3 = 2 * results[num_d][2][i] * results[num_d][2][i];
        c[i][j] =
            c[i][j] / temp3 + log(results[num_d][0][i] / results[num_d][2][i]);
      }
    }
    for (i = 0; i < cols; i++) {
      temp1 = c[0][i];
      tint = 1;
      arr_c[id][i] = charset_add(symbols, 0);
      for (j = 0; j < num_d; j++) {
        if (temp1 < c[j][i]) {
          temp1 = c[j][i];
          tint = j + 1;
        }
      }
      arr_c[id][i] = charset_add(symbols, tint);
      if (arr[id][i] < results[num_d][1][0]) {
        arr_c[id][i] = charset_add(symbols, 1);
      }
      if (arr[id][i] > results[num_d][1][num_d - 1]) {
        arr_c[id][i] = charset_add(symbols, num_d);
      }
    }
    fprintf(F1, "%s", genes_n[id]);
    for (i = 0; i < cols; i++) {
      arr_c_F2[id][i] = arr_c[id][i];
      fprintf(F1, "\t%d", arr_c[id][i]);
    }
    fprintf(F1, "\n");
    /*############################################################################*/
    /*store the qubic1.0 discretization output for further use*/
    
    /*############################################################################*/
    /* F2 split.chars  */
    int arr_c_id[10]; /* store the unique nonzero intergers */
    int arr_c_count[10];

    for (i = 0; i < 10; i++) {
      arr_c_id[i] = 0;
      arr_c_count[i] = 0;
    }
    int zc_k = 0;
    for (i = 0; i < cols; i++) {
      zc_m = 0;
      for (j = 0; j < 10; j++) {
        if (arr_c_F2[id][i] == arr_c_id[j]) {
          zc_m++;
        }
      }
      if (zc_m == 0) {
        arr_c_id[zc_k] =
            arr_c_F2[id][i]; /*arr_c_id [] store the unique nonzero integers */
        zc_k++;
      }
      if (arr_c_F2[id][i] != 0) {
        for (j = 0; j < 10; j++) {
          if (arr_c_F2[id][i] == arr_c_id[j]) {
            arr_c_count[j]++; /*arr_c_count store the # of elements for each
                                 nonzero integer*/
          }
        }
      }
    }

    float zc_max = 0;
    int zc_k_F3 = 0; /*zc_k_F3 is the most abundant nonzero integers */
    for (k = 0; k < 10;
         k++) { /* find the # of elements for the most abundant integer*/
      if (arr_c_count[k] > zc_max) {
        zc_max = arr_c_count[k];
        zc_k_F3 = arr_c_id[k];
      }
    }
    if (zc_max >= cols / 2) { /* if one peak is too abundant, use qubic1.0
                                 discretization results to generate
                                 split.chars*/
      for (i = 0; i < 10; i++) {
        arr_c_id[i] = 0;
        arr_c_count[i] = 0;
      }
      zc_k = 0;
      for (i = 0; i < cols; i++) {
        arr_c_F2[id][i] = arr_c_d[id][i];
        if (arr_c_F2[id][i] != 0) {
          zc_m = 0;
          for (j = 0; j < 10; j++) {
            if (arr_c_F2[id][i] == arr_c_id[j]) {
              zc_m++;
            }
          }
          if (zc_m == 0) {
            arr_c_id[zc_k] = arr_c_F2[id][i];
            zc_k++;
          }
        }
      }
    }

    for (i = 0; i < 10; i++) {
      if (arr_c_id[i] != 0) {
        fprintf(F2, "%s_%d", genes_n[id], arr_c_id[i]);
        for (j = 0; j < cols; j++) {
          if (arr_c_F2[id][j] == arr_c_id[i])
            fprintf(F2, "\t1");
          else
            fprintf(F2, "\t0");
        }
        fprintf(F2, "\n");
      }
    }
    printf("\n");

    /*############################################################################*/
    /*   .chars    */
    for (i = 0; i < cols; i++)
      m += arr[id][i]; /* the sum of one row */
    m /= cols;         /* the mean of one row */
    temp2 = 0;
    for (i = 0; i < cols; i++) {
      /* the square of the difference between the sample and the expectation */
      temp1 = arr[id][i];
      temp1 -= m;
      temp1 *= temp1;
      temp2 += temp1;
    }
    temp2 /= (cols - 1); /* unbiased estimated variance */
    d = sqrt(temp2);

    temp = 0;
    for (i = 0; i < cols; i++) {
      temp1 = arr[id][i] - m;
      temp1 /= d;
      temp1 = temp1 * temp1 * temp1;
      temp += temp1;
    }

    if (num_d == 1) {
      for (i = 0; i < cols; i++)
        arr_c_F3[id][i] = arr_c_d[id][i]; /*arr_c_F3[][] store F3 output */
    } else {
      for (j = 0; j < cols; j++) {
        if (arr_c[id][j] < zc_k_F3)
          arr_c_F3[id][j] = -1;
        if (arr_c[id][j] == zc_k_F3)
          arr_c_F3[id][j] = 0;
        if (arr_c[id][j] > zc_k)
          arr_c_F3[id][j] = 1;
      }
    }
    fprintf(F3, "%s", genes_n[id]);
    for (j = 0; j < cols; j++)
      fprintf(F3, "\t%d", arr_c_F3[id][j]);
    fprintf(F3, "\n");
  }
  progress("Discretization rules are written to %s", stream_nm);
  fclose(F1);
  fclose(F2);
  fclose(F3);
  fclose(F4);

  for (auto row = 0; row < rows; row++) {
    delete[] arr_c_d[row];
    delete[] arr_c_F2[row];
    delete[] arr_c_F3[row];
  }
  delete[] arr_c_d;
  delete[] arr_c_F2;
  delete[] arr_c_F3;
}
