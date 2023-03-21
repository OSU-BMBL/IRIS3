{{block name="extra_js"}}

{{/block}}
{{block name="extra_style"}}

{{/block}}
{{block name="main"}}
<meta charset="UTF-8" />
<meta http-equiv="X-UA-Compatible" content="IE=edge" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<meta
  name="description"
  content="integrated cell type specific Regulon inference from single-cell rna seq"
/>
<meta
  name="keywords"
  content="scrnaseq, regulon, single cell rna seq,Cell-type-specific Regulon Single-cell RNA-Seq"
/>
<title>
  IRIS3: Integrated Cell-type-specific Regulon Inference Server from Single-cell
  RNA-Seq
</title>
<script src="assets/js/jquery-1.12.4.min.js"></script>
<script src="assets/js/bootstrap.min.js"></script>
<script src="assets/js/wow.min.js"></script>
<script src="assets/js/jquery.ajaxchimp.js"></script>
<script src="assets/js/jquery.sticky.js"></script>
<script
  type="text/javascript"
  charset="utf8"
  src="https://cdn.datatables.net/1.10.19/js/jquery.dataTables.min.js"
></script>
<script
  type="text/javascript"
  charset="utf8"
  src="https://cdn.datatables.net/buttons/1.5.6/js/dataTables.buttons.min.js"
></script>
<script
  type="text/javascript"
  charset="utf8"
  src="https://cdn.datatables.net/buttons/1.5.6/js/buttons.html5.min.js"
></script>
<script
  type="text/javascript"
  src="https://cdn.jsdelivr.net/npm/lozad/dist/lozad.min.js"
></script>
<link rel="shortcut icon" type="image/ico" href="assets/img/favicon.png" />
<link
  rel="stylesheet"
  type="text/css"
  href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap-select/1.13.2/css/bootstrap-select.min.css"
/>
<!--====== STYLESHEETS ======-->
<link
  rel="stylesheet"
  type="text/css"
  href="https://cdn.datatables.net/1.10.19/css/jquery.dataTables.css"
/>
<link
  rel="stylesheet"
  type="text/css"
  href="https://cdn.datatables.net/buttons/1.5.6/css/buttons.dataTables.min.css"
/>
<link href="assets/css/heroic-features.css" rel="stylesheet" />
<link href="assets/css/plugins.css" rel="stylesheet" />
<link href="assets/css/theme.css" rel="stylesheet" />
<link href="assets/css/icons.css" rel="stylesheet" />
<!--====== MAIN STYLESHEETS ======-->
<link href="assets/css/style.css" rel="stylesheet" />
<link href="assets/css/responsive.css" rel="stylesheet" />
<script src="assets/js/modernizr-2.8.3.min.js"></script>
<script src="assets/js/pace.js"></script>
<script>
  $(document).ready(function () {
    /*
      $('#motiftable').DataTable({
    	"order": [[ 2, "asc" ]]
      });
      $('.dataTables_length').addClass('bs-select');*/
    var flag = []
    make_clust_main('heatmap/{{$filename}}', '#container-id-1')
  })
</script>

<div id="container-id-1">
  <h1 class="wait_message">Please wait ...</h1>
</div>

<!-- Required JS Libraries -->
<script src="assets/js/d3.js"></script>
<script src="assets/js/underscore-min.js"></script>
<!-- Clustergrammer JS -->
<script src="assets/js/clustergrammer.js"></script>
<!-- optional modules -->
<script src="assets/js/Enrichrgram.js"></script>
<script src="assets/js/hzome_functions.js"></script>
<script src="assets/js/send_to_Enrichr.js"></script>

<!-- make clustergram -->
<script src="assets/js/load_clustergram.js"></script>

{{/block}}
