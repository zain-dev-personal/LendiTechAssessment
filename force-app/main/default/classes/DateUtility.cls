public class DateUtility {
    
    // Simple business-day adder (skips Sat/Sun)
    public static Date addBusinessDays(Date startDate, Integer days) {
        Integer added = 0;
        Date d = startDate;
        while (added < days) {
            d = d.addDays(1);
            if (d.toStartOfWeek().addDays(5) > d) { // Mon..Fri
                added++;
            }
        }
        return d;
    }
}