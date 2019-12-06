/* Author:Qin Ma <maqin@uga.edu>, Step. 19, 2013
 * Usage: This is part of bicluster package. Use, redistribution, modify without
 * limitations Process the options for the commandline tool
 */

/***************************************************************************/

#include "get_options.h"

/***************************************************************************/
static const char USAGE[] =
    "===================================================================\n\
[Usage]\n\
$ ./qubic -i filename [argument list]\n\
===================================================================\n\
[Input]\n\
-i : input file must be one of two tab-delimited formats\n\
  A) continuous data (default, use pre-set discretization (see -q and -r))\n\
     -------------------------------------\n\
     o        cond1    cond2    cond3\n\
     gene1      2.4      3.5     -2.4\n\
     gene2     -2.1      0.0      1.2\n\
     -------------------------------------\n\
  B) discrete data with arbitray classes (turn on -d)\n\
     use '0' for missing or insignificant data\n\
     -------------------------------------\n\
     o        cond1    cond2    cond3\n\
     gene1        1        2        2\n\
     gene2       -1        2        0\n\
     -------------------------------------\n\
-d : the flag to analyze discrete data, where user should discretize their\n\
     data to different classes of value, see B) above\n\
     default: FALSE\n\
-b : a .blocks file to be expanded in a specific .chars file\n\
-s : the flag of doing expansion, used together with -b\n\
     default: FALSE\n\
===================================================================\n\
[Discretization]\n\
-F : the flag to only do discretization without biclustering\n\
-q : use quantile discretization for continuous data\n\
     default: 0.06 (see details in Method section in paper)\n\
-r : the number of ranks as which we treat the up(down)-regulated value\n\
     when discretization\n\
     default: 1\n\
-n : the flag to discretize the continuous values by a mixture normal distribution model\n\
     default: FALSE\n\
-R : the flag to discretize the RPKM values by a mixture normal distribution model\n\
     default: FALSE\n\
-e : the number of iterations in EM algorithm when using -n or -R\n\
     default: FALSE\n\
===================================================================\n\
[Biclustering]\n\
-f : filtering overlapping blocks,\n\
     default: 1 (do not remove any blocks)\n\
-k : minimum column width of the block,\n\
     default: 5% of columns, minimum 2 columns\n\
-c : consistency level of the block (0.5-1.0], the minimum ratio between the\n\
     number of identical valid symbols in a column and the total number \n\
     of rows in the output\n\
     default: 1.0\n\
-p : the flag to calculate the spearman correlation between any pair of genes\n\
     this can capture more reliable relationship but much slower\n\
     default: FALSE\n\
-C : the flag using the lower bound of condition number\n\
     default: 5% of the gene number in current bicluster\n\
-N : the flag using 1.0 biclustering,i.e., maximize min(|I|,|J|) \n\
===================================================================\n\
[Output]\n\
-o : number of blocks to report\n\
     default: 100\n\
===================================================================\n";

static void init_options() {
  /* default parameters */
  /* strcpy: Copies the C string pointed by source into the array pointed by
   * destination, including the terminating null character. To avoid overflows,
   * the size of the array pointed by destination shall be long enough to
   * contain the same C string as source (including the terminating null
   * character), and should not overlap in memory with source
   */
  strcpy(po->FN, " ");
  strcpy(po->BN, " ");
  po->IS_DISCRETE = FALSE;
  po->COL_WIDTH = 3;
  po->DIVIDED = 1;
  /*.06 is set as default for its best performance for ecoli and yeast
   * functional analysis*/
  po->QUANTILE = .06;
  po->TOLERANCE = 1;
  po->FP = NULL;
  po->FB = NULL;
  po->RPT_BLOCK = 100;
  po->SCH_BLOCK = 500;
  po->FILTER = 1;
  po->IS_SWITCH = FALSE;
  po->IS_cond = FALSE;
  po->IS_spearman = FALSE;
  po->IS_new_discrete = FALSE;
  po->IS_Fast = FALSE;
  po->IS_MaxMin = FALSE;
  po->IS_rpkm = FALSE;
  po->EM = 100;
}

