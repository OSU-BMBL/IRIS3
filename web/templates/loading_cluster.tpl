{{block name="extra_js"}} {{/block}} {{block name="extra_style"}} {{/block}} {{block name="main"}}
<a href="https://osu.az1.qualtrics.com/jfe/form/SV_6KihVYPtHj7FxGJ" class="take_survey" target="_blank">Take a Survey<i class="fa fa-poll-h"></i></a>
<script src="assets/js/pace.js"></script>
<script src="assets/js/code/highcharts.js"></script>
<script src="assets/js/code/modules/boost.js"></script>
<script src="assets/js/code/modules/exporting.js"></script>
<script src="assets/js/code/modules/export-data.js"></script>
<script src="assets/js/code/modules/accessibility.js"></script>
<script src="assets/js/bootstrap-select.min.js"></script>

<style>

.header-top-area {
	display:none;
}
.footer-bottom-area {
	display:none;
}
</style>
<script>
var flag = [];
if ($('#heatmapTab').length > 0) {
	window.addEventListener('scroll', function(e) {
		if(document.getElementById("heatmapTab").getBoundingClientRect().y == 10){
			document.getElementById("heatmapTab").setAttribute("style","background-color:#fff;border: 5px solid #B47157;border-radius: 5px")
		}	else {
			document.getElementById("heatmapTab").setAttribute("style","background-color:transparent;")
		}
		});
}

if ($('#regulonTab').length > 0) {
	window.addEventListener('scroll', function(e) {
		if(document.getElementById("regulonTab").getBoundingClientRect().y == 10){
			document.getElementById("regulonTab").setAttribute("style","background-color:#fff;border: 5px solid #B47157;border-radius: 5px")
		}	else {
			document.getElementById("regulonTab").setAttribute("style","background-color:transparent;")
		}
		});
}


