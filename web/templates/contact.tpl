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
<link href="assets/css/help.css" rel="stylesheet" type="text/css">
<script src="assets/js/help.js"></script>
<script type="text/javascript">
$(document).ready(function() {
    $("#the-basics-content").click(function() {
        alert("click menu1");
    });
});
if(window.location.hash == ""){

 window.location.href = "https://bmbl.bmi.osumc.edu/iris3/contact.php#1contact";
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
					<div class="submenu" id="submenu-1contact"></div>
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
    <script type="text/javascript" src="//rf.revolvermaps.com/0/0/6.js?i=5wenrn3sxnj&amp;m=7&amp;c=e63100&amp;cr1=ffffff&amp;f=arial&amp;l=0&amp;bv=90&amp;lx=-420&amp;ly=420&amp;hi=20&amp;he=7&amp;hc=a8ddff&amp;rs=80" async="async"></script></main>



{{/block}}


