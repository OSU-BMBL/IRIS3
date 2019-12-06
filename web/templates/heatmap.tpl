{{extends file="base.tpl"}}
{{block name="extra_js"}}

{{/block}}
{{block name="extra_style"}}

{{/block}}
{{block name="main"}}



<script>
$(document).ready(function () {
/*
      $('#motiftable').DataTable({
    	"order": [[ 2, "asc" ]]
      });
      $('.dataTables_length').addClass('bs-select');*/
	  var flag = [];
	  make_clust_main('data/{{$jobid}}/json/{{$filename}}','#container-id-1');
	  
});
</script>



  <div id='container-id-1'>
      <h1 class='wait_message'>Please wait ...</h1>
  </div>

   									
    <!-- Required JS Libraries -->
    <script src="assets/js/d3.js"></script>
    <script src="assets/js/underscore-min.js"></script>
    <!-- Clustergrammer JS -->
    <script src='assets/js/clustergrammer.js'></script>
    <!-- optional modules -->
    <script src='assets/js/Enrichrgram.js'></script>
    <script src='assets/js/hzome_functions.js'></script>
    <script src='assets/js/send_to_Enrichr.js'></script>

    <!-- make clustergram -->
    <script src='assets/js/load_clustergram.js'></script>

{{/block}}