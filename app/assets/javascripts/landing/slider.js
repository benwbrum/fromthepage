$(function(){

   $('.loop').on('init', function(e, slick) {
        var $firstAnimatingElements = $('div.item:first-child').find('[data-animation]');
        doAnimations($firstAnimatingElements);
    });
    $('.loop').on('beforeChange', function(e, slick, currentSlide, nextSlide) {
        var $animatingElements = $('div.item[data-slick-index="' + nextSlide + '"]').find('[data-animation]');
        doAnimations($animatingElements);
    });

    $('.loop').slick({
        dots: true,
        infinite: true,
        speed: 900,
        arrows: true,
        autoplay: false,
        autoplaySpeed: 6000,
        fade: false,
        slidesToShow: 1,
        slidesToScroll: 1,

        responsive: [
            {
              breakpoint: 768,
              settings: {
                variableWidth: true,
                arrows: false,
              }
            },
          ]
    });
    
    $(".left").on("click",function(){
        $(this).next().slick('slickPrev');
    });
    $(".right").on("click",function(){
        $(this).prev().slick('slickNext');
    });

    function doAnimations(elements) {
        var animationEndEvents = 'webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend';
        elements.each(function() {
            var $this = $(this);
            var $animationDelay = $this.data('delay');
            var $animationType = 'animated ' + $this.data('animation');
            $this.css({
                'animation-delay': $animationDelay,
                '-webkit-animation-delay': $animationDelay
            });
            $this.addClass($animationType).one(animationEndEvents, function() {
                $this.removeClass($animationType);
            });
        });
    }
});