function terminate_job(item) {
		jobid = location.search.match(/\d+/gm)
		if (jobid[0].startsWith("20")) {
			console.log("terminate job: " + jobid)
			$.ajax({
			url: "terminate_job.php?jobid=" + jobid[0] ,
			type: 'POST',
			data: {'id': jobid[0]},
			dataType: 'json',
			success: function(response) {
			},
		})
		}
	}
	


	function show_peak_table(item){
		id_name = "#"+$(item).attr("id")
			$('html, body').animate({
					scrollTop: $(id_name).offset().top
				}, 500);
		match_id = $(item).attr("id").match(/\d+/gm)
		regulon_id = $(item).attr("id").substring(8)
		table_id = "table-"+regulon_id
		species = document.getElementById("species").innerHTML
		match_species =  species.match(/[^Species: ].+/gm)[0]
		jobid = location.search.match(/\d+/gm)[0]
		table_content_id = "table-content-"+regulon_id
		table_jquery_id="#"+table_content_id
		console.log("prepare_peak.php?jobid="+jobid+"&regulon_id="+regulon_id+"&species="+match_species+"&table="+table_content_id)
		if ( ! $.fn.DataTable.isDataTable(table_jquery_id) ) {
		$(table_jquery_id).DataTable( {
				dom: 'lBfrtip',
				buttons: [
				{
				text:'Download',
				title: jobid+'_'+regulon_id+'_peak',
				action: function ( e, dt, button, config ) {
        		window.open('data/'+jobid+'/atac/'+regulon_id+'.atac_overlap_result.txt')
     		 } 
				}
				],
				"ajax": "prepare_peak.php?jobid="+jobid+"&regulon_id="+regulon_id+"&species="+match_species+"&table="+table_content_id,
				"searching": false,
				"bInfo" : false,
				"order": [[ 3, "desc" ]],
				columnDefs: [
				{
					targets: 0,
					render: function (data, type, row, meta)
					{
						if (type === 'display')
						{
							data = '<a  href="http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=' +row[6]+ '" target="_blank">'+data +'</a>';
						}
						return data
					}
				},{
                "targets": [6],
                "visible": false
				},
				{
                "targets": [3],
                "visible": false
				},{
                "targets": [7],
                render: function (data, type, row, meta){	
						var dat = new Array
						if (type === 'display'){
							res = data.split(" ")
							for(i=0;i < res.length;i++) {
								if (match_species == "Human") {
								dat[i] = '<a  href="https://www.genecards.org/cgi-bin/carddisp.pl?gene=' +res[i]+ '" target="_blank">'+res[i] +'</a>'
								} else if (match_species == "Mouse"){
								dat[i] = '<a  href="http://www.informatics.jax.org/searchtool/Search.do?query=' +res[i]+ '" target="_blank">'+res[i] +'</a>'
								}
							}
						}
						return dat
					}
				}
				],
		
		});
		}
		document.getElementById(table_id).innerHTML=""
	}
	
	
	function show_tad_table(item){
		match_id = $(item).attr("id").match(/\d+/gm)
		regulon_id = $(item).attr("id").substring(7)
		table_id = "tad-table-"+regulon_id
		species = document.getElementById("species").innerHTML
		match_species =  species.match(/[^Species: ].+/gm)[0]
		jobid = location.search.match(/\d+/gm)[0]
		table_content_id = "tad-table-content-"+regulon_id
		table_jquery_id="#"+table_content_id
		id_name = "#"+$(item).attr("id")
		$('html, body').animate({
			scrollTop: $(id_name).offset().top
		}, 500)
		if ( ! $.fn.DataTable.isDataTable(table_jquery_id) ){
			if(match_species=='Human'){
			$(table_jquery_id).DataTable( {
				dom: 'lBfrtip',
				buttons: [
				{
				text:'Download',
				title: jobid+'_'+regulon_id+'_TAD_covered_genes',
				action: function ( e, dt, button, config ) {
        		window.open('data/'+jobid+'/tad/'+regulon_id+'.tad.txt')
     		 } 
				}
				],
				"ajax": "prepare_tad.php?jobid="+jobid+"&regulon_id="+regulon_id+"&species="+match_species+"&table="+table_content_id,
				"searching": false,
				"bInfo" : false,
				"aLengthMenu": [[5, 10, -1], [5, 10, "All"]],
				"iDisplayLength": 5,
				columnDefs: [/*{
                "targets": [2],
                render: function (data, type, row, meta){	
						return data.length
					}
				},*/{
                "targets": [2],
                render: function (data, type, row, meta){	
						var dat=new Array
						if (type === 'display'){
							res=data.split(" ")
							if (res[0] != "Not"){
								for(i=0;i < res.length;i++) {
									dat[i] = '<a  href="https://www.genecards.org/cgi-bin/carddisp.pl?gene=' +res[i]+ '" target="_blank">'+res[i] +'</a>'
								}
							} else {
								dat = "Not found"
							}
						}
						return dat
					}
				}
				],
			})
			} else if (match_species == 'Mouse'){
			$(table_jquery_id).DataTable( {
				dom: 'lBfrtip',
				buttons: [
				{
				text:'Download',
				title: jobid+'_'+regulon_id+'_TAD_covered_genes',
				action: function ( e, dt, button, config ) {
        		window.open('data/'+jobid+'/tad/'+regulon_id+'.tad.txt')
     		 } 
				}
				],
				"ajax": "prepare_tad.php?jobid="+jobid+"&regulon_id="+regulon_id+"&species="+match_species+"&table="+table_content_id,
				"searching": false,
				"bInfo" : false,
				"aLengthMenu": [[ -1], [ "All"]],
				"iDisplayLength": -1,
				columnDefs: [{
                "targets": [2],
                render: function (data, type, row, meta){	
						var dat=new Array
						if (type === 'display'){
							res=data.split(" ")
							if (res[0] != "Not"){
								for(i=0;i < res.length;i++) {
									dat[i] = '<a  href="http://www.informatics.jax.org/searchtool/Search.do?query=' +res[i]+ '" target="_blank">'+res[i] +'</a>'
								}
							}else {
								dat = "Not found"
							}
						}
						return dat
					}
				}
				],
		})
			}
		}
		document.getElementById(table_id).innerHTML=""
	}
	
	function show_dorothea_table(item,this_tf){
		match_id = $(item).attr("id").match(/\d+/gm)
		regulon_id = $(item).attr("id").substring(12)
		table_id = "dorothea-table-"+regulon_id
		species = document.getElementById("species").innerHTML
		match_species =  species.match(/[^Species: ].+/gm)[0]
		jobid = location.search.match(/\d+/gm)[0]
		table_content_id = "dorothea-table-content-"+regulon_id
		table_jquery_id="#"+table_content_id
		id_name = "#"+$(item).attr("id")
		$('html, body').animate({
			scrollTop: $(id_name).offset().top
		}, 500)
		if ( !$.fn.DataTable.isDataTable(table_jquery_id) ){
			if(match_species=='Human'){
			$(table_jquery_id).DataTable( {
				dom: 'lBfrtip',
				buttons: [
				{
				extend:'copy',
				title: jobid+'_'+regulon_id+'_dorothea_overlap_genes'
				},
				{
				extend:'csv',
				title: jobid+'_'+regulon_id+'_dorothea_overlap_genes'
				}
				],
				"ajax": "prepare_dorothea_overlap.php?jobid="+jobid+"&regulon_id="+regulon_id+"&species="+match_species+"&table="+table_content_id+"&this_tf="+this_tf,
				"searching": false,
				"bInfo" : false,
				"aLengthMenu": [[5, 10,20, -1], [5, 10,20, "All"]],
				"iDisplayLength": 10,
				columnDefs: [/*{
                "targets": [2],
                render: function (data, type, row, meta){	
						return data.length
					}
				},*/{
                "targets": [1],
                render: function (data, type, row, meta){	
						var dat=new Array
						if (type === 'display')
						{
							res=data.split(" ")
							for(i=0;i < res.length;i++) {
								if (res[i] != "NA") {
									dat[i] = '<a  href="https://www.genecards.org/cgi-bin/carddisp.pl?gene=' +res[i]+ '" target="_blank">'+res[i] +'</a>'
								} else {
									dat[i] = res[i]
								}
							}
						}
						return dat
					}
				}
				],
			})
			} else if (match_species == 'Mouse'){
			$(table_jquery_id).DataTable( {
				dom: 'lBfrtip',
				buttons: [
				{
				extend:'copy',
				title: jobid+'_'+regulon_id+'_dorothea_overlap_genes'
				},
				{
				extend:'csv',
				title: jobid+'_'+regulon_id+'_dorothea_overlap_genes'
				}
				],
				"ajax": "prepare_dorothea_overlap.php?jobid="+jobid+"&regulon_id="+regulon_id+"&species="+match_species+"&table="+table_content_id,
				"searching": false,
				"bInfo" : false,
				"aLengthMenu": [[ -1], [ "All"]],
				"iDisplayLength": -1,
				columnDefs: [{
                "targets": [1],
                render: function (data, type, row, meta){	
						var dat=new Array
						if (type === 'display')
						{
							res=data.split(" ")
							for(i=0;i < res.length;i++) {
								if (res[i] != "NA") {
									dat[i] = '<a  href="http://www.informatics.jax.org/searchtool/Search.do?query=' +res[i]+ '" target="_blank">'+res[i] +'</a>'
								} else {
									dat[i] = res[i]
								}
							}
						}
						return dat
					}
				}
				],
		})
			}
		}
		document.getElementById(table_id).innerHTML=""
	}
	
	function show_similar_table(item) {
	id_name = "#"+$(item).attr("id")
		$('html, body').animate({
				scrollTop: $(id_name).offset().top
			}, 500);
	match_id = $(item).attr("id").match(/\d+/gm)
	regulon_id = $(item).attr("id").substring(11)
	table_id = "similar-table-" + regulon_id
	species = document.getElementById("species").innerHTML
	match_species = species.match(/[^Species: ].+/gm)[0]
	jobid = location.search.match(/\d+/gm)[0]
	table_content_id = "similar-table-content-" + regulon_id
	table_jquery_id = "#" + table_content_id
	if (!$.fn.DataTable.isDataTable(table_jquery_id)) {
	$(table_jquery_id).DataTable({
		dom: 'lBfrtip',
		buttons: [
				{
				extend:'copy',
				title: jobid+'_'+regulon_id+'_similar_regulon'
				},
				{
				extend:'csv',
				title: jobid+'_'+regulon_id+'_similar_regulon'
				}
				],
		"ajax": "prepare_similar_regulon.php?jobid=" + jobid + "&regulon_id=" + regulon_id + "&species=" + match_species + "&table=" + table_content_id,
		"searching": false,
		"paging": false,
		"bInfo" : false,
		"aLengthMenu": [
			[10, -1],
			[10, "All"]
		],
		"iDisplayLength": 10,
		
	})
	}
	document.getElementById(table_id).innerHTML = ""
	}
	
	function show_regulon_table(item) {
	match_id = $(item).attr("id").match(/\d+/gm)
	regulon_id = $(item).attr("id").substring(11)
	ct_id= regulon_id.substring(
    regulon_id.lastIndexOf("CT") + 2, 
    regulon_id.lastIndexOf("S")
	)
	table_id = "regulon-table-" + regulon_id
	jobid = location.search.match(/\d+/gm)[0]
	table_content_id = "regulon-table-content-" + regulon_id
	table_jquery_id = "#" + table_content_id
	//id_name = "#"+$(item).attr("id")
	$.ajax({
		url: "prepare_regulon_tsne.php?jobid=" + jobid + "&id=" + regulon_id,
		type: 'POST',
		beforeSend: function(){
		$('#'+table_content_id).html('<div id="scroll_'+table_content_id+'" class="col-sm-6"><h3>Loading regulon UMAP plot <img src="static/images/busy.gif"></h3></div>')
		$('html, body').animate({
				scrollTop: $('#scroll_'+table_content_id).offset().top-100
			}, 500)
		},
		data: {'id': regulon_id},
		dataType: 'json',
		success: function(response) {
		overview_filepath = "./data/"+jobid+"/regulon_id/overview_provde_ct.pdf"
		regulon_score_filepath = "./data/"+jobid+"/regulon_id/"+ regulon_id +".pdf"
		$('#'+table_content_id).html("")
		$('#'+table_id).html('<div class="col-sm-6"><p>UMAP Plot Colored by Cell Clusters</p><input style="float:right; "class="btn btn-default" type="button" value="Download(PDF)" onClick="window.open(\''+overview_filepath+'\')" /><img src="./data/'+jobid+'/regulon_id/overview_provide_ct.png" /></div><div class="col-sm-6"><p>UMAP Plot Colored by ' + regulon_id + ' Score</p><input style="float:right; "class="btn btn-default" type="button" value="Download(PDF)" onClick="window.open(\''+regulon_score_filepath+'\')" /><img src="./data/'+jobid+'/regulon_id/' + regulon_id + '.png" onerror="this.onerror=null; this.src="assets/img/default_umap.png"" alt=""/></div>')
		},
	})
	}
	
	function show_trajectory_table(item) {
	
	match_id = $(item).attr("id").match(/\d+/gm)
	trajectory_regulon_id = $(item).attr("id").substring(14)
	ct_id= trajectory_regulon_id.substring(
    trajectory_regulon_id.lastIndexOf("CT") + 2, 
    trajectory_regulon_id.lastIndexOf("S")
	)
	trajectory_id = "trajectory-table-" + trajectory_regulon_id
	jobid = location.search.match(/\d+/gm)[0]
	trajectory_content_id = "trajectory-table-content-" + trajectory_regulon_id
	trajectory_jquery_id = "#" + trajectory_content_id
	$.ajax({
		url: "prepare_trajectory.php?jobid=" + jobid + "&id=" + trajectory_regulon_id,
		type: 'POST',
		beforeSend: function(){
		$('#'+trajectory_content_id).html('<div id="scroll_'+trajectory_content_id+'" class="col-sm-6"><h3>Loading trajectory plot <img src="static/images/busy.gif"></h3></div>') 
		$('html, body').animate({
				scrollTop: $('#scroll_'+trajectory_content_id).offset().top-100
			}, 500)
		},
		data: {'id': trajectory_regulon_id},
		dataType: 'json',
		success: function(response) {
		overview_filepath = "./data/"+jobid+"/regulon_id/overview_ct.trajectory.pdf"
		trajectory_score_filepath = "./data/"+jobid+"/regulon_id/"+ trajectory_regulon_id +".trajectory.pdf"
		$('#'+trajectory_content_id).html("")
		$('#'+trajectory_id).html('<div class="col-sm-6"><p>Trajectory Plot Colored by cell clusters</p><input style="float:right; "class="btn btn-default" type="button" value="Download(PDF)" onClick="window.open(\''+overview_filepath+'\')" /><img src="./data/'+jobid+'/regulon_id/overview_ct.trajectory.png" /></div><div class="col-sm-6"><p>Trajectory Plot Colored by ' + trajectory_regulon_id + ' Score</p><input style="float:right; "class="btn btn-default" type="button" value="Download(PDF)" onClick="window.open(\''+trajectory_score_filepath+'\')" /><img src="./data/'+jobid+'/regulon_id/' + trajectory_regulon_id + '.trajectory.png" /></div>')
		},
	})
	}
	
	function show_gene_tsne(item) {
	gene_regulon_id = $(item).attr("id").substring($(item).attr("id").indexOf("-")+1,$(item).attr("id").indexOf("_"))
	ct_id= gene_regulon_id.substring(
    gene_regulon_id.lastIndexOf("CT") + 2, 
    gene_regulon_id.lastIndexOf("S")
	)
	gene_symbol = $(item).attr("id").substring($(item).attr("id").lastIndexOf("_")+1)
	table_id = "gene-tsne-" + gene_regulon_id
	jobid = location.search.match(/\d+/gm)[0]
	table_content_id = "gene-tsne-content-" + gene_regulon_id
	table_jquery_id = "#" + table_content_id
	
	$.ajax({
		url: "prepare_gene_tsne.php?jobid=" + jobid + "&id=" + gene_symbol,
		type: 'POST',
		beforeSend: function(){
		document.getElementById(table_content_id).innerHTML = '<div id="scroll_'+table_content_id+'" class="col-sm-6"><h3>Loading gene UMAP plot <img src="static/images/busy.gif"></h3></div>'
		$('html, body').animate({
				scrollTop: $('#scroll_'+table_content_id).offset().top-100
			}, 500)
		},
		data: {'id': gene_symbol},
		dataType: 'json',
		success: function(response) {
		overview_filepath = "./data/"+jobid+"/regulon_id/overview_ct.pdf"
		expression_filepath = "./data/"+jobid+"/regulon_id/"+ gene_symbol +".umap.pdf"
		document.getElementById(table_content_id).innerHTML = ''
		let tmp = document.getElementById(table_id).innerHTML
		document.getElementById(table_id).innerHTML = tmp + '<div class="col-sm-6"><p>UMAP Plot Colored by cell clusters</p><input style="float:right; "class="btn btn-default" type="button" value="Download(PDF)" onClick="window.open(\''+overview_filepath+'\')" /><img src="./data/'+jobid+'/regulon_id/overview_provide_ct.png" /></div><div class="col-sm-6"><p>UMAP Plot Colored by Normalized '+ gene_symbol +' Gene Expression Value</p><input style="float:right; "class="btn btn-default" type="button" value="Download(PDF)" onClick="window.open(\''+expression_filepath+'\')" /><img src="./data/'+jobid+'/regulon_id/' + gene_symbol + '.umap.png" onerror="this.onerror=null; this.src="assets/img/default_umap.png"" alt=""/></div>'
		},
	})
	}
	
	function get_gene_list(item){
	match_id = $(item).attr("id").match(/\d+/gm)
	if($(item).attr("id").includes("CT")) {
		file_path = 'data/'+ {{$jobid}} +'/'+{{$jobid}} + '_CT_'+match_id[0]+'_bic.regulon_gene_symbol.txt'
	} else {
		file_path = 'data/'+ {{$jobid}} +'/'+{{$jobid}} + '_module_'+match_id[0]+'_bic.regulon_gene_symbol.txt'
	}
	$.get(file_path,function(txt){
        var lines = txt.split("\n")
		gene_idx = match_id[1] - 1
		lines[gene_idx].split("\t").shift().replace(/\t /g, '\n')
		gene_list = lines[gene_idx].split("\t")
		gene_list.shift()
		var enrichr_info = {list: gene_list.join("\n"), description: 'Gene list send to '+$(item).attr("id") , popup: true}

          send_to_Enrichr(enrichr_info)
    })
	}	
	
	function send_to_Enrichr(options) { // http://amp.pharm.mssm.edu/Enrichr/#help
    var defaultOptions = {
    description: "",
    popup: false
	}
	
  if (typeof options.description == 'undefined')
    options.description = defaultOptions.description
  if (typeof options.popup == 'undefined')
    options.popup = defaultOptions.popup
  if (typeof options.list == 'undefined')
    alert('No genes defined.')

  var form = document.createElement('form')
  form.setAttribute('method', 'post')
  form.setAttribute('action', 'https://amp.pharm.mssm.edu/Enrichr/enrich')
  if (options.popup)
    form.setAttribute('target', '_blank')
  form.setAttribute('enctype', 'multipart/form-data')

  var listField = document.createElement('input')
  listField.setAttribute('type', 'hidden')
  listField.setAttribute('name', 'list')
  listField.setAttribute('value', options.list)
  form.appendChild(listField);

  var descField = document.createElement('input')
  descField.setAttribute('type', 'hidden')
  descField.setAttribute('name', 'description')
  descField.setAttribute('value', options.description)
  form.appendChild(descField)

  document.body.appendChild(form)
  form.submit()
  document.body.removeChild(form)
}
	function copyToClipboard(text){
    const ele = document.createElement('textarea')
    ele.value = text; 
    ele.setAttribute('readonly', true)
  // Following styling is to avoid flashing textarea on screen 
    ele.style.position = 'absolute'
    ele.style.padding = 0
    ele.style.background = 'transparent'
    ele.style.outline = 'none';
    ele.style.left = '-100%'
  document.body.appendChild(ele)
  ele.select(); 
    document.execCommand('copy')
    document.body.removeChild(ele);
  }
 
	function copy_list(item){
	$(item).tooltip({
	  trigger: 'click',
	  placement: 'bottom'
	})
	function setTooltip(message) {
	  $(item).tooltip('show')
		.attr('data-original-title', message)
		.tooltip('show')
	}
	function hideTooltip() {
	  setTimeout(function() {
		$(item).tooltip('hide')
	  }, 3000)
	}
	match_ct = $(item).attr("id").match(/\d+/gm)
	match_type = ($(item).attr("id")[0] == "s") ? '_bic.regulon_gene_symbol.txt' : '_bic.regulon_gene_id.txt'
	//match_type = '_bic.regulon_gene_symbol.txt'
	if($(item).attr("id").includes("CT")) {
		file_path = 'data/'+ {{$jobid}} +'/'+{{$jobid}} + '_CT_'+match_ct[0] + match_type
	} else {
		file_path = 'data/'+ {{$jobid}} +'/'+{{$jobid}} + '_module_'+match_ct[0] + match_type
	}

	var xmlhttp = new XMLHttpRequest()
	 xmlhttp.open("GET", file_path, false)
	 xmlhttp.send();
	  if (xmlhttp.status==200) {
		txt = xmlhttp.responseText
		var lines = txt.split("\n")
		gene_idx = match_ct[1] - 1
		lines[gene_idx].split("\t").shift().replace(/\t /g, '\n')
		gene_list = lines[gene_idx].split("\t")
		gene_list.shift()
		//console.log(gene_list.join("\n"))
		copyToClipboard(gene_list.join("\n"))
		setTooltip('Copied!')
		hideTooltip()
	  } else {
		setTooltip('Failed!')
		hideTooltip()
	  }
	}
	
	$(document).ready(function() {
		$('.selectpicker').selectpicker();
		$('.enrichr_logo').css('display','none')

		$('#tablePreview').DataTable({
			"searching": false,
			"paging": false,
			"bInfo": false,
		})
		
		//make_clust_main('data/{{$jobid}}/json/CT1.json', '#container-id-1');
		//flag.push("#container-id-1")
	

		for (i=1;i<={{$count_ct|count}};i++) {
		  new List('regulon_pagination'+i, {
				valueNames: ['page_item'+i],
				page: 10,
				pagination: true,
				innerWindow: 5,
				outerWindow: 2
			})
		}
				
		const observer = lozad(); // lazy loads elements with default selector as '.lozad'
		observer.observe();

		$('.regulon_pagination_bar').click(function() {
			observer.observe();
		});

		function arrayContains(needle, arrhaystack) {
			return (arrhaystack.indexOf(needle) > -1)
		}

		// load CT1 dge by default
		$('#dge_table_ct_1').DataTable( {
			"ajax": 'data/{{$jobid}}/json/{{$jobid}}_CT_1_dge.json',
			dom: 'lBfrtip', 
			buttons: [
				{
				extend:'csv',
				title: {{$jobid}}+'_CT1'+'_diffrentially_expressed_genes'
				}
			]
			})

		
		$('a[data-toggle="tab"]').on('shown.bs.tab', function(e) {
			var json_file = $(e.target).attr("json")
			if (json_file === undefined) {
				json_file = ""
			}
			var root_id = $(e.target).attr("root")
			//console.log(!arrayContains(root_id,flag))
			if (json_file.includes('dge')) { // render dge table
				var this_ct = json_file.match(/\d+/g)[2]
				if ( !$.fn.dataTable.isDataTable('#dge_table_ct_'+this_ct)) {
					$('#dge_table_ct_'+this_ct).DataTable( {
						"ajax": json_file,
						dom: 'lBfrtip',
						buttons: [
							{
							extend:'csv',
							title: {{$jobid}}+'CT'+this_ct+'_diffrentially_expressed_genes'
							}
						]
						} )
				}
			} else if(!arrayContains(root_id,flag)) { // render clustergrammer
				var this_ct = root_id.match(/\d+/g)[0]
				$(root_id + '> .wait_message').html('Loading heatmap ... <img src="static/images/busy.gif">')
				$('#heatmap-header-'+this_ct).css('display','block')
				//$('#heatmap-hint').css('display','none')
				$('#main_CT'+this_ct).css('display','')
				make_clust(json_file, root_id)
				flag.push(root_id)
				
				$('#heatmap-hint').html('<p style="font-size:14px;font-weight:400;">Gene symbols may not appear when the number of rows is too large, please scroll the wheel on your mouse up to zoom in when the issue occurs.</p>')
			}
		});

		//end of ready
	});


	$.get(
      'data/{{$jobid}}/json/{{$jobid}}_umap.json',
      function(dat) {
        for (let i = 0; i < dat.length; i++){
          dat[i]['color'] = dat[i]['color'][0]
        }
        Highcharts.chart('highcharts_umap', {
          chart: {
            type: 'scatter',
            zoomType: 'xy'
          },
          boost: {
            useGPUTranslations: true,
            usePreAllocated: true
          },
          title: {
            text: 'UMAP Plot Colored by Cell Clusters'
          },
          xAxis: {
            title: {
              enabled: true,
              text: 'UMAP1'
            },
            startOnTick: true,
            endOnTick: true,
            showLastLabel: true,
						gridLineWidth: 0
          },
          yAxis: {
            title: {
							enabled:true,
              text: 'UMAP2'
            },
						startOnTick: true,
            endOnTick: true,
            showLastLabel: true,
						gridLineWidth: 0
          },
          legend: {
            layout: 'vertical',
            align: 'right',
            verticalAlign: 'top',
            x: 0,
            y: 60,
            floating: true,
            backgroundColor: Highcharts.defaultOptions.chart.backgroundColor,
            borderWidth: 0.5
          },
          plotOptions: {
            series: {
              turboThreshold: 100000,
              boostThreshold: 100000,			  // Comment out this code to display error
            },
            scatter: {
              marker: {
                radius: {{if $total_cell_num < 200}} 4 {{else if $total_cell_num < 500}} 3.5 {{else if $total_cell_num < 1000}} 2.8 {{else if $total_cell_num < 5000}} 2 {{else}} 1.2 {{/if}},
                states: {
                  hover: {
                    enabled: true,
                    lineColor: 'rgb(100,100,100)'
                  }
                }
              },
              states: {
                hover: {
                  marker: {
                    enabled: true
                  }
                }
              }
            }
          },
					exporting: {
    				buttons: {
        		  contextButton: {
              menuItems:["viewFullscreen", "downloadPNG", "downloadJPEG", "downloadPDF", "downloadSVG",{
                     text: 'Download TXT table',
                     onclick: function () {
                    	 fetch('https://bmbl.bmi.osumc.edu/iris3/data/{{$jobid}}/{{$jobid}}_umap_embeddings.txt')
												.then(resp => resp.blob())
												.then(blob => {
													const url = window.URL.createObjectURL(blob);
													const a = document.createElement('a');
													a.style.display = 'none';
													a.href = url;
													a.download = '{{$jobid}}_umap_embeddings.txt';
													document.body.appendChild(a);
													a.click();
													window.URL.revokeObjectURL(url);
												})
												.catch(() => alert('Download UMAP data failed!'));
                     }
                 }]
         	 	}
       		 },
						allowHTML: true,
							menuItemDefinitions: {
							downloadPDF: {
								text: 'Download PDF image',
								onclick: function() {
										this.exportChart({
												type: 'application/pdf',
												width: null
										});
								}
							}
    				}
    		  },
          series: dat,
          tooltip: {
                formatter: function() {
                   return  'Cluster index:'+this.series.name +'<br/>Cluster:' + this.series.options.cell_type[0] + '<br/>Cell name: ' + this.series.userOptions.data[this.point.index][2] + '<br/>[' + this.x + ',' + this.y +']'
               }
              }
        })
      }
    ).fail(function(jqxhr, status, error) {
      console.log('error', status, error)
    })

 </script>
 
