let disableMissionStartForDefenders = false;
let missionOrderBy = 'all_started';
let lastEventTime = 0;
let floodProtectionTime = 3; // in sec
let floodMessage = ('Flood védelem: Várj %s másodpercet').format(floodProtectionTime);


function closePage() {

    let page = $('#page');

    page.css("display", "none");
    page.empty();

    $('.pageWrapper').css("display", "none");
}

function icons(properties) {

    let out = "";

    if (!jQuery.isEmptyObject(properties)) {

        properties.forEach(function (v, k) {

            out += "<img src='img/" + v + ".png' class='propertyIcon'>";
        });

    }

    return out;
}

function inMission(cargo, currentZone, player, mission) {

    let isMission = false;
    let isOwned = false;
    let inProgress = false;

    if (cargo.defender !== '' && !$.isEmptyObject(mission)) {

        for (let key in mission) {

            let [loadingZoneId, productId] = key.split('_');


            if (productId == cargo.id && loadingZoneId == currentZone.id) {

                isMission = true;

                if (mission[key].owner.identifier === player.identifier) {

                    isOwned = true;
                }

                if (mission[key].trailerPlate) {

                    inProgress = true;
                }
            }
        }
    }

    return {
        isMission: isMission,
        isOwned: isOwned,
        inProgress: inProgress
    }
}

function playerIsDefender(missionList, player) {

    if (!$.isEmptyObject(missionList)) {

        for (let key in missionList) {

            let defenders = missionList[key].joined;

            if (!$.isEmptyObject(defenders)) {

                for (let k in defenders) {

                    if (defenders[k] === player.identifier) {

                        return key;
                    }
                }
            }
        }
    }

    return false;
}

function playerIsConfidential(mission, player) {

    if (player.group === 'superadmin') {
        return true
    }
    if (player.identifier === mission.owner.identifier) {
        return true
    }
    if (player.job.name === mission.defender) {
        return true
    }

    return false
}

