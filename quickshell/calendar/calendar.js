.pragma library

// The month grid of the calendar: 6 rows of 7 days, starting on the first
// day of the week of the user's language, with ISO week numbers.

function sameDay(a, b) {
    return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
}

// month: 0 to 11; firstDay: 0 = Sunday … 6 = Saturday (Qt.locale().firstDayOfWeek).
// Cells: { day, inMonth, today, weekend }.
function monthGrid(year, month, firstDay, today) {
    const first = new Date(year, month, 1);
    const shift = (first.getDay() - firstDay + 7) % 7;
    const cells = [];
    for (let i = 0; i < 42; i++) {
        // Noon: daylight saving changes never move the date.
        const date = new Date(year, month, 1 - shift + i, 12);
        cells.push({
            day: date.getDate(),
            inMonth: date.getMonth() === month,
            today: sameDay(date, today),
            weekend: date.getDay() === 0 || date.getDay() === 6,
            time: date.getTime()
        });
    }
    return cells;
}

// ISO 8601 week number: the week holding the year's first Thursday is week 1.
function isoWeek(date) {
    const day = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
    const weekday = day.getUTCDay() || 7;
    day.setUTCDate(day.getUTCDate() + 4 - weekday);
    const yearStart = new Date(Date.UTC(day.getUTCFullYear(), 0, 1));
    return Math.ceil(((day - yearStart) / 86400000 + 1) / 7);
}

// Week number of each of the 6 rows (taken from the row's Thursday).
function rowWeeks(cells) {
    const weeks = [];
    for (let row = 0; row < 6; row++) {
        const days = cells.slice(row * 7, row * 7 + 7).map(cell => new Date(cell.time));
        weeks.push(isoWeek(days.find(date => date.getDay() === 4)));
    }
    return weeks;
}

// "novembre 2026" -> "Novembre 2026": month names are lower case in many languages.
function title(name, year) {
    return name.charAt(0).toUpperCase() + name.slice(1) + " " + year;
}
