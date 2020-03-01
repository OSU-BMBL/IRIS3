{{extends file="base.tpl"}}

{{block name="extra_style"}}
  form div.fieldWrapper label { min-width: 5%; }
{{/block}}

{{block name="extra_js"}}


<!-- Piwik -->

<!-- End Piwik Code -->
{{/block}}


<script>

$(document).ready(function () {
    $("#showcase").awShowcase({
        content_width: 900,
        content_height: 1000,
        auto: true,
        interval: 3000,
        continuous: false,
        arrows: true,
        buttons: true,
        btn_numbers: true,
        keybord_keys: true,
        mousetrace: false,
        /* Trace x and y coordinates for the mouse */
        pauseonover: true,
        stoponclick: false,
        transition: 'fade',
        /* hslide/vslide/fade */
        transition_delay: 0,
        transition_speed: 500,
        show_caption: 'onload'
		/* onload/onhover/show */
    });
});
</script>

</head>
{{block name="main"}}
<script src="https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.4/latest.js?config=AM_CHTML"></script>
<script src="assets/js/ASCIIMathML.js"></script>

<link href="assets/css/help.css" rel="stylesheet" type="text/css">
<script src="assets/js/help.js"></script>
<script type="text/javascript">

if(window.location.hash == ""){
 window.location.href = "https://bmbl.bmi.osumc.edu/iris3/more.php#4FAQ";
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
					<a href="#4FAQ">
						<span class="section">FAQ</span>
					</a>
					<div class="submenu" id="submenu-4FAQ"></div>
				</li>
				<li>
					<a href="#5citation">
						<span class="section">Citations</span>
					</a>
					<div class="submenu" id="submenu-5citation"></div>
				</li>	
				<li>
					<a href="#6test_data">
						<span class="section">Tested data</span>
					</a>
					<div class="submenu" id="submenu-6test_data"></div>
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