function openCargoSelect(shipments, currentZone, player, mission) {

    if (!$.isEmptyObject(shipments)) {

        let pageWrapper = $(".pageWrapper");
        pageWrapper.find(".titleContainer").css("display", "block");
        let page = $("#page");


        //pageWrapper.find(".headInformation").html(player.characterName);
        pageWrapper.find(".title").html(currentZone.name);
        pageWrapper.find(".description").html(("%s, %s").format(currentZone.address, currentZone.description));


        let cargoItemTmp = $(".cargoItem");
        let cargoDestinationTableRow = $(".cargoDestinationTableRow");


        jQuery.each(shipments, function (index, cargo) {

            if (!cargo) {
                return
            } // =  jQuery continue


            let missionInfo = inMission(cargo, currentZone, player, mission);
            let remainingTime = cargo.remainingTime !== 0;
            let playerInDefenderJob = player.job.name === cargo.defender;
            let properties = jsonParse(cargo.properties);


            let cargoItem = cargoItemTmp.clone();
            cargoItem.css("display", "grid");
            cargoItem.removeClass("template");

            if (!$.isEmptyObject(cargo.destinationZones)) {

                jQuery.each(cargo.destinationZones, function (i, dZone) {


                    let tr = cargoDestinationTableRow.clone();
                    tr.removeClass("template");

                    if (remainingTime || (playerInDefenderJob && disableMissionStartForDefenders)) {

                        tr.addClass("disabled");

                    } else {

                        tr.click(function () {

                            page.find('.cargoDestinationTableRow').removeClass('trSelected');
                            page.find('.submit').css("display", "none");
                            page.find('.missionRegister').css("display", "none");

                            $(this).addClass('trSelected');

                            if ((!missionInfo.isMission && !player.InMission) || missionInfo.isOwned) {

                                cargoItem.find('input[name="targetData"]').val(JSON.stringify({
                                    km: dZone.distance,
                                    destinationId: dZone.id,
                                    freightFee: dZone.priceData.freightFee,
                                    illegalPrice: dZone.priceData.illegalPrice
                                }));

                                if (cargo.defender === '' || (missionInfo.isOwned && !missionInfo.inProgress)) {

                                    cargoItem.find(".submit").css("display", "inline-block");
                                }

                                if (cargo.defender !== '' && (missionInfo.isOwned || !missionInfo.inProgress)) {

                                    cargoItem.find(".missionRegister").css("display", "inline-block");
                                }
                            }
                        });
                    }


                    if (missionInfo.isMission) {

                        tr.addClass('inMission');
                        cargoItem.find(".missionInfo").css("display", "inline-block");
                    }

                    tr.find(".cargoName").html(dZone.name);
                    tr.find(".cargoDescription").html(dZone.description);
                    tr.find(".cautionMoney").html(MONEY.format(cargo.caution_money));
                    tr.find(".cargoDistance").html(("%s Km").format(dZone.distance));
                    tr.find(".freightFee").html(MONEY.format(dZone.priceData.freightFee));
                    //tr.find(".freightFee").html("$" + dZone.priceData.freightFee + " $" + dZone.priceData.illegalPrice);


                    tr.appendTo(cargoItem.find(".cargoDestinationTable"));

                });

            }

            if (cargo.defender !== '') {

                cargoItem.find(".cargoDefenders").html(("Védelem:<br />(%s fő) %s").format(cargo.required_defenders, cargo.defenderLabel));
            }

            cargoItem.find(".itemImg").css("background-image", "url('img/" + cargo.trailer + ".jpg')");
            cargoItem.find(".itemHeader").html(cargo.label);
            cargoItem.find(".description").html(cargo.description);
            cargoItem.find(".icons").html(icons(properties));


            if (remainingTime || (playerInDefenderJob && disableMissionStartForDefenders)) {

                cargoItem.find(".itemHeader").addClass("disabled");
                cargoItem.find(".availableAlert").addClass("noAvailable");

                if (remainingTime) {

                    cargoItem.find(".availableAlert").html(cargo.remainingTimeDisplay);
                } else if (playerInDefenderJob && disableMissionStartForDefenders) {

                    cargoItem.find(".availableAlert").html('Védőként nem indítható');
                }
            }


            cargoItem.find('input[name="freightData"]').val(JSON.stringify({
                trailerModel: cargo.trailer,
                cautionMoney: cargo.caution_money,
                goodsValue: cargo.value,
                productId: cargo.id,
            }));

            cargoItem.find('input[name="params"]').val(cargo.params);

            cargoItem.find(".form").attr('name', cargo.name);

            cargoItem.find(".form").submit(function (e) {

                e.preventDefault();

                let cargoData = {

                    ...JSON.parse(cargoItem.find('input[name="freightData"]').val()),
                    ...JSON.parse(cargoItem.find('input[name="targetData"]').val()),
                    params: cargoItem.find('input[name="params"]').val(),
                    required_defenders: cargo.required_defenders,
                    defender: cargo.defender,
                    loadingZoneId: currentZone.id
                };

                // checkDefense
                if (cargo.defender !== '') {

                    $.post('https://eco_cargo/checkDefense', JSON.stringify(cargoData)).then(
                        resp => {
                            let response = jsonParse(resp);

                            if (typeof response.message === 'string' && response.message !== '') {

                                //Üzenet megjelenítése
                                ShowNotification({
                                    type: response.type,
                                    text: response.message,
                                });
                            }

                            if (response.state) {

                                //fuvar inditása
                                closePage();
                                $.post('https://eco_cargo/registerCargo', JSON.stringify(cargoData));
                            }
                        }
                    );

                } else {

                    closePage();
                    $.post('https://eco_cargo/registerCargo', JSON.stringify(cargoData));
                }


                return false;
            });


            // MISSION REGISTER BTN
            cargoItem.find(".missionRegister").click(function (e) {

                let cargoData = {

                    ...JSON.parse(cargoItem.find('input[name="freightData"]').val()),
                    ...JSON.parse(cargoItem.find('input[name="targetData"]').val()),
                    params: cargoItem.find('input[name="params"]').val(),
                    required_defenders: cargo.required_defenders,
                    defender: cargo.defender,
                    loadingZoneId: currentZone.id
                };

                $.post('https://eco_cargo/missionRegister', JSON.stringify(cargoData)).then(
                    resp => {
                        let response = jsonParse(resp);

                        if (typeof response.message === 'string' && response.message !== '') {

                            //Üzenet megjelenítése
                            ShowNotification({
                                type: response.type,
                                text: response.message,
                            });
                        }


                        // IN MISSION SETTINGS
                        if (response.state) {

                            // ADD MISSION MARKER
                            cargoItem.find('tr').addClass('inMission');
                            cargoItem.find(".missionInfo").css("display", "inline-block");

                            //REGISTER PLAYER IN MISSION
                            player.InMission = true;
                            missionInfo.isOwned = true;

                            cargoItem.find('tr').click();

                            //TODO HA MISSIONBA kerülsz a többi product mission gombját tiltani kell
                        }
                    }
                );
                return false;
            });

            cargoItem.appendTo(page);
        });


        pageWrapper.css("display", "block");
        page.css("display", "block");
    }
}

