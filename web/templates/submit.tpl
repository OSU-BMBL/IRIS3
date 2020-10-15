{{extends file="base.tpl"}} {{block name="extra_style"}} form div.fieldWrapper label { min-width: 5%; } {{/block}} {{block name="extra_js"}} {{/block}} {{block name="main"}}
	<script src="assets/js/bootstrap-select.min.js"></script>
<script>
function use_fast_version(item) {
  $('#f_arg_id').selectpicker('val', '0.5')
  $('#o_arg_id').selectpicker('val', '100')
  $('#k_arg_id').selectpicker('val', '20')
  $('#promoter_arg_id').selectpicker('val', '500')
  $('#is_imputation').prop('checked', false)
  $('#is_c').prop('checked', false)
}
function use_accurate_version(item) {
  $('#f_arg_id').selectpicker('val', '0.7')
  $('#o_arg_id').selectpicker('val', '500')
  $('#k_arg_id').selectpicker('val', '20')
  $('#promoter_arg_id').selectpicker('val', '1000')
}
function addPreviewTable(response, metadata = true, type) {
  if (response['data'] > 10 && type == 'exp') {
    $('#preview_' + type).append(
      $('<label>', {
        class: 'px-2 py-1'
      }).html(
        '<span class="bold highlight">Note: Your dataset is uploaded, since the file is larger than 2000MB (' +
          (response['data'][0] / 1000000).toFixed(2) +
          'MB), preview has been disabled. </span></label>'
      )
    )
  }

  // Define table
  var $table = $('<table>', {
    class: 'table-striped w-100'
  })
    .append(
      $('<thead>').append(
        $('<tr>', {
          class:
            ' very-small text-center border-grey border-left-0 border-right-0'
        })
      )
    )
    .append($('<tbody>'))
  // Add headers
  //label = metadata ? 'Gene' : 'Cell Label'

  upload_type = response['type'][0]
  if (type == 'exp' && upload_type == 'text') {
    label = 'Gene'
    $table.find('tr').append(
      $('<th>', {
        class: 'px-2 py-1 text-center'
      }).html(label)
    )
    $.each(response['columns'][0], function(i, col) {
      $table.find('tr').append(
        $('<th>', {
          class: 'px-2 py-1 text-center'
        }).html(col)
      )
    })
  } else if (type == 'label') {
    label = 'Cell label'
    $table.find('tr').append(
      $('<th>', {
        class: 'px-2 py-1 text-center'
      }).html(label)
    )
    $.each(response['columns'][0], function(i, col) {
      $table.find('tr').append(
        $('<th>', {
          class: 'px-2 py-1 text-center'
        }).html(col)
      )
    })
  } else if (type == 'module') {
    label = 'Module'
  }

  // Get row number
  n = metadata ? 6 : response['index'].length
  
  switch (upload_type) {
    case 'text':
      try {
        // Add rows
        for (i = 0; i < n; i++) {
          var $tr = $('<tr>').append(
            $('<td>', {
              class: 'bold text-center px-2 py-0'
            }).html(response['index'][i])
          )
          $.each(response['data'][i], function(i, val) {
            $tr.append(
              $('<td>', {
                class: 'light text-center tiny'
              }).html(val)
            )
          })
          $table.find('tbody').append($tr)
        } // Add
        $('#loader_' + type).addClass('d-none')
        $('#preview_' + type).append($table)
        document.getElementById('is_load_' + type).value = 1
      } catch (err) {
        $('#preview_' + type).append(
          $('<label>', {
            class: 'px-2 py-0'
          }).html(
            '<span class="highlight">ERROR: ' +
              err.message +
              ', please check your upload data format.</span></label>'
          )
        )
      }
     var check_cell_name_start_with_number = false
        for (var i = 0; i < response['columns'][0].length; i += 1) {
          // Use the index i here
          if ('0123456789'.indexOf(response['columns'][0][i].charAt(0)) !== -1) {
            check_cell_name_start_with_number = true
          }
        }

      var hasNegativeValue = false 
      for (var i_negative = 0; i_negative < response['data'].length; i_negative += 1) {
        // Use the index i here
        for(var j_negative = 0; j_negative < response['data'][i_negative].length; j_negative += 1) {
            if (Math.sign(parseFloat(response['data'][i_negative][j_negative])) === -1) {
              hasNegativeValue = true
          }
        }
      }
      
      if (response['cell_num'][0] < 100 && type == 'exp') {
        $('#preview_' + type).append(
          $('<div>', {
            class: 'recommend_small_k px-2 py-0'
          }).html(
            '<span class="bold highlight">NOTE: Your dataset has (' +
              response['cell_num'][0] +
              ') cells. It is recommended to set a small "Minimum cell number" in the advanced options section, e.g. Minimum cell number=5 for about 100 cells, otherwise errors may occur. </span></div>'
          )
        )
      }
      
      
      
      if (
        check_cell_name_start_with_number &&
        type == 'exp'
      ) {
        $('#preview_' + type).append(
          $('<div>', {
            class: 'rename_cell px-2 py-0'
          }).html(
            '<span class="bold highlight">NOTE: Some of the cell names in your dataset start with numeric value, IRIS3 will try to rename them in data pre-processing.  </span></div><br/>'
          )
        )
      }
      
      if (
        hasNegativeValue && 
        type == 'exp'
      ) {
        $('#preview_' + type).remove('.rename_cell')
        $('#preview_' + type).remove('.recommend_small_k')
        $('#preview_' + type).append(
          $('<div>', {
            class: 'px-2 py-0'
          }).html(
            '<span class="bold highlight" style="color:red">ERROR: Your dataset contains negative value, Seurat does not support this type of Single-Cell RNA-seq data, thus the IRIS3 submit button has been disabled. </span></div><div class="row"></div>'
          )
        )
        $('#hint_select_species').html(
        '<span class="bold highlight" style="color:red">ERROR: Your dataset contains negative value, Seurat does not support this type of Single-Cell RNA-seq data, thus the IRIS3 submit button has been disabled. Refresh the page to re-submit your dataset.</span>')
         $('#submit_btn').attr('disabled', true)
      }

      break
    case 'hdf':
      $('#preview_' + type).append(
        $('<div>', {
          class: 'px-2 py-0'
        }).html(
          '<br><span class="bold highlight">NOTE: Check advanced options for 10X parameter adjustment. ' +
            '</span></div>'
        )
      )
      break
    default:
      $('#preview_' + type).append(
        $('<div>', {
          class: 'px-2 py-0'
        }).html(
          '<br><span class="bold highlight">NOTE: The preview function for your upload dataset has been disabled. ' +
            '</span></div>'
        )
      )
      break
  }
  $('#preview_' + type).append(
    $('<div>', {
      class: 'px-2 py-0'
    }).html(
      '<span class="bold highlight">NOTE: Your upload file type: ' +
        upload_type +
        '</span></label><br/><span class="bold highlight">NOTE: IRIS3 does not allow submitting jobs simultaneously while multiple tabs/pages opened, please submit your job one at a time, otherwise conflicts may occur.</span>'
    )
  )
}

