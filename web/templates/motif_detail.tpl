{{extends file="base.tpl"}}

{{block name="extra_style"}}
  .dataTables_wrapper { min-height: 0; }
	div#content { min-height: 400px; }
	.title_whole {
		width : 1013px;
		height : 25px;
		padding : 5px;
		border-top-left-radius : 5px;
		border-top-right-radius : 5px;
		border : 1px solid #c3c3c3;
		background-color : #f2f2f2;
		text-align : center;
	}
{{/block}}

{{block name="extra_js"}}

<script type="text/javascript">
   var $J = jQuery.noConflict();
    var table1;
    var tt=0;   
              jQuery.extend( jQuery.fn.dataTableExt.oSort, {
                                       "scientific-pre": function ( a ) {
                                         var a = a.replace(/<(?:.|\s)*?>/g, "");
                                        return parseFloat(a);},
                                        "scientific-asc": function ( a, b ) {
                                        return ((a < b) ? -1 : ((a > b) ? 1 : 0));},
                                        "scientific-desc": function ( a, b ) {
                                        return ((a < b) ? 1 : ((a > b) ? -1 : 0));}
                             } ); 
    
    $J(document).ready(function() {
    table1=$J("table#datat").dataTable({
            "bJQueryUI": true, "sPaginationType": "full_numbers", "iDisplayLength": 5,
            "bProcessing" : false, "bServerSide": false,
            "aLengthMenu": [[5, 10, 15, -1], [5, 10, 15, "All"]],
            "aoColumns": [
			                {"bSortable": false} ,
			                 null,
			               { "sType": "scientific" },
		                  	null,
		                   {"bSortable": false}
	                      	],
            "oLanguage" : { 
              "sSearch" : "Search in table:",
              "sLoadingRecords" : "Loading data from server ... <img src='static/images/busy.gif' />"
            }
        }); 
  
        });
</script>
<!-- Piwik -->

<!-- End Piwik Code -->
{{/block}}

</head>
{{block name="main"}}
    <main role="main">

      <!-- Main jumbotron for a primary marketing message or call to action -->
<main role="main" class="container">

    <div id="content">

        <div class="container">
            <br/>
            <div class="flatPanel panel panel-default">
                <div class="flatPanel panel-heading"><strong>Job ID: {{$jobid}}</strong></div>
                <div class="panel-body">
  <form id="frm1" name="form">
      <div class="section2">
       <table class="table table-bordered" id="datat" >
         <thead>
            <tr>
               <th style="text-align:center;">Motif logo</th>
               <th style="text-align:center;">Length</th>
               <th style="text-align:center;">Pvalue</th> 
               <th style="text-align:center;">Number</th>              
               <th style="text-align:center;">Motifs</th>
              
             </tr> 
        </thead>
          
          <tbody>
            {{section name=sec1 loop=$ann}}
			
                <tr  align="middle">
                <td>
                
                
                <img onerror="this.src='data/{{$jobid}}/logo/{{$ann[sec1].Motifname}}.fsa.png'; "src="data/{{$jobid}}/logo/{{$ann[sec1].Motifname}}.fsa.png"/>
                 
                </td>
                <td><br/><br/><br/><br/><br/>{{$ann[sec1].Motiflength}}</td>
                <td><br/><br/><br/><br/><br/>{{$ann[sec1].MotifPvalue}}</td>
                <td><br/><br/><br/><br/><br/>{{$ann[sec1].Motifnumber}}</td> 
                <td align="left" >   <br/>
                                  <div style="width:600px;">
                                  <table class="table table-bordered" style="display: inline-block; overflow-y: scroll;max-height:400px;">
	                                 <tr>
	                                      <!--<td>Seq</td>-->
	                                      <td>Start</td>
	                                      <td>Motif</td>
	                                      <td>End</td>
	                                      <td>Score</td>
	                                      <td>Gene</td>
	                                 </tr>
	                                
                                  {{section name=sec2 loop=$ann[sec1].Motifs}}
                                        {{if $ann[sec1].Motifs[sec2].red==1}}
                                          <tr >
                                         <!--<td>{{$ann[sec1].Motifs[sec2].Seq}}</td>-->
                                         <td>{{$ann[sec1].Motifs[sec2].start}}</td>
                                         <td>{{$ann[sec1].Motifs[sec2].Motif}}</td>
                                         <td>{{$ann[sec1].Motifs[sec2].end}}</td>
                                         <td>{{$ann[sec1].Motifs[sec2].Score}}</td>
                                         <td><a  target="_blank" href= "https://www.ensembl.org/id/{{$ann[sec1].Motifs[sec2].Info}}" style="font-size:14px; display: inline-block;">{{$ann[sec1].Motifs[sec2].Info}}&nbsp;</a></td>
                                         </tr>
                                         {{else}}
                                           <tr>
                                         <!--<td>{{$ann[sec1].Motifs[sec2].Seq}}</td>-->
                                         <td>{{$ann[sec1].Motifs[sec2].start}}</td>
                                         <td>{{$ann[sec1].Motifs[sec2].Motif}}</td>
                                         <td>{{$ann[sec1].Motifs[sec2].end}}</td>
                                         <td>{{$ann[sec1].Motifs[sec2].Score}}</td>
                                         <td><a  target="_blank" href= "https://www.ensembl.org/id/{{$ann[sec1].Motifs[sec2].Info}}" style="font-size:14px; display: inline-block;">{{$ann[sec1].Motifs[sec2].Info}}&nbsp;</a></td>
                                         </tr>
                                         {{/if}}
                                   {{/section}}
                                   
                                 </table>
                               </div>  
                </td>
	           </tr>
	    
          {{/section}}
         </tbody>
    </table>
    
      <table  border="1" >
       <thead>
       <!--<th>No.seq</th>-->
	   <th>Gene</th>
       <th width="1000px">Motif Mapping</th>
       </thead>
       <tbody>
       {{section name=sec1 loop=$src}}
          <tr>
             <!--<td>{{$src[sec1].id}}</td>-->
			 <td><a  target="_blank" href= "https://www.ensembl.org/id/{{$ann[0].Motifs[sec1].Info}}" style="font-size:14px; display: inline-block;">{{$ann[0].Motifs[sec1].Info}}</a></td>
             <td><img src="draw_scale.php?ScaleLen={{$src[sec1].ScaleLen}}&GridUnit={{$src[sec1].GridUnit}}&LabelUnit={{$src[sec1].LabelUnit}}&MinLabel={{$src[sec1].MinLabel}}&Unit={{$src[sec1].Unit}}&WinWidth={{$src[sec1].WinWidth}}&id={{$src[sec1].id}}&jobid1={{$src[sec1].jobid1}}&blank={{$src[sec1].blank}}&color=1"/></td>
          </tr>
       {{/section}}
       </tbody>
      </table>
	  <br/>
      <div class = "title_whole"><strong style = "position : relative;">Motif Matrix Format</strong></div>
      <textarea  style="position:relative; width:99%; height:400px; border-top-left-radius : 0px; border-top-right-radius : 0px;">{{$matrix}}</textarea> 

      </div>

</form>

                </div>
            </div>
        </div>
    </div>
            
        

        

     

    </main>




{{/block}}