function openMissionList(missionList, player) {

    if (!$.isEmptyObject(missionList)) {

        let pageWrapper = $(".pageWrapper");
        pageWrapper.find(".titleContainer").css("display", "block");
        let page = $("#page");

        let isDefender = playerIsDefender(missionList, player);


        //pageWrapper.find(".headInformation").html(player.characterName);
        pageWrapper.find(".title").html("Küldetés lista");
        pageWrapper.find(".description").html("Csatlakozhatsz védőnek, jelölheted a rakodási hely és a célállomás pontokat.");

        let missionItemTmp = $(".missionItem");

        jQuery.each(missionList, function (key, mission) {

            let properties = jsonParse(mission.product.properties);

            let missionItem = missionItemTmp.clone();
            missionItem.css("display", "grid");
            missionItem.removeClass("template");

            let isConfidentialPlayer = playerIsConfidential(mission, player);

            let missionOwnerHtml = isConfidentialPlayer ? mission.owner.characterName : 'Bizalmas információ';
            let missionJoinedHtml = isConfidentialPlayer ? Object.keys(mission.joined).length : '?';
            let missionDefenderHtml = isConfidentialPlayer ? mission.product.defenderLabel : '?';

            //CARGO HEADER
            missionItem.find(".icons").html(icons(properties));
            missionItem.find(".itemHeader").html(mission.product.label);
            missionItem.find(".itemImg").css("background-image", "url('img/" + mission.product.trailer + ".jpg')");
            missionItem.find(".form").attr('name', mission.name);
            missionItem.find(".missionLoadingAddress").html(mission.loadingZone.address);
            missionItem.find(".missionOwner").html(missionOwnerHtml);
            missionItem.find(".missionDefender").html(missionDefenderHtml);
            missionItem.find(".missionJoined").html(missionJoinedHtml);

            // SET LOADING WAYPOINT BTN
            let setLoadingWaypointBtn = missionItem.find(".missionSetWaypoint");
            setLoadingWaypointBtn.click(function () {

                $.post('https://eco_cargo/setWaypoint', JSON.stringify({
                    missionId: key
                }));

                setLoadingWaypointBtn.remove();
                closePage();
                return false;
            });


            if (isDefender && isDefender === key && mission.destinationZoneId) {

                // SET DESTINATION WAYPOINT BTN
                let setDestinationWaypointBtn = missionItem.find(".missionSetDestinationWaypoint");

                setDestinationWaypointBtn.css('display', 'block');

                setDestinationWaypointBtn.click(function () {

                    $.post('https://eco_cargo/setDestinationWaypoint', JSON.stringify({
                        missionId: key
                    }));

                    setDestinationWaypointBtn.remove();
                    closePage();
                    return false;
                });
            }


            // JOIN BTN
            if (mission.owner.identifier !== player.identifier && !isDefender && mission.product.defender === player.job.name) {


                if (lastEventTime + floodProtectionTime < getTimeStamp()) {

                    lastEventTime = getTimeStamp();

                    let joinBtn = missionItem.find(".join");

                    joinBtn.removeClass('hide');
                    joinBtn.click(function () {

                        $.post('https://eco_cargo/missionJoin', JSON.stringify({
                            missionId: key,
                            defender: mission.product.defender,
                            owner: mission.owner,
                            player: player
                        }));

                        joinBtn.remove();
                        closePage();
                        return false;
                    });

                } else {

                    ShowNotification({type: 'warning', text: floodMessage});
                }
            }


            // LEAVE BTN
            if (mission.owner.identifier !== player.identifier && key === isDefender) {

                if (lastEventTime + floodProtectionTime < getTimeStamp()) {

                    lastEventTime = getTimeStamp();

                    let leaveBtn = missionItem.find(".leave");

                    leaveBtn.removeClass('hide');
                    leaveBtn.click(function () {

                        $.post('https://eco_cargo/missionLeave', JSON.stringify({
                            missionId: key,
                            defender: mission.product.defender,
                            owner: mission.owner,
                            player: player
                        }));

                        leaveBtn.remove();
                        closePage();
                        return false;
                    });

                } else {

                    ShowNotification({type: 'warning', text: floodMessage});
                }
            }


            // DELETE BTN
            if (mission.owner.identifier === player.identifier && !mission.trailerPlate) {

                let deleteBtn = missionItem.find(".delete");

                deleteBtn.removeClass('hide');
                deleteBtn.click(function () {

                    $.post('https://eco_cargo/missionDelete', JSON.stringify({
                        missionId: key,
                        defender: mission.product.defender
                    }));

                    deleteBtn.remove();
                    closePage();
                    return false;
                });
            }

            missionItem.appendTo(page);
        });

        pageWrapper.css("display", "block");
        page.css("display", "block");
    }

}