<main role="main" class="container" style="min-height: calc(100vh - 182px);">
    <div id="content">
        <div class="container">
            <br/>
            <div class="flatPanel panel panel-default" >
                    {{if $status == "1"}}
                    <div class="row">
                        <div class="col-md-12">
                            <div class="panel with-nav-tabs panel-default">
                                <div class="panel-heading">
                                    <ul class="nav nav-tabs">
																			<li class="active"><a href="#tab1default" data-toggle="tab">Cell clustering</a></li>
                                    </ul>
                                </div>
                                <div class="panel-body">
                                    <div class="tab-content">
									<div class="tab-pane fade in active" id="tab1default">
										<div class="col-md-12 col-sm-12"> 
											<div class="row">
													<div class="form-group col-md-4 col-sm-4">
														<p id="species">Species: {{$species}} {{$main_species}}{{if $second_species != ''}},{{/if}} {{$second_species}}</p>
																					</div>
																					<div class="form-group col-md-4 col-sm-4">
																							<p>Number of cells: {{$total_cell_num}}</p>
																					</div>
																					<div class="form-group col-md-4 col-sm-4">
																							<p>Number of genes: {{$total_gene_num}}</p>
																					</div>
																					<div class="form-group col-md-4 col-sm-4">
																							<p>Number of filtered genes: {{$filter_gene_num}}</p>
																					</div>
																					<div class="form-group col-md-4 col-sm-4">
																							<p>Gene filtering ratio: {{$filter_gene_rate*100}}%</p>
																					</div>
													<div class="form-group col-md-4 col-sm-4">
																							<p>Number of filtered cells: {{$filter_cell_num}}</p>
																					</div>
																					<div class="form-group col-md-4 col-sm-4">
																							<p>Cell filtering ratio: {{$filter_cell_rate*100}}%</p>
																					</div>
													{{if $provide_label > 0}}
																					<div class="form-group col-md-4 col-sm-4">
																							<p>Number of provided cell clusters: {{$provide_label}}</p>
																					</div>
													{{/if}}
													<div class="form-group col-md-4 col-sm-4">
																							<p>Number of predicted cell clusters: {{$predict_label}}</p>
																					</div>
																					<div class="form-group col-md-4 col-sm-4">
																							<p>Total biclusters: {{$total_bic}}</p>
																					</div>
													</div>
													<hr/>
											<div
												id="highcharts_umap"
												style="min-width: 310px; height: 600px; max-width: 1000px; margin: 0 auto"
											></div>
											<hr/>
											{{if ($ARI  >0)}}
																		 <table id="tablePreview" class="table">
																				<thead>
																						<tr>
																								<th>Adjusted Rand Index (ARI)</th>
																								<th>Rand Index (RI)</th>
																								<th>Jaccard Index (JI)</th>
																								<th>Fowlkes and Mallows's index (FMI)</th>
																						</tr>
																				</thead>
																				<tbody>
																						<tr>
																								<td>{{$ARI}}</td>
																								<td>{{$RI}}</td>
																								<td>{{$JI}}</td>
																								<td>{{$FMI}}</td>
																						</tr>
																				</tbody>
																		</table>
													<hr/>
											{{/if}}
											<div class="panel with-nav-tabs panel-default">
											<div class="panel-heading">
												<ul class="nav nav-tabs">
														<li><a href="#plot-tab1default" data-toggle="tab">UMAP Plot</a></li>
														<li><a href="#tab4default" data-toggle="tab">Differentially expressed genes</a></li>
														<li><a href="#plot-tab2default" data-toggle="tab">Trajectory Plot</a></li>
														<li><a href="#plot-tab3default" data-toggle="tab">Silhouette score</a></li>
														{{if ($sankey_src|@count >0)}}<li><a href="#plot-tab4default" data-toggle="tab">Sankey plot</a></li>{{/if}}
												</ul>
											</div>
											<div class="panel-body">
												<div class="tab-content">
													<div class="tab-pane fade" id="plot-tab1default">
														<div class="flatPanel panel-default">
															{{if $label_use_predict == 'user\'s label'}}
															<div class="CT-result-img">
																												<div class="col-sm-6">
																<h4 style="text-align:center;margin-top:50px"> UMAP Plot Colored by Provided Cell Clusters</h4>
																													 <input style="float:right; "class="btn btn-default" type="button" value="Download(PDF)" onClick="window.open('data/{{$jobid}}/regulon_id/overview_provide_ct.pdf')" />
																	 <img class="lozad" style="width:100%" data-src="data/{{$jobid}}/regulon_id/overview_provide_ct.png"></img>
																</div>
																<div class="col-sm-6">
																<h4 style="text-align:center;margin-top:50px"> UMAP Plot Colored by Predicted Cell Clusters</h4>
																													 <input style="float:right; "class="btn btn-default" type="button" value="Download(PDF)" onClick="window.open('data/{{$jobid}}/regulon_id/overview_predict_ct.pdf')" />
																	 <img class="lozad" style="width:100%" data-src="data/{{$jobid}}/regulon_id/overview_predict_ct.png"></img>
																</div>
															</div>
															{{else}}
															<div class="CT-result-img">
																												<div class="col-sm-6">
																<h4 style="text-align:center;margin-top:50px"> UMAP Plot Colored by Cell Clusters</h4>
																													 <input style="float:right; "class="btn btn-default" type="button" value="Download(PDF)" onClick="window.open('data/{{$jobid}}/regulon_id/overview_ct.pdf')" />
																	 <img class="lozad" style="width:100%" data-src="data/{{$jobid}}/regulon_id/overview_ct.png"></img>
																</div>
															</div>
															{{/if}}
														</div>
													</div>
													<div class="tab-pane fade" id="tab4default">
														<ul class="nav nav-tabs nav-sticky" id="dgeTab" role="tablist">
															{{section name=ct_idx start=0 loop=$count_ct}}
																<li class="nav-item {{if {{$count_ct[ct_idx]}} eq '1'}}active{{/if}}">
																		<a class="nav-link fade in {{if {{$count_ct[ct_idx]}} eq '0'}}active{{/if}}" id="nav-{{$count_ct[ct_idx]}}" data-toggle="tab" tabtype="main" href="#dge_CT{{$count_ct[ct_idx]}}" json="data/{{$jobid}}/json/{{$jobid}}_CT_{{$count_ct[ct_idx]}}_dge.json" root="#dge_table_ct_{{$count_ct[ct_idx]}}" role="tab" aria-controls="home" aria-selected="true">CT{{$count_ct[ct_idx]}}</a>
																</li>
															{{/section}}
															</ul>
															<div class="tab-content" id="dgeTabContent">	
																{{section name=ct_idx start=0 loop=$count_ct}}	{{/section}}
																{{foreach from=$regulon_result item=label1 key=sec0}}	
																	<div class="tab-pane {{if {{$sec0+1}} eq '1'}}active{{/if}}" id="dge_CT{{$sec0+1}}" role="tabpanel">
																		<div class="flatPanel panel panel-default ct-panel">
																					<div class="row">
																						<div class="form-group col-md-12 col-sm-12" style="height:100%">
																							<table id="dge_table_ct_{{$sec0+1}}" class="display" style="width:100%">
																								<thead>
																									<tr>
																										<th>Cell Cluster</th>
																										<th>Gene</th>
																										<th>P-value</th>
																										<th>Avg_logFC</th>
																										<th>Pct.1</th>
																										<th>Pct.2</th>
																										<th>Adjusted p-value</th>
																									</tr>
																								</thead>
																							</table>
																						</div>
																							</div></div> </div> {{/foreach}}</div>
													</div>
													<div class="tab-pane fade" id="plot-tab2default">
														<div class="flatPanel panel-default">
															{{if $label_use_predict == 'user\'s label'}}
															<div class="CT-result-img">
																<div class="col-sm-6">
																<h4 style="text-align:center;margin-top:50px"> Trajectory Plot Colored by Cell Clusters</h4>
																													 <input style="float:right; "class="btn btn-default" type="button" value="Download(PDF)" onClick="window.open('data/{{$jobid}}/regulon_id/overview_ct.trajectory.pdf')" />
																	 <img class="lozad" style="width:100%" data-src="data/{{$jobid}}/regulon_id/overview_ct.trajectory.png"  onerror="this.onerror=null; this.src='assets/img/default_trajectory.png'" alt=""></img>
																</div>
																<div class="row">
																</div>
															</div>	
															{{else}}
															<div class="CT-result-img">
																<div class="col-sm-6">
																<h4 style="text-align:center;margin-top:50px"> Trajectory Plot Colored by Cell Clusters</h4>
																														<input style="float:right; "class="btn btn-default" type="button" value="Download(PDF)" onClick="window.open('data/{{$jobid}}/regulon_id/overview_ct.trajectory.pdf')" />
																	<img class="lozad" style="width:100%" data-src="data/{{$jobid}}/regulon_id/overview_ct.trajectory.png"  onerror="this.onerror=null; this.src='assets/img/default_trajectory.png'" alt=""></img>
																</div>
															</div>
															{{/if}}
														</div>
												</div>
												<div class="tab-pane fade" id="plot-tab3default">
													<div class="panel-body">
														<div class="flatPanel panel-default"> 
															<div class="CT-result-img">
																<div class="col-sm-12">
																<h4 style="text-align:center;margin-top:50px"> Silhouette score</h4>
																	<div id="score_div"></div>
																</div>
															</div>
														</div>
													</div>
											</div>
											<div class="tab-pane fade" id="plot-tab4default">
												<div class="panel-body">
													<div class="flatPanel  panel-default">
														<div class="CT-result-img">
															{{if ($sankey_src|@count >0)}}
															<div class="col-sm-12">
															<h4 style="text-align:center;margin-top:50px"> Sankey plot</h4>
																<div id="sankey_div" style="max-width: 95%; display:block;"></div>
															</div>
															{{/if}}
														</div>
													</div>
												</div>
											</div>
										</div>
									</div>  
								</div>  
							</div>
														
                                            </div>
                                        		
                            </div>
                        </div>
                    </div>
                    
						</div>
                    </div>
					 </div>
					 </div>
            </div>
					{{elseif $status==="404"}}
					<div class="flatPanel panel-heading" style="padding: 20px 20px"><strong>Job ID: {{$jobid}}</strong></div>
                <div class="panel-body">
					<div style="text-align: left;">
                        <p>Job ID not found</p>
                    </div>
					</div>
					{{elseif $status==="error"}}
					<div class="flatPanel panel-heading" style="padding: 20px 20px"><strong>Job ID: {{$jobid}}</strong></div>
						<div class="panel-body">
					<div style="text-align: left;">
												<strong><h3>Sorry, there has been an error.</h3></strong>
												<p>Please check with your <span style="color: red;">input data format</span> and <span style="color: red;">species</span> information: </p><p>1. The required input is gene expression data with three acceptable formats, The expression value should be positive.</p>
												<ul>
														<li>A single txt, tsv or csv formatted gene expression matrix. The compressed format (gzip) is accepted.</li>
														<li>An <a href="https://support.10xgenomics.com/single-cell-atac/software/pipelines/latest/advanced/h5_matrices" target="_blank"><strong>hdf5 feature barcode matrix</strong></a></li>
														<li>The <a href="https://support.10xgenomics.com/single-cell-gene-expression/software/pipelines/latest/output/matrices" target="_blank"><strong>three files</strong></a> recording information of barcodes, features, and gene expressions in the 10X genomics
																output folder, all three files should be the raw compressed format. </li>
												</ul><p>2. Cell label file (Optional): a two-column matrix with the first column as the cell names exactly matching the gene expression file, and the second column as ground-truth cell clusters. </p><p>3. Gene module file (Optional): Each column should reprensents a gene module.</p>
						
						<p>Pleas check our <a href="https://bmbl.bmi.osumc.edu/iris3/tutorial.php#1basics">tutorial</a> for more information. </p>
						<br>
                    </div>
					
					<strong>Job settings:</strong><br>
                            <div class="col-md-12 col-sm-12">
								<div class="form-group col-md-6 col-sm-6">
                                    <p>Species: {{$input_species}}</p>
                                </div>
                                <div class="form-group col-md-6 col-sm-6">
                                    <p for="reportsList">Enable imputation: {{$is_imputation}}</p>
                                </div>
																<div class="form-group col-md-6 col-sm-6">
																	<p for="reportsList">Remove ribosome genes: {{$remove_ribosome}}</p>
																</div>
                                <div class="form-group col-md-6 col-sm-6">
                                    <p>Enable dual strategy: {{$is_c}}</p>
                                </div>
								<div class="form-group col-md-6 col-sm-6">
                                    <p for="reportsList">Minimum cell number: {{$k_arg}}</p>
                                </div>
                                <div class="form-group col-md-6 col-sm-6">
                                    <p>Maximum bicluster number: {{$o_arg}}</p>
                                </div>
                                <div class="form-group col-md-6 col-sm-6">
                                    <p>Bicluster overlap rate: {{$f_arg}}</p>
                                </div>
								<div class="form-group col-md-6 col-sm-6">
                                    <p>Cell clustering method: {{$label_use_predict}}</p>
                                </div>
								<div class="form-group col-md-6 col-sm-6">
                                    <p>Upstream promoter region: {{$promoter_arg}}</p>
                                </div>
								<div class="form-group col-md-6 col-sm-6"> 
                                    <p>Email: {{$email_line}}</p>
                                </div>
                                <div class="form-group col-md-6 col-sm-6"> 
                                    <p>Uploaded files: </p><p>{{$expfile_name}}</p><p>{{$labelfile_name}}</p><p>{{$gene_module_file_name}}</p>
                                </div>
                            </div>
					</div>
					{{elseif $status==="error_bic"}}
					<div class="flatPanel panel-heading" style="padding: 20px 20px"><strong>Job ID: {{$jobid}}</strong></div>
						<div class="panel-body">
					<div style="text-align: left;">
                        <strong><h3>Sorry, there has been an error:</h3></strong> <p style="color:red">IRIS3 did not find enough bi-clusters in your data.</p>
						<ul>
						
						<li>
						Each gene measured in the expression dataset should have an identifier listed in the first column, both Gene Symbols (e.g. HSPA9) and Gene IDs (e.g. ENSG00000113013) are allowed.
						</li>
						<li>
						The selected species is: {{$input_species}}, please check it since we noticed that many errors occur due to the unmatched species information.
						</li>
						<li>
						The minimum cell number parameter is set to {{$k_arg}}, it is important to set a smaller minimal cell numer in a small dataset. E.g. set to 5 for cell number less than 100.
						</li>
						</ul>
						<p>Pleas check our <a href="https://bmbl.bmi.osumc.edu/iris3/tutorial.php#1basics">tutorial</a> for more information. </p>
						<br>
                    </div>
					
					<strong>Job settings:</strong><br>
                            <div class="col-md-12 col-sm-12">
								<div class="form-group col-md-6 col-sm-6">
                                    <p>Species: {{$input_species}}</p>
                                </div>
                                <div class="form-group col-md-6 col-sm-6">
                                    <p for="reportsList">Enable imputation: {{$is_imputation}}</p>
                                </div>
																<div class="form-group col-md-6 col-sm-6">
																	<p for="reportsList">Remove ribosome genes: {{$remove_ribosome}}</p>
																</div>
																<div class="form-group col-md-6 col-sm-6">
                                    <p>Enable dual strategy: {{$is_c}}</p>
                                </div>
								<div class="form-group col-md-6 col-sm-6">
                                    <p for="reportsList">Minimum cell number: {{$k_arg}}</p>
                                </div>
                                <div class="form-group col-md-6 col-sm-6">
                                    <p>Maximum bicluster number: {{$o_arg}}</p>
                                </div>
                                <div class="form-group col-md-6 col-sm-6">
                                    <p>Bicluster overlap rate: {{$f_arg}}</p>
                                </div>
								<div class="form-group col-md-6 col-sm-6">
                                    <p>Cell clustering method: {{$label_use_predict}}</p>
                                </div>
								<div class="form-group col-md-6 col-sm-6">
                                    <p>Upstream promoter region: {{$promoter_arg}}</p>
                                </div>
								<div class="form-group col-md-6 col-sm-6"> 
                                    <p>Email: {{$email_line}}</p>
                                </div>
                                <div class="form-group col-md-6 col-sm-6"> 
                                    <p>Uploaded files: </p><p>{{$expfile_name}}</p><p>{{$labelfile_name}}</p><p>{{$gene_module_file_name}}</p>
                                </div>
                            </div>
					</div>
										{{elseif $status==="error_num_cells"}}
					<div class="flatPanel panel-heading" style="padding: 20px 20px"><strong>Job ID: {{$jobid}}</strong></div>
						<div class="panel-body">
					<div style="text-align: left;">
                        <strong><h3>Sorry, there has been an error</h3></strong> <p>Please check with your <span style="color: red;">input data format</span> and <span style="color: red;">species</span> information: <p>1. The required input is gene expression data with three acceptable formats, The expression value should be positive.</p>
												<ul>
														<li>A single txt, tsv or csv formatted gene expression matrix. The compressed format (gzip) is accepted.</li>
														<li>An <a href="https://support.10xgenomics.com/single-cell-atac/software/pipelines/latest/advanced/h5_matrices" target="_blank"><strong>hdf5 feature barcode matrix</strong></a></li>
														<li>The <a href="https://support.10xgenomics.com/single-cell-gene-expression/software/pipelines/latest/output/matrices" target="_blank"><strong>three files</strong></a> recording information of barcodes, features, and gene expressions in the 10X genomics
																output folder, all three files should be the raw compressed format. </li>
												</ul><p>2. Cell label file (Optional): a two-column matrix with the first column as the cell names exactly matching the gene expression file, and the second column as ground-truth cell clusters. </p><p>3. Gene module file (Optional): Each column should reprensents a gene module.</p>
						<br>For further question, please contact qin.ma@osumc.edu<br>
						<br>
                    </div>
					
					<strong>Job settings:</strong><br>
                            <div class="col-md-12 col-sm-12">
								<div class="form-group col-md-6 col-sm-6">
                                    <p>Species: {{$input_species}}</p>
                                </div>
                                <div class="form-group col-md-6 col-sm-6">
                                    <p for="reportsList">Enable imputation: {{$is_imputation}}</p>
                                </div>
																<div class="form-group col-md-6 col-sm-6">
																	<p for="reportsList">Remove ribosome genes: {{$remove_ribosome}}</p>
																</div>
                                <div class="form-group col-md-6 col-sm-6">
                                    <p>Enable dual strategy: {{$is_c}}</p>
                                </div>
								<div class="form-group col-md-6 col-sm-6">
                                    <p for="reportsList">Minimum cell number: {{$k_arg}}</p>
                                </div>
                                <div class="form-group col-md-6 col-sm-6">
                                    <p>Maximum bicluster number: {{$o_arg}}</p>
                                </div>
                                <div class="form-group col-md-6 col-sm-6">
                                    <p>Bicluster overlap rate: {{$f_arg}}</p>
                                </div>
								<div class="form-group col-md-6 col-sm-6">
                                    <p>Cell clustering method: {{$label_use_predict}}</p>
                                </div>
								<div class="form-group col-md-6 col-sm-6">
                                    <p>Upstream promoter region: {{$promoter_arg}}</p>
                                </div>
								<div class="form-group col-md-6 col-sm-6"> 
                                    <p>Email: {{$email_line}}</p>
                                </div>
                                <div class="form-group col-md-6 col-sm-6"> 
                                    <p>Uploaded files: </p><p>{{$expfile_name}}</p><p>{{$labelfile_name}}</p><p>{{$gene_module_file_name}}</p>
                                </div>
                            </div>
					</div>
					{{elseif $status==="complete_seurat1"}}
					<div class="flatPanel panel-heading" style="padding: 20px 20px"><strong>Job ID: {{$jobid}}</strong></div>
						<div class="panel-body">
					<div style="text-align: left;">
                        <strong><h3>Sorry, there has been an error</h3></strong> <p>Please check with your <span style="color: red;">input data format</span> and <span style="color: red;">species</span> information: <p>1. The required input is gene expression data with three acceptable formats, The expression value should be positive.</p>
												<ul>
														<li>A single txt, tsv or csv formatted gene expression matrix. The compressed format (gzip) is accepted.</li>
														<li>An <a href="https://support.10xgenomics.com/single-cell-atac/software/pipelines/latest/advanced/h5_matrices" target="_blank"><strong>hdf5 feature barcode matrix</strong></a></li>
														<li>The <a href="https://support.10xgenomics.com/single-cell-gene-expression/software/pipelines/latest/output/matrices" target="_blank"><strong>three files</strong></a> recording information of barcodes, features, and gene expressions in the 10X genomics
																output folder, all three files should be the raw compressed format. </li>
												</ul><p>2. Cell label file (Optional): a two-column matrix with the first column as the cell names exactly matching the gene expression file, and the second column as ground-truth cell clusters. </p><p>3. Gene module file (Optional): Each column should reprensents a gene module.</p>
						<br>For further question, please contact qin.ma@osumc.edu<br>
						<br>
                    </div>
					
					<strong>Job settings:</strong><br>
                            <div class="col-md-12 col-sm-12">
								<div class="form-group col-md-6 col-sm-6">
                                    <p>Species: {{$input_species}}</p>
                                </div>
                                <div class="form-group col-md-6 col-sm-6">
                                    <p for="reportsList">Enable imputation: {{$is_imputation}}</p>
                                </div>
																<div class="form-group col-md-6 col-sm-6">
																	<p for="reportsList">Remove ribosome genes: {{$remove_ribosome}}</p>
																</div>
                                <div class="form-group col-md-6 col-sm-6">
                                    <p>Enable dual strategy: {{$is_c}}</p>
                                </div>
								<div class="form-group col-md-6 col-sm-6">
                                    <p for="reportsList">Minimum cell number: {{$k_arg}}</p>
                                </div>
                                <div class="form-group col-md-6 col-sm-6">
                                    <p>Maximum bicluster number: {{$o_arg}}</p>
                                </div>
                                <div class="form-group col-md-6 col-sm-6">
                                    <p>Bicluster overlap rate: {{$f_arg}}</p>
                                </div>
								<div class="form-group col-md-6 col-sm-6">
                                    <p>Cell clustering method: {{$label_use_predict}}</p>
                                </div>
								<div class="form-group col-md-6 col-sm-6">
                                    <p>Upstream promoter region: {{$promoter_arg}}</p>
                                </div>
								<div class="form-group col-md-6 col-sm-6"> 
                                    <p>Email: {{$email_line}}</p>
                                </div>
                                <div class="form-group col-md-6 col-sm-6"> 
                                    <p>Uploaded files: </p><p>{{$expfile_name}}</p><p>{{$labelfile_name}}</p><p>{{$gene_module_file_name}}</p>
                                </div>
                            </div>
					</div>
					{{else}} {{block name="meta"}}
					<div id="myModal" class="modal fade" role="dialog">
						<div class="modal-dialog">
					
							<!-- Modal content-->
							<div class="modal-content">
								<div class="modal-header">
									<button type="button" class="close" data-dismiss="modal">&times;</button>
									<h4 class="modal-title">Terminate your job</h4>
								</div>
								<div class="modal-body">
									<p>WARNING: This will delete all files belong to Job ID: {{$jobid}}</p>
								</div>
								<div class="modal-footer">
									<button type="button" class="btn btn-warning" data-dismiss="modal" onclick="terminate_job(this)">Confirm</button>
									<button type="button" class="btn btn-success" data-dismiss="modal">Close</button>
								</div>
							</div>
					
						</div>
					</div>
					<div class="flatPanel panel-heading" style="padding: 20px 20px"><strong>Job ID: {{$jobid}}</strong></div>
                <div class="panel-body">
                    <META HTTP-EQUIV="REFRESH" CONTENT="180"> {{/block}}

                    <div style="text-align: left;">
                        <div class="flatPanel panel panel-default">
                        <div class="panel-body"><p>
							<p>Your job has been submitted successfully! Thanks for your interest in using IRIS3.</p>
							<p>Your job ID is  <font color="red"> <strong>{{$jobid}}</strong></font>, which can be used to retrieve the prediction results in the searching bar at <a href="https://bmbl.bmi.osumc.edu/iris3">https://bmbl.bmi.osumc.edu/iris3</a></p>
							<p>Note: The running time usually takes a few hours and can be more than 10 hours if there are more than 5000 cells in your data. Hence, we recommend you bookmark this page or save the job ID; and retrieve the result at your convenience later. </p>
							<p>Please feel free to contact us at qin.ma@osumc.edu, if you might have any questions regarding your job.</p>
							<hr/>
							<strong>Job status: (Cell clustering results will be available to preview after step II)</strong><br>
							{{if $running_status == 'preprocessing'}}
							<p>Step I: Data pre-processing.(Running)<img src="static/images/busy.gif" /> <button type="button" class="btn btn-warning" data-toggle="modal" data-target="#myModal">Terminate your job</button>
							<p class="waiting_job_status">Step II: Cell clustering.</p>
							<p class="waiting_job_status">Step III: Gene module detection.</p>
							<p class="waiting_job_status">Step IV: Active gene module determination.</p>
							<p class="waiting_job_status">Step V: Motif finding and comparison.</p>
							<p class="waiting_job_status">Step VI: Regulon determination.</p>
							<p class="waiting_job_status">Step VII: CTSR inference.</p>
							{{else if $running_status == 'cell_cluster_prediction'}}
							<p>Step I: Data pre-processing.(Complete)</p>
							<p>Step II: Cell clustering.(Running)<img src="static/images/busy.gif" /> <button type="button" class="btn btn-warning" data-toggle="modal" data-target="#myModal">Terminate your job</button>
							<p class="waiting_job_status">Step III: Gene module detection.</p>
							<p class="waiting_job_status">Step IV: Active gene module determination.</p>
							<p class="waiting_job_status">Step V: Motif finding and comparison.</p>
							<p class="waiting_job_status">Step VI: Regulon determination.</p>
							<p class="waiting_job_status">Step VII: CTSR inference.</p>
							{{else if $running_status == 'gene_module_detection'}}
							<p>Step I: Data pre-processing.(Complete)</p>
							<p>Step II: Cell clustering.(Complete)</p>
							<p>Step III: Gene module detection.(Running)<img src="static/images/busy.gif" /> <button type="button" class="btn btn-warning" data-toggle="modal" data-target="#myModal">Terminate your job</button>
							<p class="waiting_job_status">Step IV: Active gene module determination.</p>
							<p class="waiting_job_status">Step V: Motif finding and comparison.</p>
							<p class="waiting_job_status">Step VI: Regulon determination.</p>
							<p class="waiting_job_status">Step VII: CTSR inference.</p>
							{{else if $running_status == 'gene_module_assignment'}}
							<p>Step I: Data pre-processing.(Complete)</p>
							<p>Step II: Cell clustering.(Complete)</p>
							<p>Step III: Gene module detection.(Complete)</p>
							<p>Step IV: Active gene module determination.(Running)<img src="static/images/busy.gif" /> <button type="button" class="btn btn-warning" data-toggle="modal" data-target="#myModal">Terminate your job</button>
							<p class="waiting_job_status">Step V: Motif finding and comparison.</p>
							<p class="waiting_job_status">Step VI: Regulon determination.</p>
							<p class="waiting_job_status">Step VII: CTSR inference.</p>
							{{else if $running_status == 'motif_finding_and_comparison'}}
							<p>Step I: Data pre-processing.(Complete)</p>
							<p>Step II: Cell clustering.(Complete)</p>
							<p>Step III: Gene module detection.(Complete)</p>
							<p>Step IV: Active gene module determination.(Complete)</p>
							<p>Step V: Motif finding and comparison.(Running)<img src="static/images/busy.gif" /> <button type="button" class="btn btn-warning" data-toggle="modal" data-target="#myModal">Terminate your job</button>
							<p class="waiting_job_status">Step VI: Regulon determination.</p>
							<p class="waiting_job_status">Step VII: CTSR inference.</p>
							{{else if $running_status == 'active_regulon_determination'}}
							<p>Step I: Data pre-processing.(Complete)</p>
							<p>Step II: Cell clustering.(Complete)</p>
							<p>Step III: Gene module detection.(Complete)</p>
							<p>Step IV: Active gene module determination.(Complete)</p>
							<p>Step V: Motif finding and comparison.(Complete)</p>
							<p>Step VI: Regulon determination.(Running)<img src="static/images/busy.gif" /> <button type="button" class="btn btn-warning" data-toggle="modal" data-target="#myModal">Terminate your job</button>
							<p class="waiting_job_status">Step VII: CTSR inference.</p>
							{{else if $running_status == 'regulon_inference'}}
							<p>Step I: Data Pre-processing.(Complete)</p>
							<p>Step II: Cell clustering.(Complete)</p>
							<p>Step III: Gene module detection.(Complete)</p>
							<p>Step IV: Active gene module determination.(Complete)</p>
							<p>Step V: Motif finding and comparison.(Complete)</p>
							<p>Step VI: Regulon determination.(Complete)</p>
							<p>Step VII: CTSR inference.(Running)<img src="static/images/busy.gif" /> <button type="button" class="btn btn-warning" data-toggle="modal" data-target="#myModal">Terminate your job</button>
							{{/if}}
							 
              <p>This page will be automatically refreshed every <b>180</b> seconds.</p>
							<hr/>
							{{if $running_status == 'preprocessing' or $running_status == 'cell_cluster_prediction'}}
							<strong>Job settings:</strong><br>
                            <div class="col-md-12 col-sm-12">
								<div class="form-group col-md-6 col-sm-6">
                                    <p>Species: {{$input_species}}</p>
                                </div>
                                <div class="form-group col-md-6 col-sm-6">
                                    <p for="reportsList">Enable imputation: {{$is_imputation}}</p>
																</div>
																<div class="form-group col-md-6 col-sm-6">
																	<p for="reportsList">Remove ribosome genes: {{$remove_ribosome}}</p>
																</div>
																<div class="form-group col-md-6 col-sm-6">
																	<p>Number of principle components: {{$n_pca}}</p>
															</div>
															<div class="form-group col-md-6 col-sm-6">
																		<p>Number of highly variable features: {{$n_variable_features}}</p>
																</div>
																<div class="form-group col-md-6 col-sm-6">
																	<p>Cell clustering resolution: {{$resolution_seurat}}</p>
															</div>
                                <div class="form-group col-md-6 col-sm-6">
                                    <p>Enable dual strategy: {{$is_c}}</p>
                                </div>
								<div class="form-group col-md-6 col-sm-6">
                                <p for="reportsList">Minimum cell number: {{$k_arg}}</p>
                                </div>
                                <div class="form-group col-md-6 col-sm-6">
                                    <p>Maximum bicluster number: {{$o_arg}}</p>
                                </div>
                                <div class="form-group col-md-6 col-sm-6">
                                    <p>Bicluster overlap rate: {{$f_arg}}</p>
                                </div>
								<div class="form-group col-md-6 col-sm-6">
                                    <p>Cell clustering method: {{$label_use_predict}}</p>
                                </div>
								<div class="form-group col-md-6 col-sm-6">
                                    <p>Upstream promoter region: {{$promoter_arg}}</p>
                                </div>
								<div class="form-group col-md-6 col-sm-6"> 
                                    <p>Email: {{$email_line}}</p>
                                </div>
                                <div class="form-group col-md-6 col-sm-6"> 
                                    <p>Uploaded files: </p><p>{{$expfile_name}}</p><p>{{$labelfile_name}}</p><p>{{$gene_module_file_name}}</p>
                                </div>
                </div>

							{{else}}
							<strong>You may preview the available results:</strong><br>
														<div class="panel-heading">
															<ul class="nav nav-tabs">
																	<li class="active"><a href="#preview-tab1default" data-toggle="tab">Cell cluster plot (interactive)</a></li>
																	<li><a href="#preview-tab2default" data-toggle="tab">Cell cluster plot (static)</a></li>
																	<li><a href="#preview-tab3default" data-toggle="tab">Differentially expressed genes</a></li>
																	<li><a href="#preview-tab4default" data-toggle="tab">Job information</a></li>
															</ul>
													</div>
													<div class="panel-body">
														  <div class="tab-content">
															  <div class="tab-pane fade in active" id="preview-tab1default">
																	  <div class="flatPanel panel panel-default">
																		  <div class="panel-body">
																				<div class="col-md-12 col-sm-12"> 
																					<div id="highcharts_umap" style="min-width: 310px; height: 600px; max-width: 1000px; margin: 0 auto"></div>
																				</div>
																		  </div>
																    </div>
																</div>
																<div class="tab-pane fade " id="preview-tab2default">
																		{{if $label_use_predict == 'user\'s label'}}
																		<div class="CT-result-img">
																															<div class="col-sm-6">
																			<h4 style="text-align:center;margin-top:50px"> UMAP Plot Colored by Provided Cell Clusters</h4>
																																 <input style="float:right; "class="btn btn-default" type="button" value="Download(PDF)" onClick="window.open('data/{{$jobid}}/regulon_id/overview_provide_ct.pdf')" />
																				 <img class="lozad" style="width:100%" data-src="data/{{$jobid}}/regulon_id/overview_provide_ct.png"></img>
																			</div>
																			<div class="col-sm-6">
																			<h4 style="text-align:center;margin-top:50px"> UMAP Plot Colored by Predicted Cell Clusters</h4>
																																 <input style="float:right; "class="btn btn-default" type="button" value="Download(PDF)" onClick="window.open('data/{{$jobid}}/regulon_id/overview_predict_ct.pdf')" />
																				 <img class="lozad" style="width:100%" data-src="data/{{$jobid}}/regulon_id/overview_predict_ct.png"></img>
																			</div>
																		</div>
																		<div class="CT-result-img">
																			<div class="col-sm-6">
																			<h4 style="text-align:center;margin-top:50px"> Trajectory Plot Colored by Cell Clusters</h4>
																																 <input style="float:right; "class="btn btn-default" type="button" value="Download(PDF)" onClick="window.open('data/{{$jobid}}/regulon_id/overview_ct.trajectory.pdf')" />
																				 <img class="lozad" style="width:100%" data-src="data/{{$jobid}}/regulon_id/overview_ct.trajectory.png"  onerror="this.onerror=null; this.src='assets/img/default_trajectory.png'" alt=""></img>
																			</div>
																			<div class="row">
																			</div>
																		</div>	
																		{{else}}
																		<div class="CT-result-img">
																															<div class="col-sm-6">
																			<h4 style="text-align:center;margin-top:50px"> UMAP Plot Colored by Cell Clusters</h4>
																																 <input style="float:right; "class="btn btn-default" type="button" value="Download(PDF)" onClick="window.open('data/{{$jobid}}/regulon_id/overview_ct.pdf')" />
																				 <img class="lozad" style="width:100%" data-src="data/{{$jobid}}/regulon_id/overview_ct.png"></img>
																			</div>
																			<div class="col-sm-6">
																			<h4 style="text-align:center;margin-top:50px"> Trajectory Plot Colored by Cell Clusters</h4>
																																	<input style="float:right; "class="btn btn-default" type="button" value="Download(PDF)" onClick="window.open('data/{{$jobid}}/regulon_id/overview_ct.trajectory.pdf')" />
																				<img class="lozad" style="width:100%" data-src="data/{{$jobid}}/regulon_id/overview_ct.trajectory.png"  onerror="this.onerror=null; this.src='assets/img/default_trajectory.png'" alt=""></img>
																			</div>
																		</div>
																		{{/if}}
																</div>
																<div class="tab-pane fade" id="preview-tab3default">
																	<ul class="nav nav-tabs nav-sticky" id="dgeTab" role="tablist">
																		{{section name=ct_idx start=0 loop=$count_dge}}
																			<li class="nav-item {{if {{$count_dge[ct_idx]}} eq '1'}}active{{/if}}">
																					<a class="nav-link fade in {{if {{$count_dge[ct_idx]}} eq '0'}}active{{/if}}" id="nav-{{$count_dge[ct_idx]}}" data-toggle="tab" tabtype="main" href="#dge_CT{{$count_dge[ct_idx]}}" json="data/{{$jobid}}/json/{{$jobid}}_CT_{{$count_dge[ct_idx]}}_dge.json" root="#dge_table_ct_{{$count_dge[ct_idx]}}" role="tab" aria-controls="home" aria-selected="true">CT{{$count_dge[ct_idx]}}</a>
																			</li>
																		{{/section}}
																		</ul>
																		<div class="tab-content" id="dgeTabContent">	
																			{{section name=ct_idx start=0 loop=$count_dge}}	{{/section}}
																			{{foreach from=$count_dge item=label1 key=sec0}}	
																				<div class="tab-pane {{if {{$sec0+1}} eq '1'}}active{{/if}}" id="dge_CT{{$sec0+1}}" role="tabpanel">
																					<div class="flatPanel panel panel-default ct-panel">
																								<div class="row">
																									<div class="form-group col-md-12 col-sm-12" style="height:100%">
																										<table id="dge_table_ct_{{$sec0+1}}" class="display" style="width:100%">
																											<thead>
																												<tr>
																													<th>Cell Cluster</th>
																													<th>Gene</th>
																													<th>P-value</th>
																													<th>Avg_logFC</th>
																													<th>Pct.1</th>
																													<th>Pct.2</th>
																													<th>Adjusted p-value</th>
																												</tr>
																											</thead>
																										</table>
																									</div>
																										</div></div> </div> {{/foreach}}</div>
																</div>
																<div class="tab-pane fade" id="preview-tab4default"><div class="flatPanel panel panel-default">
																	<div class="panel-body">
																		<div class="col-md-12 col-sm-12">
																			<div class="form-group col-md-6 col-sm-6">
																					<p for="reportsList">Enable imputation: {{$is_imputation}}</p>
																			</div>
																			<div class="form-group col-md-6 col-sm-6">
																				<p for="reportsList">Remove ribosome genes: {{$remove_ribosome}}</p>
																			</div>
																			<div class="form-group col-md-6 col-sm-6">
																				<p>Number of principle components: {{$n_pca}}</p>
																		</div>
																		<div class="form-group col-md-6 col-sm-6">
																					<p>Number of highly variable features: {{$n_variable_features}}</p>
																			</div>
																			<div class="form-group col-md-6 col-sm-6">
																				<p>Cell clustering resolution: {{$resolution_seurat}}</p>
																		</div>
																			<div class="form-group col-md-6 col-sm-6">
																					<p>Enable dual strategy: {{$is_c}}</p>
																			</div>
																			<div class="form-group col-md-6 col-sm-6">
																					<p for="reportsList">Minimum cell number: {{$k_arg}}</p>
																			</div>
																			<div class="form-group col-md-6 col-sm-6">
																					<p>Maximum bicluster number: {{$o_arg}}</p>
																			</div>
																			<div class="form-group col-md-6 col-sm-6">
																					<p>Bicluster overlap rate: {{$f_arg}}</p>
																			</div>
																			<div class="form-group col-md-6 col-sm-6">
																					<p>Cell clustering method: {{$label_use_predict}}</p>
																			</div>
																			<div class="form-group col-md-6 col-sm-6">
																					<p>Upstream promoter region: {{$promoter_arg}}</p>
																			</div>
																			<div class="form-group col-md-6 col-sm-6"> 
																					<p>Email: {{$email_line}}</p>
																			</div>
																			<div class="form-group col-md-6 col-sm-6"> 
																					<p>Uploaded files: </p><p>{{$expfile_name}}</p><p>{{$labelfile_name}}</p><p>{{$gene_module_file_name}}</p>
																			</div>
																	</div>
																</div>
															</div>
														</div>
													</div>
												</div>
													{{/if}}
                        </div>
                    </div>
                    {{/if}}
                </div>
        </div>
    </div>

    <script>