var addTable = function(dataset, type) {
  // modified function from biojupies/upload/table
  $('#expression').val(JSON.stringify(dataset))
  // Toggle Interfaces
  //$('button[form="upload-expression-form"]').prop('disabled', false);
  //$('button[form="upload-expression-form"]').toggleClass('black white bg-white bg-blue');
  if (dataset['type'][0] == 'text') {
    $('#dropzone_' + type).hide()
    $('#formats').hide()
    $('#drop_exp').hide()
    $('#drop_label').hide()
  }
  addPreviewTable(dataset, true, type)
  if (dataset['type'][0] == 'text') {
    $('#intro_' + type).append(
      $('<label>', {
        class: 'px-2 py-1'
      }).html(
        'Your uploaded gene expression file contains <span class="highlight">' +
          dataset['cell_num'][1] +
          ' cells</span> and <span class="highlight">' +
          dataset['gene_num'][0] +
          ' genes</span>. Check that the preview is correct, select the species then click submit button or upload additional files in the advanced options. Please refresh the page if you would like to re-submit your dataset.</label>'
      )
    )
  } else if (dataset['type'][0] == 'hdf') {
    $('#intro_' + type).append(
      $('<label>', {
        class: 'px-2 py-1'
      }).html(
        'You uploaded <span class="highlight">HDF format </span>gene expression file, select the species then click submit button or upload additional files in the advanced options. Refresh the page to re-submit your dataset.</label>'
      )
    )
  }
}
var exp_file_status = 0
$(document).ready(function() {
  $('.selectpicker').selectpicker()
  $('#tooltip1').tooltip()
  $('[data-toggle="tooltip"]').tooltip({
    placement: 'top'
  })
  $('.dropdown-toggle').dropdown()
  // clear uploaded files on refresh
  $.ajax({
    url: 'upload.php',
    type: 'POST',
    data: {
      filename: 'clear'
    },
    dataType: 'json',
    success: function(response) {},
    error: function(e) {
      console.log(e.message)
    }
  })
  dz_exp = $('#dropzone_exp').dropzone({
    dictDefaultMessage:
      'Drag or click upload your gene expression matrix, supported format: <br>1. Gene expression matrix (txt, tsv, csv). <br>2. HDF5 feature barcode matrix (hdf5).<br>3. Gene-barcode matrices (3 gzip files in your 10X output directory). <br>Note: You may upload compressed files (gzip).',
    acceptedFiles: '.txt,.csv,.tsv,.gz,.zip,.h5,.hdf5,.zip',
    url: 'upload.php',
    maxFiles: 3,
    parallelUploads: 3,
    maxFilesize: 5000, //5GB max upload file size
    maxfilesexceeded: function(file) {
      this.removeFile(this.files[0])
      this.addFile(file)
    },
    timeout: 1800000,
    sending: function(file, xhr, formData) {
      formData.append('filetype', 'dropzone_exp')
      $('#hint_select_species').html(
        '<span class="bold highlight">NOTE: If submit button is still disabled after you uploaded dataset, try to deselect then select species again. </span>'
      )
    },
    success: function(file, response) {
      if ($('#species_arg').selectpicker('val')) {
        $('#submit_btn').attr('disabled', false)
      }
      exp_file_status = 1
      response = JSON.parse(response)
      if (this.getAcceptedFiles().length <= 1) {
        addTable(response, 'exp')
      }
    }
  })

  $('div#dropzone_label').dropzone({
    dictDefaultMessage:
      'Drag or click to upload your cell label file. <br> Accepted files: .txt,.csv,.tsv',
    acceptedFiles: '.txt,.csv,.tsv,.xls,.xlsx',
    url: 'upload.php',
    maxFiles: 1,
    maxFilesize: 50,
    timeout: 1800000,
    maxfilesexceeded: function(file) {
      this.removeAllFiles()
      this.addFile(file)
    },
    sending: function(file, xhr, formData) {
      formData.append('filetype', 'dropzone_label')
    },
    success: function(file, response) {
      response = JSON.parse(response)
      //console.log(response);
      addTable(response, 'label')
    }
  })

  $('div#dropzone_gene_module').dropzone({
    dictDefaultMessage:
      'Drag or click to upload your gene module file. <br> Accepted files: .txt,.csv,.tsv',
    acceptedFiles: '.txt,.csv,.tsv,.xls,.xlsx',
    url: 'upload.php',
    maxFiles: 1,
    maxFilesize: 50,
    timeout: 300000,
    maxfilesexceeded: function(file) {
      this.removeAllFiles()
      this.addFile(file)
    },
    sending: function(file, xhr, formData) {
      formData.append('filetype', 'dropzone_gene_module')
    },
    success: function(file, response) {
      $('#enable_gene_module').attr('disabled', false)
      response = JSON.parse(response)
      //console.log(response);
      addTable(response, 'gene_module')
    }
  })

  $('.dz-message').css({
    'font-size': '18px'
  })
  // Load Example expression file
  $('#load_exp').click(function(evt) {
    exp_file_status = 1
    $('#submit_btn').attr('disabled', false)
    $('#loader_exp').html(
      $('<div>', {
        class: 'text-center medium regular py-5 border-grey rounded',
        style:
          'background-size: 100% 100%;height:150px; background-size: 100% 100%;margin:10px 0 0 0;border:1px solid #c9c9c9;border-radius:.25rem!important'
      }).html(
        $('<div>', {
          class: 'dz-default dz-message',
          style: 'margin:2em 0;font-weight:600;color:#B47157'
        }).html(
          '<span class="glyphicon glyphicon-ok" aria-hidden="true"></span>Example gene expression file loaded (Zeisel et al, 2015)'
        )
      )
    )
    $('#dropzone_exp').hide()
    $('#loader_label').html(
      $('<div>', {
        class: 'text-center medium regular py-5 border-grey rounded',
        style:
          'background-image: url(assets/img/expression_label.jpg); background-size: 100% 100%;height:150px; background-size: 100% 100%;margin:10px 0 0 0;border:1px solid #c9c9c9;border-radius:.25rem!important'
      }).html(
        $('<div>', {
          class: 'dz-default dz-message',
          style: 'margin:2em 0;font-weight:600;color:#B47157'
        }).html(
          '<span class="glyphicon glyphicon-ok" aria-hidden="true"></span>Example cell label file loaded (Zeisel et al, 2015)'
        )
      )
    )
    $('#dropzone_label').hide()
    $("#species_arg option[value='Mouse']").prop('selected', true)
    $('.selectpicker').selectpicker('refresh')
    // load example data
    $.ajax({
      url: 'upload.php',
      type: 'POST',
      data: {
        filename: 'expression'
      },
      dataType: 'json',
      success: function(response) {},
      error: function(e) {
        //console.log(e.message)
      }
    })
  })
  // load example cell label
  $('#load_label').click(function(evt) {
    exp_file_status = 1
    $('#submit_btn').attr('disabled', false)
    $('#loader_exp').html(
      $('<div>', {
        class: 'text-center medium regular py-5 border-grey rounded',
        style:
          'background-image: url(assets/img/expression_table.jpg); background-size: 100% 100%;height:150px; background-size: 100% 100%;margin:10px 0 0 0;border:1px solid #c9c9c9;border-radius:.25rem!important'
      }).html(
        $('<div>', {
          class: 'dz-default dz-message',
          style: 'margin:2em 0;font-weight:600;color:#B47157'
        }).html(
          '<span class="glyphicon glyphicon-ok" aria-hidden="true"></span>Example gene expression file loaded'
        )
      )
    )
    $('#dropzone_exp').hide()
    $('#loader_label').html(
      $('<div>', {
        class: 'text-center medium regular py-5 border-grey rounded',
        style:
          'background-image: url(assets/img/expression_label.jpg); background-size: 100% 100%;height:150px; background-size: 100% 100%;margin:10px 0 0 0;border:1px solid #c9c9c9;border-radius:.25rem!important'
      }).html(
        $('<div>', {
          class: 'dz-default dz-message',
          style: 'margin:2em 0;font-weight:600;color:#B47157'
        }).html(
          '<span class="glyphicon glyphicon-ok" aria-hidden="true"></span>Example cell label file loaded'
        )
      )
    )
    $('#dropzone_label').hide()
    $("#species_arg option[value='Human']").prop('selected', true)
    $('.selectpicker').selectpicker('refresh')
    // AJAX upload example
    $.ajax({
      url: 'upload.php',
      type: 'POST',
      data: {
        filename: 'label'
      },
      dataType: 'json',
      success: function(response) {},
      error: function(e) {
        console.log(e.message)
      }
    })
  })

  // load example gene module
  /*$('#load_gene_module').click(function(evt) {
	$('#submit_btn').attr("disabled", false);
	$('#enable_labelfile').attr("disabled", false);
	$('#loader_exp').html($('<div>', {'class': 'text-center medium regular py-5 border-grey rounded', 'style':"background-image: url(assets/img/expression_table.jpg); background-size: 100% 100%;height:150px; background-size: 100% 100%;margin:10px 0 0 0;border:1px solid #c9c9c9;border-radius:.25rem!important"}).html($('<div>', {'class': 'dz-default dz-message','style':'margin:2em 0;font-weight:600;font-size:2em;color:#B47157'}).html('<span class="glyphicon glyphicon-ok" aria-hidden="true"></span>Example gene expression file loaded')));
	$('#dropzone_exp').hide();
	$('#loader_label').html($('<div>', {'class': 'text-center medium regular py-5 border-grey rounded', 'style':"background-image: url(assets/img/expression_label.jpg); background-size: 100% 100%;height:150px; background-size: 100% 100%;margin:10px 0 0 0;border:1px solid #c9c9c9;border-radius:.25rem!important"}).html($('<div>', {'class': 'dz-default dz-message','style':'margin:2em 0;font-weight:600;font-size:1.5em;color:#B47157'}).html('<span class="glyphicon glyphicon-ok" aria-hidden="true"></span>Example cell label file loaded')));
	$('#dropzone_label').hide();

	$.ajax({
		url: "upload.php",
		type: 'POST',
		data: {'filename': 'gene_module'},
		dataType: 'json',
		success: function(response) {
		},
        error: function(e){
            console.log(e.message);
        }
	})
	});*/
  
  $('select#species_arg').on('change', function(value) {
    var This = $(this)
    var selectedD = $(this).val()
    

    if (selectedD && exp_file_status) {
      if($('#hint_select_species').children().attr('style') !== 'color:red'){
        $('#submit_btn').attr('disabled', false)
      }
    } else {
      $('#submit_btn').attr('disabled', true)
    }
  })
})
</script>
<main role="main" class="container" style="min-height: calc(100vh - 182px);">
	<hr>
	<!--<div class="starter-template">-->
  <form method="POST" action="{{$URL}}" encType="multipart/form-data" id="needs-validation">
    <div class="text-center"> <a href="submit.php"><button type="button" class="btn btn-submit  btn-lg">Single scRNA-seq dataset</button></a>
      <a href="submit_integration.php"><button type="button" class="btn  btn-light btn-lg">Multiple scRNA-seq dataset integration</button></a>
      <a href="submit_atac.php"><button type="button" class="btn btn-light btn-lg">scRNA-seq & scATAC-seq integration</button></a> </div>

		<h2 class="text-center">Job Submission</h2>
		<div class="form-group row">
			<div class="form-check col-sm-12 ">
				<label class="form-check-label" for="expfile">Upload gene expression file: <span class="glyphicon glyphicon-question-sign" data-toggle="tooltip" data-original-title="A gene expression file with genes as rows and cells as columns. Users can provide normalized or non-normalized file (Read counts) for the submission. Accept txt, csv, and tsv format for text gene expression matrix, 10X hdf5 or gene-barcode matrices. "> </span>
				</label>
			</div>
			<div class="form-check col-sm-2  ">
				<div class="dropdown"  id="drop_exp">
					<button class="btn btn-default dropdown-toggle" type="button" id="dropdownMenu1" data-toggle="dropdown" aria-haspopup="true" aria-expanded="true" style="border:1px solid #c9c9c9;border-radius:.25rem!important">Example <span class="caret"></span>
					</button>
					<ul class="dropdown-menu" aria-labelledby="dropdownMenu1">
						<li><a id="load_exp" class="dropdown-item" href="#">Load example (Zeisel et al, 2015)</a>
						</li>
						<!--<li><a class="dropdown-item" href="storage/Yan_2013_expression.csv" >Download (Yan et al, 2013) gene expression matrix (Yan et al, 2013)</a>
						</li>
						<li><a class="dropdown-item" href="/iris3/storage/Yan_2013_label.csv" download>Download (Yan et al, 2013) cell label file)</a></li>
						<li><a class="dropdown-item" href="/iris3/storage/Yan_2013_example_gene_module.csv">Download example gene module file</a></li>
						<li><a class="dropdown-item" href="/iris3/storage/Zeisel_index_label.csv" download>Download (Zeisel et al, 2015) cell label file</a></li>-->
						<li><a class="dropdown-item" href="storage/Zeisel_expression.csv" >Download (Zeisel et al, 2015) gene expression matrix  (Example output mouse dataset)</a>
						</li>
						<li><a class="dropdown-item" href="storage/5k_pbmc_protein_v3_filtered_feature_bc_matrix.h5" >Download example HDF5 feature barcode matrix (10X 5K Human PMBCs)</a>
						</li>
						<li><a class="dropdown-item" href="storage/genes.tsv.gz" >Download example gene-barcode matrices (10X 2700 Human PMBCs) (genes.tsv.gz)</a>
						</li>
						<li><a class="dropdown-item" href="storage/barcodes.tsv.gz" >Download example gene-barcode matrices (10X 2700 Human PMBCs) (barcodes.tsv.gz)</a>
						</li>
						<li><a class="dropdown-item" href="storage/matrix.mtx.gz" >Download example gene-barcode matrices (10X 2700 Human PMBCs) (matrix.mtx.gz)</a>
						</li>
					</ul>
				</div>
			</div>
			<!--<div class="form-check col-sm-1  ">
				<div class="dropdown">
					<button class="btn btn-default dropdown-toggle" type="button" id="dropdownMenu1" data-toggle="dropdown" aria-haspopup="true" aria-expanded="true" style="border:1px solid #c9c9c9;border-radius:.25rem!important">Example (10x) <span class="caret"></span>
					</button>
					<ul class="dropdown-menu" aria-labelledby="dropdownMenu1">
						<li><a id="load_exp" class="dropdown-item" href="#">Load example file</a>
						</li>
						<li><a class="dropdown-item" href="storage/Yan_2013_expression.csv" >Download example gene expression file</a>
						</li>
					</ul>
				</div>
			</div>-->
			<div class="col-sm-12">
				<div id="dropzone_exp" class="dropzone border-grey rounded dz-clickable" style="background-size: 100% 100%;margin:10px 0 0 0;border:2px dashed #c9c9c9;border-radius:.25rem!important"></div>
			<div id="loader_exp"></div>
			<!--<div id="hint_upload" style="font-weight: 200;">Note: We accept gene symbols as row identifiers, automated identifier conversion currently in development.</div>-->
			<div id="preview_exp"></div>
			<div id="intro_exp" class="mt-2"></div>
			</div>

		</div>
		<div class="form-group row">
		<div class="form-check col-sm-6 ">
		<label class="form-check-label" for="species_select">Species:
		 <span class="glyphicon glyphicon-question-sign" data-toggle="tooltip" data-original-title="Specifies the species belonging to your gene expression matrix."> </span> 
				</label>
		<select class="selectpicker" id="species_arg" name="species_arg[]" title="Select species...">
  <option value="Human">Human (hg38)</option>
  <option value="Mouse">Mouse (mm10)</option>