function openCargoPage(report) {

    if (!$.isEmptyObject(report)) {

        let pageWrapper = $(".pageWrapper");
        let page = $("#page");
        page.empty();

        //let properties = jsonParse(report.product.properties);

        let reportTmp = $(".cargoReport").clone();
        reportTmp.removeClass("template");

        pageWrapper.find(".title").html('Szállítólevél');
        pageWrapper.find(".description").html('');


        reportTmp.find(".employeeName").html(report.owner.characterName);
        reportTmp.find(".productName").html(report.product.name);
        reportTmp.find(".propNames").html(report.product.propnames);


        reportTmp.find(".senderCompany").html(report.loadingZone.name);
        reportTmp.find(".senderAddress").html(report.loadingZone.address);
        reportTmp.find(".senderDescription").html(report.loadingZone.description);

        reportTmp.find(".itemImg").css("background-image", "url('img/" + report.product.trailer + ".jpg')");

        reportTmp.find(".deliveryCompany").html(report.targetZone.name);
        reportTmp.find(".deliveryAddress").html(report.targetZone.address);
        reportTmp.find(".deliveryDescription").html(report.targetZone.description);

        reportTmp.find(".km").html(report.km);

        reportTmp.find(".plate").html(report.trailerPlate);

        reportTmp.find(".trailerDamage").html(("(trailer) %s %").format(Math.round(report.trailerHealth * 0.1)));
        reportTmp.find(".goodsDamage").html(("(rakomány) %s %").format(Math.round(report.quality)));
        reportTmp.find(".maxSpeedCountry").html(("%s Km/h").format(report.maxSpeed.country));
        reportTmp.find(".maxSpeedCity").html(("%s Km/h").format(report.maxSpeed.city));


        //PAYMENT
        if (report.showPayData) {


            let payTable;
            let paymentContainer = reportTmp.find("#paymentContainer");

            if (report.stolen) {

                payTable = $("#illegalPaymentTable").clone();
                payTable.find(".freightFee").html(MONEY.format(report.illegalPrice));
            } else {

                payTable = $("#legalPaymentTable").clone();

                payTable.find(".cautionMoney").html(MONEY.format(report.cautionMoney));
                payTable.find(".cautionDeduction").html(MONEY.format(report.payData.cautionDeduction));
                payTable.find(".cautionPayment").html(MONEY.format(report.payData.cautionPayment));
                payTable.find(".freightFee").html(MONEY.format(report.payData.freightFee));
            }

            payTable.find(".trailerDamage").html(("(trailer) %s %").format(Math.round(report.trailerHealth * 0.1)));
            payTable.find(".goodsDamage").html(("(rakomány) %s %").format(Math.round(report.quality)));
            payTable.find(".priceDeduction").html(MONEY.format(report.payData.priceDeduction));
            payTable.find(".pricePayment").html(MONEY.format(report.payData.pricePayment));
            payTable.find(".payable").html(MONEY.format(report.payData.payable));

            if (!isNaN(report.payData.defenderSocietyPayable) && report.payData.defenderSocietyPayable > 0) {

                payTable.find(".societyPayableTr").css("display", "table-row");
                payTable.find(".defenderSocietyPayable").html(MONEY.format(report.payData.defenderSocietyPayable));
            }


            payTable.removeClass("template");
            payTable.appendTo(paymentContainer);

        }

        //PAYMENT END
        reportTmp.appendTo(page);

        pageWrapper.css("display", "block");
        page.css("display", "block");
    }

}

