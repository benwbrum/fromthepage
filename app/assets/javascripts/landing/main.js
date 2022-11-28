$(function () {

    $(document).ready(function($) {
        $(window).scroll(function () {
            if ($(this).scrollTop() > 40) {
                $('.logo img').addClass('small-logo');
                $('header').addClass('header-bg');
            } else {
                $('.logo img').removeClass('small-logo');
                $('header').removeClass('header-bg');
            }
        });
    });

    $('.menu-trigger').on('click', function () {
        $(this).toggleClass('active');
        $('.menu').toggleClass('active');
        $('body').toggleClass('hidden');
        // $(window).scrollTop(0);
        return false;
    });

    $('.menu li .sub-menu').parent().append('<span class="sub-down"><i class="fa fa-angle-down"></i></span>');
    $('.sub-down').parent().find('a').on('click', function () {
        $(this).toggleClass('active');
        $(this).parent().find('.sub-menu').toggle();
    });


    $('#videoButton').on('click', function() {
        $(this).toggleClass('active');
    });

    var videoPlayer = document.getElementById('video');
    var videoButton = document.getElementById('videoButton');


    videoButton.addEventListener('click', function () {
        if (videoPlayer.paused == false) {
            videoPlayer.pause();
            videoPlayer.firstChild.nodeValue = 'Play';
        } else {
            videoPlayer.play();
            videoPlayer.firstChild.nodeValue = 'Pause';
        }
    });


    
});