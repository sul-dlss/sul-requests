var truncate = (function() {
    return {
        init: function() {
            var toggleLess = ' <a class="trunk8toggle-less" href="#">less</a>';
            var toggleMore = ' <a class="trunk8toggle-more" href="#">more</a>';
            var trunk8Settings = {
                lines: 2,
                tooltip: false
            };
            var trunk8ToggleSettings = {
                lines: 2,
                fill: '&hellip;' + toggleMore,
                tooltip: false
            };

            $(document).on('turbo:load', function() {
                $("[data-behavior='truncate']").trunk8(trunk8Settings);

                $("[data-behavior='trunk8toggle']").trunk8(trunk8ToggleSettings);
            });

            $(document).on('click', '.trunk8toggle-more', function () {
                $(this).parent().trunk8('revert').append(toggleLess);
                return false;
            });

            $(document).on('click', '.trunk8toggle-less', function () {
                $(this).parent().trunk8(trunk8ToggleSettings);
                return false;
           });
        }
    };
}());

truncate.init();