color_array2=["#FFFF00", "#1CE6FF", "#FF34FF", "#FFE119", "#008941", "#006FA6", "#A30059",
"#7A4900", "#0000A6", "#63FFAC", "#B79762", "#004D43", "#8FB0FF", "#997D87",
"#5A0007", "#809693", "#FEFFE6", "#1B4400", "#4FC601", "#3B5DFF", "#4A3B53", "#FF2F80",
"#61615A", "#BA0900", "#6B7900", "#00C2A0", "#FFAA92", "#FF90C9", "#B903AA", "#D16100",
"#DDEFFF", "#000035", "#7B4F4B", "#A1C299", "#300018", "#0AA6D8", "#013349", "#00846F",
"#372101", "#FFB500", "#C2FFED", "#A079BF", "#CC0744", "#C0B9B2", "#C2FF99", "#001E09",
"#00489C", "#6F0062", "#0CBD66", "#EEC3FF", "#456D75", "#B77B68", "#7A87A1", "#788D66",
"#885578", "#0089A3", "#FF8A9A", "#D157A0", "#BEC459", "#456648", "#0086ED", "#886F4C",
"#34362D", "#B4A8BD", "#00A6AA", "#452C2C", "#636375", "#A3C8C9", "#FF913F", "#938A81",
"#575329", "#00FECF", "#B05B6F", "#8CD0FF", "#3B9700", "#04F757", "#C8A1A1", "#1E6E00",
"#7900D7", "#A77500", "#6367A9", "#A05837", "#6B002C", "#772600", "#D790FF", "#9B9700",
"#549E79", "#FFF69F", "#201625", "#CB7E98", "#72418F", "#BC23FF", "#99ADC0", "#3A2465", "#922329",
"#5B4534", "#FDE8DC", "#404E55", "#FAD09F", "#A4E804", "#f58231", "#324E72", "#402334"];