function openMaintenance(data) {

    if (!$.isEmptyObject(data)) {

        let pageWrapper = $(".pageWrapper");
        pageWrapper.find(".titleContainer").css("display", "none");

        let page = $("#page");
        page.empty();

        let mntTmp = $(".mnt").clone();
        mntTmp.removeClass("template");

        mntTmp.find(".countProducts").html(data.countProducts);
        mntTmp.find(".countProductsMarker").addClass((data.countProducts > 0) ? 'good' : 'fault');

        let orphanProductHtml = 0;
        if (!$.isEmptyObject(data.orphanProduct)) {

            orphanProductHtml = '<ul>';

            for (let i = 0; i < data.orphanProduct.length; i++) {

                orphanProductHtml += "<li>" + data.orphanProduct[i].id + ". " + data.orphanProduct[i].transName + "</li>";
            }

            orphanProductHtml += '</ul>';
        }

        mntTmp.find(".orphanProduct").html(orphanProductHtml);
        mntTmp.find(".orphanProductMarker").addClass((orphanProductHtml === 0) ? 'good' : 'fault');

        mntTmp.find(".countRoutes").html(data.countRoutes);
        mntTmp.find(".countRoutesMarker").addClass((data.countRoutes > 0) ? 'good' : 'fault');
        mntTmp.find(".countUniqueRoutes").html(data.countUniqueRoutes);
        mntTmp.find(".countUniqueRoutesMarker").addClass((data.countUniqueRoutes > 0) ? 'good' : 'fault');

        mntTmp.find(".wrongDistanceRecord").html(data.wrongDistanceRecord);
        mntTmp.find(".wrongDistanceRecordMarker").addClass((data.wrongDistanceRecord === 0) ? 'good' : 'fault');


        let orphanDistanceRecordHtml = 0;
        if (!$.isEmptyObject(data.orphanDistanceRecord)) {

            orphanDistanceRecordHtml = '<ul>';

            for (let i = 0; i < data.orphanDistanceRecord.length; i++) {

                orphanDistanceRecordHtml += "<li>" + data.orphanDistanceRecord[i] + "</li>";
            }

            orphanDistanceRecordHtml += '</ul>';
        }

        mntTmp.find(".orphanDistanceRecord").html(orphanDistanceRecordHtml);
        mntTmp.find(".orphanDistanceRecordMarker").addClass((orphanDistanceRecordHtml === 0) ? 'good' : 'fault');


        mntTmp.find(".missingDistanceRecord").html(data.missingDistanceRecord);
        mntTmp.find(".missingDistanceRecordMarker").addClass((data.missingDistanceRecord === 0) ? 'good' : 'fault');

        mntTmp.find(".countActionPoints").html(data.countActionPoints);
        mntTmp.find(".countActionPointsMarker").addClass((data.countActionPoints > 0) ? 'good' : 'fault');


        let missingActionPointsHtml = 0;
        if (!$.isEmptyObject(data.missingActionPoints)) {

            missingActionPointsHtml = '<ul>';

            jQuery.each(data.missingActionPoints, function (k, v) {

                missingActionPointsHtml += ("<li>Zone: %s, Product: %s. %s</li>").format(
                    v.zoneId,
                    v.productId,
                    v.productLabel
                )
            });

            missingActionPointsHtml += '</ul>';
        }

        mntTmp.find(".missingActionPoints").html(missingActionPointsHtml);
        mntTmp.find(".missingActionPointsMarker").addClass((missingActionPointsHtml === 0) ? 'good' : 'fault');


        let orphanActionPointsHtml = 0;
        if (!$.isEmptyObject(data.orphanActionPoints)) {

            orphanActionPointsHtml = '<ul>';

            for (let i = 0; i < data.orphanActionPoints.length; i++) {

                orphanActionPointsHtml += ("<li>%s. %s</li>").format(
                    data.orphanActionPoints[i].id,
                    data.orphanActionPoints[i].name
                )
            }

            orphanActionPointsHtml += '</ul>';
        }


        mntTmp.find(".orphanActionPoints").html(orphanActionPointsHtml);
        mntTmp.find(".orphanActionPointsMarker").addClass((orphanActionPointsHtml === 0) ? 'good' : 'fault');


        mntTmp.find(".missingLocales").html(JSON.stringify(data.missingLocales));


        // SUBMIT BTN
        let distanceBtn = mntTmp.find(".distanceBtn");
        distanceBtn.click(function () {

            $.post('https://eco_cargo/distanceCalc', JSON.stringify({}));

            distanceBtn.remove();
            closePage();
            return false;
        });

        // SHOW ZONES BTN
        let showAllActionPointBtn = mntTmp.find(".showAllActionPointBtn");
        showAllActionPointBtn.click(function () {

            $.post('https://eco_cargo/showAllActionPoints', JSON.stringify({}));

            showAllActionPointBtn.remove();
            closePage();
            return false;
        });


        mntTmp.appendTo(page);

        pageWrapper.css("display", "block");
        page.css("display", "block");
    }

}

