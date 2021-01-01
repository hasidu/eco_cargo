let hud = {};
let hudWrapper = $("#hudWrapper");

let deliveryWrapper = $("#deliveryWrapper");
let generalWrapper = $("#generalWrapper");
let actionWrapper = $("#actionWrapper");

let monitor = {};

function closeHud(identifier) {

    $.when($(identifier).fadeOut()).done(function () {
        $(identifier).remove();
    });
}

function deliveryInfo(data) {

    if (!$.isEmptyObject(data)) {

        deliveryWrapper.empty();

        data.goodsQuality = data.goodsQuality < 0 ? 0 : data.goodsQuality;

        let properties = jsonParse(data.productProperties);

        let template = $(".hud").clone();
        template.removeClass("template");
        template.addClass("dInfo");

        hud = {
            wheel: template.find(".wheel"),
            roll: template.find(".roll"),
            damage: template.find(".damage"),
            trailerHealth: template.find(".trailerHealth"),
            trailerBar: template.find(".trailerBar"),
            goodsQuality: template.find(".goodsQuality"),
            goodsBar: template.find(".goodsBar"),
            speedLimit: template.find(".speedLimit")
        };


        template.find(".hudProperties").html(icons(properties));
        template.find(".productName").html(data.productName);
        /*template.find(".hudAddress").html(data.targetZone.address);*/

        hud.trailerBar.css("width", data.trailerHealth + "%");
        hud.goodsBar.css("width", data.goodsQuality + "%");

        hud.trailerHealth.html(data.trailerHealth);
        hud.goodsQuality.html(data.goodsQuality);

        hud.speedLimit.html(data.speedLimit);


        deliveryWrapper.html(template);

        hudWrapper.css("display", "block");
    }
}

function updateHud(paramName, value) {

    if (jQuery.isEmptyObject(hud)) {
        return false
    }

    switch (paramName) {

        case 'trailerHealth':

            hud.trailerBar.css("width", value + "%");
            hud.trailerHealth.html(value);

            if (monitor.damage === undefined) {

                hud.damage.addClass("alertIcon");
                monitor.damage = true;

                setTimeout(function () {

                    hud.damage.removeClass("alertIcon");
                    delete monitor.damage;

                }, 5000);
            }
            break;

        case 'goodsQuality':

            value = value < 0 ? 0 : value;

            hud.goodsBar.css("width", value + "%");
            hud.goodsQuality.html(value);
            break;

        case 'wheel':

            if (monitor.wheel === undefined) {

                hud.wheel.addClass("alertIcon");
                monitor.wheel = true;

                setTimeout(function () {

                    hud.wheel.removeClass("alertIcon");
                    delete monitor.wheel;

                }, 5000);
            }
            break;

        case 'roll':

            if (monitor.roll === undefined) {

                hud.roll.addClass("alertIcon");
                monitor.roll = true;

                setTimeout(function () {

                    hud.roll.removeClass("alertIcon");
                    delete monitor.roll;

                }, 5000);
            }
            break;

        case 'speedLimit':

            hud.speedLimit.html(value);
            break;

        case 'overSpeed':

            if (value === 1) {

                hud.speedLimit.css("color", "red");
                hud.speedLimit.addClass("blink");
                monitor.overSpeed = true;

            } else {

                hud.speedLimit.css("color", "white");
                hud.speedLimit.removeClass("blink");
            }
            break;
    }
}

function actionInfo(value) {

    actionWrapper.empty();

    let aInfo = $(".actionInformation").clone();
    aInfo.removeClass("template").addClass("aInfo");

    aInfo.find(".msgCompanyName").html(value.name);
    aInfo.find(".msgDescription").html(value.description);
    aInfo.find(".msgActionMsg").html(value.message);
    aInfo.fadeIn();
    actionWrapper.html(aInfo);
}

let persistentNotifs = {};

function CreateNotification(data) {
    let $notification = $(document.createElement('div'));
    $notification.addClass('notification').addClass(data.type);
    $notification.html(data.text);
    $notification.fadeIn();
    if (data.style !== undefined) {
        Object.keys(data.style).forEach(function (css) {
            $notification.css(css, data.style[css])
        });
    }

    return $notification;
}

function ShowNotification(data) {

    if (data.persist === undefined) {

        let $notification = CreateNotification(data);
        generalWrapper.append($notification);

        setTimeout(function () {
            $.when($notification.fadeOut()).done(function () {
                $notification.remove();
            });
        }, data.length != null ? data.length : 8000);

    } else {
        if (data.persist.toUpperCase() === 'START') {
            if (persistentNotifs[data.id] === undefined) {
                let $notification = CreateNotification(data);
                generalWrapper.append($notification);
                persistentNotifs[data.id] = $notification;
            } else {
                let $notification = $(persistentNotifs[data.id]);
                $notification.addClass('notification').addClass(data.type);
                $notification.html(data.text);

                if (data.style !== undefined) {
                    Object.keys(data.style).forEach(function (css) {
                        $notification.css(css, data.style[css])
                    });
                }
            }
        } else if (data.persist.toUpperCase() === 'END') {
            let $notification = $(persistentNotifs[data.id]);
            $.when($notification.fadeOut()).done(function () {
                $notification.remove();
                delete persistentNotifs[data.id];
            });
        }
    }
}