color_array3=["#5A5156","#5A5156","#F6222E","#FE00FA","#16FF32","#3283FE","#FEAF16","#B00068","#1CFFCE","#90AD1C","#2ED9FF","#DEA0FD","#AA0DFE","#F8A19F","#325A9B","#C4451C","#1C8356","#85660D","#B10DA1","#FBE426","#1CBE4F","#FA0087","#FC1CBF","#F7E1A0","#C075A6","#782AB6","#AAF400","#BDCDFF","#822E1C",
"#B5EFB5","#7ED7D1","#1C7F93","#D85FF7","#683B79","#66B0FF","#3B00FB"]
{{section name=clust loop=$silh_trace}}
var trace{{$silh_trace[clust]}} = {
  x: [{{section name=idx loop=$silh_x[{{$silh_trace[clust]}}]}} "{{$silh_x[{{$silh_trace[clust]}}][idx]}}",{{/section}}],
  y: [{{section name=idx loop=$silh_y[{{$silh_trace[clust]}}]}} "{{$silh_y[{{$silh_trace[clust]}}][idx]}}",{{/section}}],
  name: '{{$silh_trace[clust]}}',
  marker:{
		{{if !empty($sankey_nodes)}} 
    	color: [{{section name=idx loop=$silh_y[{{$silh_trace[clust]}}]}} color_array3[36-{{$silh_trace[clust]}}],{{/section}}]
		{{else}}
		color: [{{section name=idx loop=$silh_y[{{$silh_trace[clust]}}]}} color_array3[{{$silh_trace[clust]}}],{{/section}}]
		{{/if}}
  },
  type: 'bar'
};
{{/section}}


