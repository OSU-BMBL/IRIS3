/*
Example files
*/

var hzome = ini_hzome();

//make_clust_main('data/2018122223201/json/CT1.json','#container-id-1');
//make_clust('data/2018122223201/json/2018122223201_CT_1_regulon1.json','#container-id-1-1');
var about_string = 'Zoom, scroll, and click buttons to interact with the clustergram. <a href="http://amp.pharm.mssm.edu/clustergrammer/help"> <i class="fa fa-question-circle" aria-hidden="true"></i> </a>';

function make_clust(inst_network,root_id){

    d3.json(inst_network, function(network_data){

      // define arguments object
      var args = {
        root: root_id,
        'network_data': network_data,
        'about':about_string,
        'row_tip_callback':hzome.gene_info,
        'col_tip_callback':test_col_callback,
        'tile_tip_callback':test_tile_callback,
        'matrix_update_callback':matrix_update_callback,
        'cat_update_callback': cat_update_callback,
		'dendro_callback':dendro_callback,
        'sidebar_width':160,
        // 'ini_view':{'N_row_var':20}
        'ini_expand':true,
		'make_modals':false,
      };

      resize_container_small(args);

      d3.select(window).on('resize',function(){
        resize_container_small(args);
        cgm.resize_viz();
      });

      cgm = Clustergrammer(args);

      check_setup_enrichr(cgm);

      d3.select(cgm.params.root + ' .wait_message').remove();
  });

}

function make_clust_main(inst_network,root_id){
	file_size = get_filesize(inst_network, function(size) {
		if (size > 5000000 && window.location.pathname == "/iris3/results.php") {
			console.log(inst_network +" file size: "+size+" bytes. The heatmap has been automatically disabled as page may crash.")
			document.getElementById(root_id.substr(1)).innerHTML = "<p>The heatmap has been automatically disabled as page may crash. Click 'Open in new tab' if you would like to check the heatmap for details.</p>"
		} else {
			d3.json(inst_network, function(network_data){

      // define arguments object
      var args = {
        root: root_id,
        'network_data': network_data,
        'about':about_string,
        'row_tip_callback':hzome.gene_info,
        'col_tip_callback':test_col_callback,
        'tile_tip_callback':test_tile_callback,
        'matrix_update_callback':matrix_update_callback,
        'cat_update_callback': cat_update_callback,
		'dendro_callback':dendro_callback,
        'sidebar_width':160,
        // 'ini_view':{'N_row_var':20}
        'ini_expand':true,
		'make_modals':false,
      };

      resize_container(args);

      d3.select(window).on('resize',function(){
        resize_container(args);
        cgm.resize_viz();
      });

      cgm = Clustergrammer(args);

      check_setup_enrichr(cgm);

      d3.select(cgm.params.root + ' .wait_message').remove();
  });
		}
	});
}


function matrix_update_callback(){

  if (genes_were_found[this.root]){
    enr_obj[this.root].clear_enrichr_results(false);
  }
}

function cat_update_callback(){
  console.log('callback to run after cats are updated');
}

function test_tile_callback(tile_data){
  var row_name = tile_data.row_name;
  var col_name = tile_data.col_name;

}

function test_col_callback(col_data){
  var col_name = col_data.name;
}

function dendro_callback(inst_selection){

  var inst_rc;
  var inst_data = inst_selection.__data__;

  // toggle enrichr export section
  if (inst_data.inst_rc === 'row'){
    d3.select('.enrichr_export_section')
      .style('display', 'block');
  } else {
    d3.select('.enrichr_export_section')
      .style('display', 'none');
  }

}

function resize_container(args){

  var screen_width = window.innerWidth;
  var screen_height = window.innerHeight - 20;

  d3.select(args.root)
    .style('width', screen_width+'px')
    .style('height', screen_height+'px');
}



function resize_container_small(args){

  var screen_width = window.innerHeight-20;
  var screen_height = window.innerHeight-200;

  d3.select(args.root)
    .style('width', screen_width+'px')
    .style('height', screen_height+'px');
}

function get_filesize(url, callback) {
    var xhr = new XMLHttpRequest();
    xhr.open("HEAD", url, true); // Notice "HEAD" instead of "GET",
                                 //  to get only the header
    xhr.onreadystatechange = function() {
        if (this.readyState == this.DONE) {
            callback(parseInt(xhr.getResponseHeader("Content-Length")));
        }
    };
    xhr.send();
}
