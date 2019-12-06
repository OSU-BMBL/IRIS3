{{extends file="base.tpl"}}

{{block name="extra_style"}}
  form div.fieldWrapper label { min-width: 5%; }
{{/block}}

{{block name="extra_js"}}


{{/block}}


{{block name="main"}}
<link href="assets/css/help.css" rel="stylesheet" type="text/css">
<script src="assets/js/help.js"></script>
<script type="text/javascript">
if(window.location.hash == ""){
 window.location.href = "https://bmbl.bmi.osumc.edu/iris3/news.php#1version";
}
</script>
    <main role="main" style="min-height: calc(100vh - 182px);">

      <!-- Main jumbotron for a primary marketing message or call to action -->

      <div class="container">
		<div>
		  <div class="row">
		  <div class="col-md-3">
		  	<div id="menu">
			<ul>
				<li>
					<a href="#1version" class="highlight">
						<span class="section">News</span>
						
					</a>
					<div class="submenu" id="submenu-1basics"></div>
				</li>
				<li>
					<a href="#2log">
						<span class="section">Update log</span>
						
					</a>
					<div class="submenu" id="submenu-2submission"></div>
				</li>
								
			</ul>
			
			
		</div>
		</div>
<div class="col-md-9">
		<div class="clear"></div>
		<div id="content">
		
        <hr>
</div>
</div>
      </div> <!--<img src="http://circos.ca/guide/tables/img/guide-table.png"> /container -->
<div class="push"></div>
    </main>




{{/block}}