var score_data = [{{section name=clust loop=$silh_trace}}trace{{$silh_trace[clust]}},  {{/section}}]

var score_layout = {
	title: "",
	autosize:true,
	barmode: 'group',
		width: $(".panel-body").width()-150,
	font: {
		size: 12
	},
	"titlefont": {
    "size": 16
	},/*
	width: '100%',
	height: 500,*/
	"xaxis": {
	visible:false,
	tickangle: -45,
	responsive: true,
	},
 }
 
var score_config = {
  toImageButtonOptions: {
	title: 'Download plot as a svg',
    format: 'svg', // one of png, svg, jpeg, webp
    filename: 'new_image',
    scale: 1 // Multiply title/legend/axis/canvas sizes by this factor
	},
	autosize: true,
	responsive: true,
  showLink: true,
  displayModeBar: true,
  modeBarButtonsToRemove:['zoom2d', 'pan2d', 'select2d', 'lasso2d', 'zoomIn2d', 'zoomOut2d', 'autoScale2d','hoverClosestCartesian', 'hoverCompareCartesian','hoverClosest3d','toggleHover','hoverClosestGl2d','hoverClosestPie','toggleSpikelines']
};
	if ($('#score_div').length > 0) {
		Plotly.react('score_div', score_data, score_layout, score_config);
	}

    </script>
	
	{{if !empty($sankey_nodes)}} 
	 <script>
		    var sankey_data = {
            type: "sankey",
            orientation: "h",
            node: {
                pad: 10,
                thickness: 30,
                line: {
                    color: "black",
                    width: 2
                },
                label: {{$sankey_nodes}},
                //color: 'RdBu'
				color:[{{section name=clust loop=$silh_trace}} color_array3[36-{{$silh_trace[clust]}}],{{/section}}{{for $clust= 0 to $sankey_nodes_count-1}} color_array3[{{$clust}}+1],{{/for}}]
				//{{$sankey_label_order[$clust]}}
            },
            link: {
                source: {{$sankey_src}},
                target: {{$sankey_target}},
                value:  {{$sankey_value}}
            }
        }
        var sankey_data = [sankey_data]
        var sankey_layout = {
					title: "",
					autosize: true,
					responsive: true,
					width: $(".panel-body").width()-150,
					height: 600,
									font: {
											size: 12
									},
					"titlefont": {
					"size": 16
					},
				}
				if ($('#sankey_div').length > 0) {
					Plotly.react('sankey_div', sankey_data, sankey_layout,score_config)
				}
		 </script>
		{{/if}}
<div class="push"></div></main>
{{/block}}