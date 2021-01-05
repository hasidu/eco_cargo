const MONEY = new Intl.NumberFormat('en-US',
    {
        style: 'currency', currency: 'USD',
        minimumFractionDigits: 0
    });

String.prototype.format = function () {
    return [...arguments].reduce((p, c) => p.replace(/%s/, c), this);
};

function millisecond2date(millisecond, locale) {

    let localeString = locale || 'hu-HU';
    return new Date(millisecond).toLocaleDateString(localeString)
}

function displayElapsedTime(elapsedTime) {

    if (elapsedTime < 60) {

        return {time: elapsedTime, unit: 'sec'}
    }

    let hours = Math.floor(elapsedTime / 3600);
    let minutes = ((Math.floor((elapsedTime % 3600) / 60) / 60).toPrecision(1)) * 1;

    if (hours < 1) {

        let minutes = Math.floor((elapsedTime % 3600) / 60);

        return {time: minutes, unit: 'min'}
    }

    return {time: hours + minutes, unit: 'h'}
}

function prepareStatData(data) {

    let displayTime = displayElapsedTime(data.working_time);

    data.distance = (data.distance * 1).toFixed(1);
    data.quality_rate = (data.quality_rate * 1).toFixed(1);
    data.success_rate = (data.success_rate * 1).toFixed(1);
    data.working_time = (displayTime.time * 1).toFixed(1);
    data.working_time_unit = displayTime.unit;
    data.registered = millisecond2date(data.registered, 'hu-HU');
    data.last_activity = millisecond2date(data.last_activity, 'hu-HU');
}

function getTimeStamp() {

    return Date.now() / 1000;
}