{{extends file="base.tpl"}}

{{block name="extra_style"}}
  form div.fieldWrapper label { min-width: 5%; }
{{/block}}

{{block name="extra_js"}}
{{/block}}
{{block name="main"}}


  
    <!--[if lt IE 8]>
        <p class="browserupgrade">You are using an <strong>outdated</strong> browser. Please <a href="http://browsehappy.com/">upgrade your browser</a> to improve your experience.</p>
    <![endif]-->

    <header class="top-area" id="home" >


        <!--WELCOME SLIDER AREA-->
        <div class="welcome-slider-area white font16">
            <div class="welcome-single-slide">
                <div class="slide-bg-one slide-bg-overlay"></div>
                <div class="welcome-area">
                    <div class="container">
                        <div class="row flex-v-center">
                            <div class="col-md-7 col-lg-7 col-sm-7 col-xs-7">
                                <div class="welcome-text">
                                    <h1>IRIS3</h1>
                                    <h3>Integrated Cell-type-specific Regulon Inference Server from Single-cell RNA-Seq</h3>
                                    <div class="home-button">
                                        <form method="POST" action="{{$URL}}" encType="multipart/form-data" id="needs-validation">
                                            <input type="text" name="jobid" id="jobid" placeholder="Search your job ID">
                                            <button type="submit" name="submit" value="submit"><i class="fa fa-search"></i></button>
                                        </form>
                                    </div>
                                </div>
								
                            </div>
							
                    
							 <div class="col-md-5 col-lg-5 col-sm-5 col-xs-5">
                                <div class="welcome-text">
                                 <a href="assets/img/iris3_overview.png" target="_blank"><img src="assets/img/iris3_overview.png" style="height:auto;margin:auto;display:block"></a>
                                               
                                </div>
                            </div>
							
                        </div>
						
                    </div>
                </div>
	<section class="features-top-area" id="features">
        <div class="container">
            <div class="row promo-content">
                <div class="col-md-4 col-lg-4 col-sm-6 col-xs-12">
                    <div class="text-icon-box mb20 xs-mb0 wow fadeInUp padding30" data-wow-delay="0.1s">
                        <!--<div class="box-icon features-box-icon">
                            <i class="fa fa-graduation-cap"></i>
                        </div>-->
                        <h3 class="box-title">Tutorial</h3>
                        <p>New to IRIS3? Our detailed tutorial will guide you through the process of using IRIS3.</p><br>
						<p><a class="enroll-button" href="/iris3/tutorial.php#1basics" role="button">Learn More</a></p>
                    </div>
                </div>
                
                
                <div class="col-md-4 col-lg-4 col-sm-6 col-xs-12">
					<div class="text-icon-box relative mb20 xs-mb0  wow fadeInUp padding30" data-wow-delay="0.2s">
                        
                        <h3 class="box-title">New Job</h3>
                            <p>Submit your data to IRIS3 or check out the example result.</p><br>
            <p><a class="enroll-button" href="/iris3/submit.php" role="button">Get Started</a></p>
                    </div>	
                </div>
				<div class="col-md-4 col-lg-4 col-sm-6 col-xs-12">
                    <div class="text-icon-box relative mb20 xs-mb0 wow fadeInUp padding30" data-wow-delay="0.3s">
                        <!--<div class="box-icon features-box-icon">
                            <i class="fa fa-rocket"></i>
                        </div>-->
                        <h3 class="box-title">News</h3>
                                    <p>Posted: 11/10/2019</p>
						<p> We are excited to present you the IRIS3 server 1.0! Please feel free to contact us if you encounter any issues.</p>
            <p><a class="enroll-button" href="/iris3/news.php#1version" role="button">More changes</a></p>
                    </div>
                </div>
            </div>
			
        </div>
    </section>
            </div>
        </div>
		<!--<script src="assets/js/three.r92.min.js"></script>
<script src="assets/js/vanta.net.min.js"></script>
<script>
VANTA.NET({
  el: "#home",
  color:0x17984c,
  backgroundColor:0x0B1E28,
  points: 4.00,
  maxDistance: 17.00,
  spacing: 13
})
</script>
-->

<script src="assets/js/three.r92.min.js"></script>
<script src="assets/js/vanta.cells.min.js"></script>
<script>
VANTA.CELLS({
  el: "#home",
  color1: 0x656b6a,
  color2: 0x0B1E28,
  size: 2.60,
  speed: 0.90
})
</script>


        <!--WELCOME SLIDER AREA END-->
<div class="push"></div>
    </header>








{{/block}}


