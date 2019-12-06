<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">

<head>
    <!--====== USEFULL META ======-->
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="integrated cell type specific Regulon inference from single-cell rna seq" />
    <meta name="keywords" content="scrnaseq, regulon, single cell rna seq,Cell-type-specific Regulon Single-cell RNA-Seq" />
    <title>IRIS3: Integrated Cell-type-specific Regulon Inference Server from Single-cell RNA-Seq</title>
    <script src="assets/js/jquery-1.12.4.min.js"></script>
    <script src="assets/js/bootstrap.min.js"></script>
    <script src="assets/js/wow.min.js"></script>
    <script src="assets/js/jquery.ajaxchimp.js"></script>
    <script src="assets/js/jquery.sticky.js"></script>
	<script type="text/javascript" charset="utf8" src="https://cdn.datatables.net/1.10.19/js/jquery.dataTables.min.js"></script>
	<script type="text/javascript" charset="utf8" src="https://cdn.datatables.net/buttons/1.5.6/js/dataTables.buttons.min.js"></script>
	<script type="text/javascript" charset="utf8" src="https://cdn.datatables.net/buttons/1.5.6/js/buttons.html5.min.js"></script>
	<script type="text/javascript" src="https://cdn.jsdelivr.net/npm/lozad/dist/lozad.min.js"></script>
    <link rel="shortcut icon" type="image/ico" href="assets/img/favicon.png" />
	<link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap-select/1.13.2/css/bootstrap-select.min.css">
    <!--====== STYLESHEETS ======-->
	<link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/1.10.19/css/jquery.dataTables.css">
	<link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/buttons/1.5.6/css/buttons.dataTables.min.css">
	<link href="assets/css/heroic-features.css" rel="stylesheet">
    <link href="assets/css/plugins.css" rel="stylesheet">
    <link href="assets/css/theme.css" rel="stylesheet">
    <link href="assets/css/icons.css" rel="stylesheet">
    <!--====== MAIN STYLESHEETS ======-->
    <link href="assets/css/style.css" rel="stylesheet">
    <link href="assets/css/responsive.css" rel="stylesheet">
    <script src="assets/js/modernizr-2.8.3.min.js"></script>

	</head>

    <a href="#scroolup" class="scrolltotop"><i class="fa fa-long-arrow-up"></i></a>
        <div class="header-top-area" id="scroolup">
            <div class="mainmenu-area" id="mainmenu-area">
                <div class="mainmenu-area-bg"></div>
                <nav class="navbar">
                    <div class="container">
                        <div class="navbar-header">
                            <a class="navbar-brand" href="/iris3/index.php" style="color:white;font-size:24px">IRIS3</a>
                        </div>
                        <div id="main-nav" class="stellarnav">
                            <ul id="nav" class="nav navbar-nav pull-right">
                                <li><a href="/iris3/index.php">Home</a></li>
                                <li><a href="/iris3/submit.php">Submit</a></li>
                                <li><a href="/iris3/tutorial.php#1basics">Tutorial</a></li>
								<li><a href="/iris3/news.php#1version">What's new</a></li>
								<li><a href="/iris3/contact.php#1contact">Contact</a></li>
								<li><a href="/iris3/more.php#4FAQ">FAQ</a></li>
                            </ul>
                        </div>
                    </div>
                </nav>
            </div>
        </div>

      {{block name="head"}}
      
      {{/block}}


  
{{block name="main"}}

{{/block}}


    {{block name="foot"}}
    <footer class="footer-area sky-gray-bg">
        <div class="footer-bottom-area white">
            <div class="container">
                <div class="row">
                    <div class="col-md-12 col-lg-12 col-sm-12 col-xs-12">
                        <div class="footer-copyright text-center wow fadeIn">
                            <p class="m-0 text-center text">© <script>document.write(new Date().getFullYear());</script> <a href="https://u.osu.edu/bmbl/">BMBL</a> | <a href="mailto:qin.ma@osumc.edu" title="qin.ma@osumc.edu">Contact us: qin.ma@osumc.edu</a>  </p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </footer>

    {{/block}}
    
    <script type="text/javascript">

	  var _gaq = _gaq || [];
      _gaq.push(['_setAccount', 'UA-8700754-6']);
      _gaq.push(['_trackPageview']);
    
      (function() {
        var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
        ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
        var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
      })();
    </script>
  </body>
</html>