function openStatistics(data, statType) {

    statType = statType || 'myStatistics';


    let pageWrapper = $(".pageWrapper");
    pageWrapper.find(".titleContainer").css("display", "none");

    let page = $("#page");
    page.empty();

    let statisticsContainer = $(".statisticsContainer").clone();
    statisticsContainer.removeClass("template");

    let statisticsContent = statisticsContainer.find(".statisticsContent");

    let myStatisticsBtn = statisticsContainer.find("#myStatisticsBtn");
    let summaryStatisticsBtn = statisticsContainer.find("#summaryStatisticsBtn");

    if (statType === 'allStatistics') {

        myStatisticsBtn.click(function () {

            if (lastEventTime + floodProtectionTime < getTimeStamp()) {

                lastEventTime = getTimeStamp();

                $.post('https://eco_cargo/myStatistics', JSON.stringify({}));
            } else {

                ShowNotification({type: 'warning', text: floodMessage});
            }
            return false;
        });

    } else {

        summaryStatisticsBtn.click(function () {

            if (lastEventTime + floodProtectionTime < getTimeStamp()) {

                lastEventTime = getTimeStamp();

                $.post('https://eco_cargo/getAllStatistics', JSON.stringify({

                    orderBy: missionOrderBy
                })).then(
                    resp => {

                        openStatistics(jsonParse(resp), 'allStatistics')
                    }
                );
            } else {

                ShowNotification({type: 'warning', text: floodMessage});
            }

            return false;
        });

    }


    if (statType === 'allStatistics') {

        if (!$.isEmptyObject(data)) {

            let summaryStatistics = $(".summaryStatistics").clone();
            summaryStatistics.removeClass("template");

            let table = summaryStatistics.find(".summaryStatisticsTable");
            let trTemp = table.find(".summaryStatisticsTableTr");
            table.removeClass("template");

            for (let i = 0; i < data.length; i++) {

                let cData = data[i];

                let tr = trTemp.clone();
                tr.removeClass("template");

                prepareStatData(cData);

                tr.find(".ranking").html(i + 1);
                tr.find(".summaryStatValueName").html(cData.character_name);
                tr.find(".summaryStatValueDistance").html(cData.distance);
                tr.find(".summaryStatValueAllStarted").html(cData.all_started);
                tr.find(".summaryStatValueAllDone").html(cData.all_done);
                tr.find(".summaryStatValueVulnerable").html(cData.vulnerable);
                tr.find(".summaryStatValueWorkingTime").html(("%s %s").format(cData.working_time, cData.working_time_unit));
                tr.find(".summaryStatValueQualityRate").html(("%s%").format(cData.quality_rate));
                tr.find(".summaryStatValueSuccessRate").html(("%s%").format(cData.success_rate));
                tr.find(".summaryStatValueRegistered").html(cData.registered);
                tr.find(".summaryStatValueLastActivity").html(cData.last_activity);

                tr.appendTo(table);
            }

            summaryStatistics.appendTo(statisticsContent);

            let th = table.find("th");

            th.click(function () {

                if ($(this).data('orderby') !== undefined) {

                    if (lastEventTime + floodProtectionTime < getTimeStamp()) {

                        lastEventTime = getTimeStamp();

                        missionOrderBy = $(this).data('orderby');

                        $.post('https://eco_cargo/getAllStatistics', JSON.stringify({

                            orderBy: missionOrderBy
                        })).then(
                            resp => {

                                openStatistics(jsonParse(resp), 'allStatistics')
                            }
                        );

                    } else {

                        ShowNotification({type: 'warning', text: floodMessage});
                    }
                }


                return false;
            });

            for (let i = 0; i < th.length; i++) {

                if (th[i].dataset.orderby === missionOrderBy) {

                    th[i].classList.add('currentOrder');
                }
            }
        }

    } else {

        if (!$.isEmptyObject(data)) {

            prepareStatData(data);

            let myStatistics = $(".myStatistics").clone();
            myStatistics.removeClass("template");


            myStatistics.find(".qualityRate").html(("%s%").format(data.quality_rate));
            myStatistics.find(".successRate").html(("%s%").format(data.success_rate));

            myStatistics.find(".distance").html(data.distance);
            myStatistics.find(".workingTime").html(data.working_time);

            myStatistics.find(".timeUnit").html(data.working_time_unit);
            myStatistics.find(".registeredTime").html(data.registered);

            myStatistics.find(".allStarted").html(data.all_started);
            myStatistics.find(".startedMission").html(data.started_mission);
            myStatistics.find(".startedDelivery").html(data.started_delivery);

            myStatistics.find(".allDone").html(data.all_done);
            myStatistics.find(".allDone").html(data.all_done);
            myStatistics.find(".doneMission").html(data.done_mission);
            myStatistics.find(".doneDelivery").html(data.done_delivery);

            myStatistics.find(".vulnerable").html(data.vulnerable);
            myStatistics.find(".defender").html(data.defender);

            myStatistics.find(".allStolen").html(data.all_stolen);
            myStatistics.find(".stolenMission").html(data.stolen_mission);
            myStatistics.find(".stolenDelivery").html(data.stolen_delivery);

            myStatistics.find(".destroyedTrailer").html(data.destroyed_trailer);

            myStatistics.appendTo(statisticsContent);

        }

    }

    statisticsContainer.appendTo(page);
    pageWrapper.css("display", "block");
    page.css("display", "block");


}