/*argc is a count of the arguments supplied to the program and argc[] is an
 * array of pointers to the strings which are those arguments-its type is array
 * of pointer to char
 */
void get_options(int argc, char *argv[]) {
  int op;
  bool is_valid = TRUE;

  /*set memory for the point which is decleared in struct.h*/
  po = new Prog_options;
  /*Initialize the point*/
  init_options();

  /*The getopt function gets the next option argument from the argument list
   *specified by the argv and argc arguments. Normally these values come
   *directly from the arguments received by main
   */
  /*An option character in this string can be followed by a colon (:) to
   *indicate that it takes a required argument. If an option character is
   *followed by two colons (::), its argument is optional if an option character
   *is followed by no colons, it does not need argument
   */
  while ((op = getopt(argc, argv, "i:b:q:r:dsf:k:o:c:Cm:e:pnRFNh")) > 0) {
    switch (op) {
    /*optarg is set by getopt to point at the value of the option argument, for
     * those options that accept arguments*/
    case 'i':
      strcpy(po->FN, optarg);
      break;
    case 'b':
      strcpy(po->BN, optarg);
      break;
    /*atof can convert string to double*/
    case 'q':
      po->QUANTILE = atof(optarg);
      break;
    /*atoi can convert string to integer*/
    case 'r':
      po->DIVIDED = atoi(optarg);
      break;
    case 'd':
      po->IS_DISCRETE = TRUE;
      break;
    case 's':
      po->IS_SWITCH = TRUE;
      break;
    case 'f':
      po->FILTER = atof(optarg);
      break;
    case 'k':
      po->COL_WIDTH = atoi(optarg);
      break;
    case 'c':
      po->TOLERANCE = atof(optarg);
      break;
    case 'o':
      po->RPT_BLOCK = atoi(optarg);
      po->SCH_BLOCK = 5 * po->RPT_BLOCK;
      break;
    case 'C':
      po->IS_cond = TRUE;
      break;
    case 'e':
      po->EM = atoi(optarg);
      break;
    case 'p':
      po->IS_spearman = TRUE;
      break;
    case 'n':
      po->IS_new_discrete = TRUE;
      break;
    case 'R':
      po->IS_rpkm = TRUE;
      break;
    case 'F':
      po->IS_Fast = TRUE;
      break;
    case 'N':
      po->IS_MaxMin = TRUE;
      break;
    case 'h':
      puts(USAGE);
      exit(0);
    /*if expression does not match any constant-expression, control is
     * transferred to the statement(s) that follow the optional default label*/
    default:
      is_valid = FALSE;
    }
  }
  /* basic sanity check */
  if (is_valid && po->FN[0] == ' ') {
    puts(USAGE);
    exit(0);
  }
  if (is_valid) {
    po->FP = mustOpen(po->FN, "r");
  }
  if (po->IS_SWITCH) {
    po->IS_DISCRETE = TRUE;
    po->FB = mustOpen(po->BN, "r");
  }

  /* option value range check */
  if ((po->QUANTILE > .5) || (po->QUANTILE <= 0)) {
    err("-q quantile discretization should be (0,.5]");
    is_valid = FALSE;
  }
  if ((po->FILTER > 1) || (po->FILTER < 0)) {
    err("-f overlapping filtering should be [0,1.]");
    is_valid = FALSE;
  }
  if ((po->TOLERANCE > 1) || (po->TOLERANCE <= .5)) {
    err("-c noise ratio should be (.5,1]");
    is_valid = FALSE;
  }
  if (po->COL_WIDTH < 2 && po->COL_WIDTH != -1) {
    err("-k minimum column width should be >=2");
    is_valid = FALSE;
  }
  if (po->RPT_BLOCK <= 0) {
    err("-n number of blocks to report should be >0");
    is_valid = FALSE;
  }
  if (!is_valid)
    errAbort("Type -h to view possible options");
}
/***************************************************************************/
