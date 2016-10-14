var truncate = (function() {
    return {
        init: function() {
            var toggleLess = ' <a class="trunk8toggle-less" href="#">less</a>';
            var toggleMore = ' <a class="trunk8toggle-more" href="#">more</a>';
            var trunk8Settings = {
                lines: 2,
                tooltip: false
            };

            $(document).on('turbolinks:load', function() {
                $("[data-behavior='truncate'],[data-behavior='trunk8toggle']").trunk8(trunk8Settings);

                $("[data-behavior='trunk8toggle']").each(function() {
                    if ($(this).text()) {
                        $(this).append(toggleMore);
                    }
                });
            });

            $(document).on('click', '.trunk8toggle-more', function () {
                $(this).parent().trunk8('revert').append(toggleLess);
                return false;
            });

            $(document).on('click', '.trunk8toggle-less', function () {
                $(this).parent().trunk8(trunk8Settings).append(toggleMore);
                return false;
           });
        }
    };
}());

truncate.init();
