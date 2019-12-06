$(function () {
	var pre_submenu_id;
    var hash = getUrlHash(),
        parts, section, idx;
    if (hash) {
        renderContentByHash(hash);
    }

    $(window).on('hashchange', function () {
        renderContentByHash(getUrlHash());
    });

    /* Renders the correct submenu and content, depending on URL hash.
     */
    function renderContentByHash(hash) {
        var parts = hash.split('&'),
            section = parts[0],
            idx;

        if (parts.length > 1) {
            idx = Number(parts[1].split('=')[1]);
        }
		var submenu_id = '#submenu-'+ section;
        $(submenu_id).load('templates/tutorial/' + section + '-submenu.html', function () {
            highlightSubmenu(section);
            watchSubmenu(submenu_id);
			
        });
		if (pre_submenu_id != submenu_id){
			$(pre_submenu_id).empty();
			pre_submenu_id = submenu_id;
		}
		
        $('#content').load('templates/tutorial/' + section + '-content.html', function () {
            highlightCode();
            enlargeImageOnClick();
            watchScrollToLinks();
            highlightReportButtonOnHover();
            // We cannot just check `if (idx) {` because idx can be 0, which is falsy.
            if (typeof idx !== 'undefined') {
                scrollToQuestionByIndex(idx);
            }
        });
    }

    /* Highlight menu item that has been selected
     */
    function highlightSubmenu(section) {
        var $a = $('#menu li a[href="#' + section + '"]');
        $('#menu li a').removeClass('highlight');
        $a.addClass('highlight');
    }

    /* Highlight code snippets.
     */
    function highlightCode() {
        $('pre code').each(function (i, block) {
            //hljs.highlightBlock(block);
        });
    }

    /* Set listener to enlarge img tags on click.
     */
    function enlargeImageOnClick() {
        $('#content #the-basics-content img').click(function () {
            $(this).toggleClass('large');
        });
    }

    /* Any link with a "data-scroll-to" property should scroll to another question
     * in the documentation.
     */
    function watchScrollToLinks() {
        $('#content a').click(function (evt) {
            var idx = $(this).attr('data-scroll-to');
            if (typeof idx !== 'undefined') {
                idx = Number(idx);
                scrollToQuestionByIndex(idx);
                modifyUrlSoQuestionIsLinkable(idx);
            }
        });
    }

    /* Returns URL hash.
     */
    function getUrlHash() {
        return window.location.hash.replace('#', '');
    }

    /* Binds event listeners to menu items for scroll-to functionality.
     */
    function watchSubmenu(submenu_id) {
		submenu_li = submenu_id + ' li';
        $(submenu_li).click(function (evt) {
            var idx = $(this).index();
            scrollToQuestionByIndex(idx);
            modifyUrlSoQuestionIsLinkable(idx);
        });
    }

    /* Update the URL to contain the question ID.
     * This makes the question linkable.
     */
    function modifyUrlSoQuestionIsLinkable(idx) {
        var hash = getUrlHash();
        if (hash.indexOf('q=') > 0) {
            window.location.hash = hash.replace(/q=[0-9]/, 'q=' + idx);
        } else {
            window.location.hash += '&q=' + idx;
        }
    }

    /* Scroll to and highlight question based on index.
     */
    function scrollToQuestionByIndex(idx) {
        var $qa = $('#content .qa'),
            $elemToScrollTo = $qa.eq(idx);

        // Highlight question so it's easier to see on page,
        // especially if we cannot scroll directly to it
        // (if it's the last question for example).
        $qa.find('h3').removeClass('highlight');
        $elemToScrollTo.find('h3').addClass('highlight');

        // Scroll to question.
        //
        // Why select both `html` and `body`? See this question:
        // https://stackoverflow.com/questions/8149155
        $('html, body')
        // Animation appears sometimes appears to keep running and if I scroll up
        // directly afterwards, it tries to scroll down again. stop() fixes this.
            .stop()
            .animate({
                scrollTop: $elemToScrollTo.offset().top
            }, 500);
    }

    function highlightReportButtonOnHover() {
        $('#report-button-pointer')
            .mouseover(function () {
                // When I cache this selector, it does not work. Not sure why, but
                // might have to do with Jira's JS.
                $('.atlwdg-trigger.atlwdg-SUBTLE')
                    .css({
                        backgroundColor: '#fff3b8'
                    });
            })
            .mouseout(function () {
                $('.atlwdg-trigger.atlwdg-SUBTLE')
                    .css({
                        backgroundColor: '#f9f9f9'
                    });
            });
    }
});