</select>
</div>
		<br/>
		
			
		</div>
		
		<hr>
		<div class="bs-example2">
			<div class="panel-group" id="accordion2">
				<div class="panel panel-default">
					<div class="panel-collapse-heading"> 
						<h2 class="panel-title">
                     <a data-toggle="collapse" data-parent="#accordion2" href="#collapseThree2">Advanced options</a>
                  </h4>
					</div>
						
					<div id="collapseThree2" class="panel-collapse collapse">
						<div class="panel-body">
							<h4 class="font-italic text-left">DrImpute:</h4>
                 <div class="form-group row">
									<div class="col-md-4">
										<label class="form-check-label" for="is_imputation">Enable imputation in pre-processing.
							 <span class="glyphicon glyphicon-question-sign" data-container="body" data-toggle="tooltip" data-original-title="Enable imputation step using DrImpute with all default parameters in the pre-processing step. Default: disabled."> </span> 
						    	</label>
									</div>
									<div class="col-md-4">
										<select  id="is_imputation" class="selectpicker" name="is_imputation" data-width="auto">
											<option>Yes</option>
											<option data-subtext="Default" selected="selected">No</option>
										</select>
									</div>
                </div>
              <h4 class="font-italic text-left">Seurat:</h4>
			  <div class="form-group row">
									<div class="col-md-4">
										<label class="form-check-label" for="remove_ribosome">Remove ribosome genes.
							 <span class="glyphicon glyphicon-question-sign" data-container="body" data-toggle="tooltip" data-original-title="Determine whether you want to remove ribosome genes in pre-processing step. Default: disabled."> </span> 
						    	</label>
									</div>
									<div class="col-md-4">
										<select  id="remove_ribosome" class="selectpicker" name="remove_ribosome" data-width="auto">
											<option>Yes</option>
											<option data-subtext="Default" selected="selected">No</option>
										</select>
									</div>
                </div>
							<div class="form-group row">
									<div class="col-md-4">
										<label for="ex3">Number of principal components used in downstream analyses. <span class="glyphicon glyphicon-question-sign" data-toggle="tooltip" data-original-title="Determine the ‘dimensionality’ of the dataset, the top principal components represent a robust compression of the dataset. Default: 10."> </span>
										</label>
									</div>
									<div class="col-md-4">
										<select  id="n_pca_id" class="selectpicker" name="n_pca" data-width="auto">
                      <option>5</option>
                      <option>6</option>
                      <option>7</option>
                      <option>8</option>
											<option>9</option>
                      <option data-subtext="Default" selected="selected">10</option>
                      <option>11</option>
											<option>12</option>
											<option>13</option>
                      <option>14</option>
                      <option>15</option>
											<option>16</option>
											<option>17</option>
											<option>18</option>
                      <option>19</option>
                      <option>20</option>
                      <option>21</option>
                      <option>22</option>
                      <option>23</option>
                      <option>24</option>
                      <option>25</option>
										</select>
									</div>
								</div>
								<div class="form-group row">
									<div class="col-md-4">
										<label for="ex3">Number of highly variable features. <span class="glyphicon glyphicon-question-sign" data-toggle="tooltip" data-original-title="The subset of features that exhibit high cell-to-cell variation in the dataset, focusing on these genes in downstream analysis helps to highlight biological signal in single-cell datasets. Default: 5000."> </span>
										</label>
									</div>
									<div class="col-md-4">
										<select  id="n_variable_features_id" class="selectpicker" name="n_variable_features" data-width="auto">
											<option>1000</option>
											<option>2000</option>
											<option>3000</option>
											<option>4000</option>
											<option data-subtext="Default" selected="selected">5000</option>
											<option>6000</option>
											<option>7000</option>
											<option>8000</option>
											<option>9000</option>
                      <option>10000</option>
                      <option>all</option>
										</select>
									</div>
								</div>
                <div class="form-group row">
									<div class="col-md-4">
										<label for="ex3">Cell clustering resolution.<span class="glyphicon glyphicon-question-sign" data-toggle="tooltip" data-original-title="Resolution for clustering in Seurat (form 0-1). Larger number will generate more clusters and smaller number will generate less clusters. Default: 0.8."> </span>
										</label>
									</div>
									<div class="col-md-4">
										<select  id="resolution_seurat_id" class="selectpicker" name="resolution_seurat" data-width="auto">
											<option>0.1</option>
											<option>0.2</option>
                      <option>0.3</option>
											<option>0.4</option>
                      <option>0.5</option>
											<option>0.6</option>
                      <option>0.7</option>
											<option data-subtext="Default" selected="selected">0.8</option>
                      <option>0.9</option>
											<option>1.0</option>
                      <option>1.1</option>
											<option>1.2</option>
                      <option>1.3</option>
											<option>1.4</option>
                      <option>1.5</option>
											<option>1.6</option>
											<option>1.7</option>
											<option>1.8</option>
											<option>1.9</option>
											<option>2.0</option>
										</select>
									</div>
								</div>
							<div class="form-group">
                <h4 class="font-italic text-left">QUBIC2:</h4>
            <div class="form-group row">
              <div class="col-md-4">
                <!--<input class="form-check-input" type="checkbox" name="is_c" id="is_c" value="1">-->
                <label class="form-check-label" for="is_c">Enable dual strategy in bi-clustering.
                  <span class="glyphicon glyphicon-question-sign" data-toggle="tooltip" data-original-title="Enable dual strategy for QUBIC2 biclustering optimization. Time consuming. Not recommended for 10X data. Default: disabled."> </span> 
                 </label>
              </div>
              <div class="col-md-4">
                <select  id="is_c" class="selectpicker" name="is_c" data-width="auto">
                  <option>Yes</option>
                  <option data-subtext="Default" selected="selected">No</option>
                </select>
              </div>
            </div>
								<div class="row">
									<div class="col-md-4">
										<label for="ex1">Bicluster overlap rate. <span class="glyphicon glyphicon-question-sign" data-toggle="tooltip" data-original-title="Controls the level of overlaps between to-be-identified biclusters. A larger value means more overlap on gene modules. Default is 0.7."> </span> 
										</label>
									</div>
									<div class="col-md-4">
										<select  id="f_arg_id" class="selectpicker" name="f_arg" data-width="auto">
											<option>0.5</option>
											<option>0.6</option>
											<option data-subtext="Default" selected="selected">0.7</option>
											<option>0.8</option>
											<option>0.9</option>
											<option>1.0</option>
										</select>
									</div>
								</div>
								<br>
								<div class="row">
									<div class="col-md-4">
										<label for="ex3">Maximum bicluster number. <span class="glyphicon glyphicon-question-sign" data-toggle="tooltip" data-original-title="Max number of biclusters to output. Note: the output number will affect the prediction of bicluster, not merely a cutoff, and the output biclusters may be less than this number. A smaller value (e.g 100) helps decrease running time. Default is 500. "> </span>
										</label>
									</div>
									<div class="col-md-4">
										<select  id="o_arg_id" class="selectpicker" name="o_arg" data-width="auto">
											<option>20</option>
											<option>50</option>
											<option>100</option>
											<option>200</option>
											<option data-subtext="Default" selected="selected">500</option>
											<option>1000</option>
										</select>
									</div>
								</div>
								<br>
								<div class="row">
									<div class="col-md-4">
										<label for="ex2">Minimum cell number. <span class="glyphicon glyphicon-question-sign" data-toggle="tooltip" data-original-title="Minimum column width of the bicluster block. Default is 20."> </span>
										</label>
									</div>
									<div class="col-md-4">
										<select id="k_arg_id" class="selectpicker" name="k_arg" data-width="auto">
											<option>3</option>
											<option>5</option>
                      <option>6</option>
											<option>7</option>
                      <option>8</option>
                      <option>9</option>
											<option>10</option>
											<option>15</option>
											<option data-subtext="Default" selected="selected">20</option>
											<option>25</option>
                      <option>30</option>
											<option>40</option>
											<option>50</option>
											<option>60</option>
											<option>70</option>
											<option>80</option>
											<option>90</option>
											<option>100</option>
										</select>
									</div>
								</div>
							
								<br>
								<div class="row">
									<div class="col-md-4">
										<label for="ex2">Discretization level. <span class="glyphicon glyphicon-question-sign" data-toggle="tooltip" data-original-title="discretization parameter. Default is 0.06."> </span>
										</label>
									</div>
									<div class="col-md-4">
										<select id="q_arg_id" class="selectpicker" name="q_arg" data-width="auto">
											
                      <option>0.03</option>
                      <option>0.04</option>
											<option>0.05</option>
											<option data-subtext="Default" selected="selected">0.06</option>
											<option>0.07</option>
											<option>0.08</option>
											<option>0.09</option>
										</select>
									</div>
								</div><br>
								<div class="row">
									<div class="col-md-4">
										<label for="ex2">Consistency level. <span class="glyphicon glyphicon-question-sign" data-toggle="tooltip" data-original-title="Consistency parameter. Default is 1."> </span>
										</label>
									</div>
									<div class="col-md-4">
										<select id="c_arg_id" class="selectpicker" name="c_arg" data-width="auto">
											<option>0.9</option>
											<option>0.95</option>
                      <option data-subtext="Default" selected="selected">1.0</option>
											
										</select>
									</div>
								</div>
							</div>
							<h4 class="font-italic text-left">DMINDA2 & MEME:</h4>
							<div class="form-group  row">
								<div class="col-md-4">
									<label for="ex2">Motif finding upstream promoter region.
									 <span class="glyphicon glyphicon-question-sign" data-toggle="tooltip" data-original-title="The upstream promoter region is open to users to decide the region for motif finding.  Wider range may cause require longer computational time. Default: 1000 bp."> </span> 
									</label>
									
								</div>
								<div class="col-md-4">
								<select id="promoter_arg_id" class="selectpicker" name="promoter_arg" data-width="auto">
										<option>250</option>
										<option>500</option>
										<option>750</option>
										<option data-subtext="Default" selected="selected">1000</option>
										<option>2000</option>
									</select>
								</div>
              </div>
              <hr/>
							<div class="form-group row">
                <div class="col-md-12">
                <label for="ex3">Not sure which parameters to choose? Check our <a href="https://bmbl.bmi.osumc.edu/iris3/tutorial.php#2submission" target="_blank">tutorial</a>.
                </label>
							</div>
						  <div class="form-check col-sm-12 ">
							<button type="button" id="fast_version_btn" class="btn btn-default extra-button" data-toggle="collapse" onclick="use_fast_version(this);" >Fast version</button><span style="margin-left:5px;margin-right:50px" class="glyphicon glyphicon-question-sign" data-container="body" data-toggle="tooltip" data-original-title=" This option uses  fast version. This sets f=0.5, k=20, o=100, promoter region=500 bp. This runs faster but generage less regulons."> </span> 
						
						
							<button type="button" id="fast_version_btn" class="btn btn-default extra-button" data-toggle="collapse" onclick="use_accurate_version(this);">Default version</button><span style="margin-left:5px" class="glyphicon glyphicon-question-sign" data-container="body" data-toggle="tooltip" data-original-title="(Default)This option uses  parameters in our publications. This sets f=0.7, k=20, o=500, and promoter region=1000. This runs slower but genreate more regulons."> </span> 
						</div>
					</div>
							<hr/>
							<h4 class="font-italic text-left">Optional choices</h4>
							<label class="form-check-label" for="is_imputation">Upload cell label (Labels should be at least two factors):
							 <span class="glyphicon glyphicon-question-sign" data-toggle="tooltip" data-original-title="Provide cell labels for regulon identification (Cell label should be at least two factors). This file contains two columns: cell names and cell labels. Regulons will be predicted based on the provided cell labels. "> </span>
							</label>
							
							<div id="upload_label">
									<div class="form-group row">
										<div class="col-sm-4">
											<div class="dropdown"  id="drop_label">
												<button class="btn btn-default dropdown-toggle" type="button" id="dropdownMenu1" data-toggle="dropdown" aria-haspopup="true" aria-expanded="true" style="border:1px solid #c9c9c9;border-radius:.25rem!important">Example <span class="caret"></span>
												</button>
												<ul class="dropdown-menu" aria-labelledby="dropdownMenu1">
													<!--<li><a id="load_label" class="dropdown-item" href="#dropzone_label">Load example file</a>
													</li>-->
													<!--<li><a class="dropdown-item" href="/iris3/storage/Yan_2013_label.csv" download>Download cell label file (Yan et al, 2013)</a>
													</li>-->
													<li><a class="dropdown-item" href="/iris3/storage/Zeisel_index_label.csv" download>Download cell label file (Zeisel et al, 2015)</a>
													</li>
												</ul>
											</div>
											<div id="dropzone_label" class="dropzone border-grey rounded dz-clickable" style="background-image: url(assets/img/expression_label.jpg); background-size: 100% 100%;margin:0;border:1px solid #c9c9c9;border-radius:.25rem!important"></div>
											<div id="loader_label"></div>
									<div id="preview_label"></div>
										</div>
									</div>
							</div>
							<label class="form-check-label" for="is_imputation">Upload gene module:
							 <span class="glyphicon glyphicon-question-sign" data-toggle="tooltip" data-original-title="Upload a gene module file for additional analysis. The uploaded file can includes single/multiple columns, and each column represents a gene module."> </span> 
							</label>
							
			
							<div id="upload_gene_module">
									<div class="form-group row">
										<div class="col-sm-4">
											<div class="dropdown" id="drop_gene_module">
												<button class="btn btn-default dropdown-toggle" type="button" id="dropdownMenu1" data-toggle="dropdown" aria-haspopup="true" aria-expanded="true" style="border:1px solid #c9c9c9;border-radius:.25rem!important">Example <span class="caret"></span>
												</button>
												<ul class="dropdown-menu" aria-labelledby="dropdownMenu1">
													<!--<li><a id="load_gene_module" class="dropdown-item" href="#dropzone_label">Load example file</a>
													</li>-->
													<li><a class="dropdown-item" href="/iris3/storage/example_gene_module.csv" download>Download example gene module file</a>
													</li>
												</ul>
											</div>
											<div id="dropzone_gene_module" class="dropzone border-grey rounded dz-clickable" style="background-image: url(assets/img/gene_module.png); background-size: 100% 100%;margin:0;border:1px solid #c9c9c9;border-radius:.25rem!important"></div>
														<div id="loader_gene_module"></div>
			<div id="preview_gene_module"></div>
										</div>
									</div>
							</div>
							
							
						</div>
					</div>
				</div>
			</div>
		</div>
		<!--<div class="form-check col-sm-12 ">
				<input class="form-check-input" type="checkbox" name="allowstorage" id="allowstorage" value="1">
				<label class="form-check-label" for="allowstorage">Allow permanent storage in our database <span class="glyphicon glyphicon-question-sign" data-toggle="tooltip" data-original-title="By checking this option, you allow us to store your data in iris3 database (both submitted and results) for the future database construction. Be cautious if your data have not been published."> </span>
				</label>
			</div>-->
		<div id="emailfd" class="section" style="position:relative;top:10px;"><p>&nbsp;&nbsp;Optional: The running time usually takes a few hours, and can be more than 10 hours if there are more than 5000 cells in your data. Hence, we strongly recommend you to leave your email below, and you will be notified by email when the job is done.</p>
			<div class="bootstrap-iso" style="margin: 5px;">&nbsp; <strong>E-mail</strong>&nbsp;:
				<input name="email" type="text" id="email" size="60" style="position:relative;left:10px; width : 30%;" pattern="[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,3}$" />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</div>
		</div>
		<hr>
		<div class="form-group">
			<button type="submit" id="submit_btn" disabled="true" class="btn btn-submit" name="submit" value="submit">Submit</button>
			<input type="hidden" id="is_load_exp" name="is_load_exp" value="0">
			<input type="hidden" id="is_load_label" name="is_load_label" value="0">
			<input type="hidden" id="is_load_gene_module" name="is_load_gene_module" value="0">
			<input class="btn btn-submit" type="button" value="Example output" onClick="javascript:location.href = '/iris3/results.php?jobid=2020041684528';" />
			<div class="row"><label id="hint_select_species"></label></div>
		</div>
		<div class="form-group">
			<p id="words" class="hidden text-danger">Your job is running, don't close the browser tab, waiting time could vary from minutes to hour.</p>
		</div>
	</form>
	<!--</div>-->
	<hr>
	<script src='assets/js/dropzone.js'></script>
	<link href="assets/css/dropzone.css" type="text/css" rel="stylesheet" />
</main>{{/block}}