// Listen for NUI Events
window.addEventListener('message', function (event) {
    let item = event.data;

    switch (item.subject) {

        // HUD
        case 'UPDATE':

            updateHud(item.paramName, item.value);
            break;

        case 'CLOSE_INFO':

            closeHud('.dInfo');
            closeHud('.aInfo');
            break;

        case 'DELIVERY_INFO':

            if (item.operation === 'close') {

                closeHud('.dInfo');
            } else {

                deliveryInfo(item.deliveryData);
            }
            break;

        case 'ACTION_INFO':

            if (item.operation === 'close') {

                closeHud('.aInfo');

            } else if ($('#page').css('display') !== 'block') {

                actionInfo(item.actionData);
            }
            break;

        case 'NOTIFICATION':

            ShowNotification(item);
            break;


        // PAGES
        case 'CARGO_SELECT':

            closePage();
            closeHud('.aInfo');
            disableMissionStartForDefenders = item.disableMissionStartForDefenders;
            openCargoSelect(item.data, item.currentZone, item.player, item.mission);
            break;

        case 'CARGO_REPORT':

            closePage();
            openCargoPage(item.data);
            break;

        case 'MISSION_LIST':

            closePage();
            openMissionList(item.mission, item.player);
            break;

        case 'MAINTENANCE':

            closePage();
            openMaintenance(item.data);
            break;

        case 'STATISTICS':

            closePage();
            openStatistics(item.data);
            break;

        case 'CLOSE_PAGE':

            closePage();
            break;
    }

});


$('.btnClose').click(function () {

    closePage();
    $.post('https://eco_cargo/exit', JSON.stringify({}));
});


$(document).keyup(function (key) {

    if (key.which === 27 || key.which === 8) {

        closePage();
        $.post('https://eco_cargo/exit', JSON.stringify({}));
    }
});

