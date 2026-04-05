#import "Signs.h"
// #import <math.h>

float fixangle( float angle ){
    return angle - 360.0f * ( floor ( angle / 360.0f ) );
}

float torad( float deg ){
    return deg * ( M_PI / 180.0f );
}

float todeg( float rad ){
    return rad * ( 180.0f / M_PI );
}

float dsin( float deg ){
    return sin( torad( deg ) );
}

double jtime( double t ){
    return (t / 86400.0f) + 2440587.5f;
}

float kepler( float m, float ecc ){
    float EPSILON = 0.000001f;
    m = torad(m);
    float e = m;
    float delta;
    
    // first time
    delta = e - ecc * sin(e) - m;
    e -= delta / ( 1.0f - ecc * cos(e) );
    
    // loop
    while( fabsf(delta) > EPSILON ){
        delta = e - ecc * sin(e) - m;
        e -= delta / ( 1.0f - ecc * cos(e) );
    }
    
    return e;
}

@implementation Signs

- (id) initWithDate:(NSDate*) date {
    self = [super init];
    if (self) {
        now = date;
    }
    return self;
}

- (void) dealloc {
    // [super dealloc];
}

#pragma mark Moon Phase Calculation

- (float) phase {
    // const
    double Epoch = 2444238.5;
    float Elonge = 278.833540;
    float Elongp = 282.596403;
    float Eccent = 0.016718;
    float Mmlong = 64.975464;
    float Mmlongp = 349.383063;
    float Mlnode = 151.950429;
    float Minc = 5.145396;
    
    NSTimeInterval d = [now timeIntervalSince1970];
    
    double pdate = jtime( (float)d );
    double Day = pdate - Epoch;
    
    double N = fixangle( ( 360.0f / 365.2422f ) * Day );
    double M = fixangle( N + Elonge - Elongp );
    double Ec = kepler( M, Eccent );
    Ec = sqrt( ( 1.0f + Eccent ) / ( 1.0f - Eccent ) ) * tan( Ec / 2.0f );
    Ec = 2.0f * todeg( atan( Ec ) );
    double Lambdasun = fixangle( Ec + Elongp );
    
    double ml = fixangle( 13.1763966f * Day + Mmlong );
    double MM = fixangle( ml - 0.1114041f * Day - Mmlongp );
    double MN = fixangle( Mlnode - 0.0529539f * Day );
    double Ev = 1.2739f * sin( torad( 2.0f * ( ml - Lambdasun ) - MM ) );
    double Ae = 0.1858f * sin( torad( M ) );
    double A3 = 0.37f * sin( torad( M ) );
    double MmP = MM + Ev - Ae - A3;
    double mEc = 6.2886f * sin( torad( MmP ) );
    double A4 = 0.214f * sin( torad( 2.0f * MmP ) );
    double lP = ml + Ev + mEc - Ae + A4;
    double V = 0.6583f * sin( torad( 2.0f * ( lP - Lambdasun ) ) );
    double lPP = lP + V;
    double NP = MN - 0.16f * sin( torad( M ) );
    double y = sin( torad( lPP - NP ) ) * cos( torad( Minc ) );
    double x = cos( torad( lPP - NP ) );
    double Lambdamoon = todeg( atan2( y, x ) );
    Lambdamoon += NP;
    
    double MoonAge = lPP - Lambdasun;
    float mpfrac = fixangle( MoonAge ) / 360.0f;
    
    return mpfrac;
}

#pragma mark Moon Sign Calculation - Wrong?

const float d2r = M_PI / 180.0f;
const float r2d = 180.0f / M_PI;

// calculate Julian Day from Month, Day and Year
float mdy2julian(int m, int d, int y)
{
    float im = 12 * (y + 4800) + m - 3;
    float j = (2 * (im - floor(im/12) * 12) + 7 + 365 * im)/12;
    j = floor(j) + d + floor(im/48) - 32083;
    if(j > 2299171)j += floor(im/4800) - floor(im/1200) + 38;
    return j;
}

float ut2gst(float t, float ut)
{
    float t0 = 6.697374558 + (2400.051336 * t) + (0.000025862 * t * t);
    ut *= 1.002737909;
    t0 += ut;
    while(t0 < 0.0)t0 += 24;
    while(t0 > 24.0)t0 -= 24;
    return t0;
}

// Calculate Ayanamsa using J2000 Epoch
float calcayan(float t)
{
    float ln = 125.0445550 - 1934.1361849 * t + 0.0020762 * t * t; // Mean lunar node
    float off = 280.466449 + 36000.7698231 * t + 0.00031060 * t * t; // Mean Sun
    off = 17.23*sin(d2r * ln)+1.27*sin(d2r * off)-(5025.64+1.11*t)*t;
    off = (off- 85886.27)/3600.0;
    return off;
}


float dc;
float ra;
float pln;
float pla;

void ecl2equ(float ln, float la, float ob)
{
    float y = asin(sin(d2r *la ) * cos(d2r * ob ) + cos(d2r *la ) * sin(d2r *ob ) * sin(d2r * ln));
    dc = r2d * y;
    y = sin(d2r *ln ) * cos(d2r * ob) - tan(d2r * la) * sin(d2r * ob);
    float x = cos(d2r * ln);
    x = atan2(y,x);
    x = r2d * x;
    if(x < 0.0)x += 360;
    ra = x/15;
}

void equ2ecl(float ra, float dc, float ob)
{
    ra *= 15;
    float y = sin(d2r *ra) * cos(d2r * ob) + tan(d2r *dc) * sin(d2r * ob);
    float x = cos(d2r * ra);
    x = atan2(y,x);
    x *= r2d;
    if(x < 0)x += 360;
    pln = x;
    y = asin(sin(d2r * dc) * cos(d2r * ob) - cos(d2r * dc) * sin(d2r * ob) * sin(d2r * ra));
    pla = r2d * y;
}

- (float) moonSign {
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute fromDate:now]; // Get necessary date components
    
    int mon = (int)[components month];
    int day = (int)[components day];
    int year= (int)[components year];
    float hr= [components hour];
    hr	+= [components minute]/60;
    float tz= 5.0;
    tz += 0/60;
    float ln= 74.0;
    ln += 0/60;
    float la= 40.0;
    la += 43.0/60;
    
    
    // checks for checked DST, East, South
    Boolean dst = NO;
    Boolean eln = NO;
    Boolean sla = NO;
    
    if(eln)ln = -ln;
    if(sla)la = -la;
    if(dst){
        if(ln < 0.0)tz++;
        else tz--;
    }
    
    float jd = mdy2julian(mon,day,year);
    float f = 0.0;
    if(ln < 0.0)f = hr - tz;
    else f = hr + tz;
    float t = (jd - 2451545 - 0.5)/36525;
    float gst = ut2gst(t,f);
    t = ((jd - 2451545) + f/24 - 0.5)/36525;
    float ay = calcayan(t);
    
    float ob = 23.452294 - 0.0130125 * t; //  Obliquity of Ecliptic
    
    // Calculate Moon longitude, latitude, and distance
    
    // Moon mean longitude
    float l = (218.3164591 + 481267.88134236 * t);
    // Moon mean elongation
    float d = (297.8502042 + 445267.1115168 * t);
    // Sun's mean anomaly
    float m = (357.5291092 + 35999.0502909 * t);
    // Moon's mean anomaly
    float mm = (134.9634114 + 477198.8676313 * t);
    // Moon's argument of latitude
    f = (93.2720993 + 483202.0175273 * t);
    
    d *= d2r; m *= d2r; mm *= d2r; f *= d2r;
    
    float e = 1 - 0.002516 * t - 0.0000074 * t * t;
    
    float p =		6.288774 * sin(mm)
    + 1.274027 * sin(d*2-mm)
    + 0.658314 * sin(d*2)
    + 0.213618 * sin(2*mm)
    - 0.185116 * e * sin(m)
    - 0.114332 * sin(f*2);
    
    p +=	  0.058793 * sin(d*2 - mm * 2)
    + 0.057066 * e * sin(d*2 - m - mm)
    + 0.053322 * sin(d*2 + mm)
    + 0.045758 * e * sin(d*2 - m)
    - 0.040923 * e * sin(m - mm)
    - 0.034720 * sin(d)
    - 0.030383 * e * sin(m + mm);
    
    p +=	  0.015327 * sin(d*2 - f*2)
    - 0.012528 * sin(mm + f*2)
    + 0.010980 * sin(mm - f*2)
    + 0.010675 * sin(d * 4 - mm)
    + 0.010034 * sin(3 * mm);
    
    p +=	  0.008548 * sin(d * 4 - mm * 2)
    - 0.007888 * e * sin(d * 2 + m - mm)
    - 0.006766 * e * sin(d * 2 + m)
    - 0.005163 * sin(d - mm)
    + 0.004987 * e * sin(d + m)
    + 0.004036 * e * sin(d*2 - m + mm)
    + 0.003994 * sin(d * 2 + mm * 2);
    
    float b = 	  5.128122 * sin(f)
    + 0.280602 * sin(mm+f)
    + 0.277693 * sin(mm-f)
    + 0.173237 * sin(d*2-f)
    + 0.055413 * sin(d*2-mm+f)
    + 0.046271 * sin(d*2-mm-f);
    
    b += 	  0.032573 * sin(2*d + f)
    + 0.017198 * sin(2*mm + f)
    + 0.009266 * sin(2*d + mm - f)
    + 0.008823 * sin(2*mm - f)
    + 0.008247 * e * sin(2*d - m - f)
    + 0.004324 * sin(2*d - f - 2*mm);
    
    b += 	  0.004200 * sin(2*d +f+mm)
    + 0.003372 * e * sin(f - m - 2 * d)
    + 0.002472 * e * sin(2*d+f-m-mm)
    + 0.002222 * e * sin(2*d + f - m)
    + 0.002072 * e * sin(2*d-f-m-mm)
    + 0.001877 * e * sin(f-m+mm);
    
    b += 	  0.001828 * sin(4*d-f-mm)
    - 0.001803 * e * sin(f+m)
    - 0.001750 * sin(3*f)
    + 0.001570 * e * sin(mm-m-f)
    - 0.001487 * sin(f+d)
    - 0.001481 * e * sin(f+m+mm);
    
    
    float r =		0.950724 + 0.051818  * cos(mm)
    + 0.009531 * cos(2*d - mm)
    + 0.007843 * cos(2*d)
    + 0.002824 * cos(2*mm)
    + 0.000857 * cos(2*d + mm)
    + 0.000533 * e * cos(2*d - m);
    
    r += 	0.000401 * e * cos(2*d-m-mm)
    + 0.000320 * e * cos(mm-m)
    - 0.000271 * cos(d)
    - 0.000264 * e * cos(m+mm)
    - 0.000198 * cos(2*f - mm)
    + 0.000173 * cos(3 * mm);
    
    r += 	0.000167 * cos(4*d - mm)
    - 0.000111 * e * cos(m)
    + 0.000103 * cos(4*d - 2*mm)
    - 0.000084 * cos(2*mm - 2*d)
    - 0.000083 * e * cos(2*d + m)
    + 0.000079 * cos(2*d + 2*mm)
    + 0.000072 * cos(4*d);
    
    
    l += p;
    while(l < 0.0)l += 360.0;
    while(l > 360.0)l -= 360.0;
    
    
    // start parallax calculations
    ecl2equ(l,b,ob);
    ln = -ln; // flip sign of longitude
    ln /= 15;
    ln += gst;
    while(ln < 0.0)ln += 24;
    while(ln > 24.0)ln -= 24;
    float h = (ln - ra) * 15;
    // calc observer latitude vars
    float u = atan(0.996647 * tan(d2r *la));
    // hh = alt/6378140; // assume sea level
    float s = 0.996647 * sin(u); // assume sealevel
    float c = cos(u);	// + hh * cos(d2r(la)); // cos la' -- assume sea level
    r = 1/sin(d2r * r);
    float dlt = atan2(c * sin(d2r*h),r * cos(d2r * dc) - c * cos(d2r* h));
    dlt *= r2d;
    float hh = h + dlt;
    dlt /= 15;
    ra -= dlt;
    dc = atan(cos(d2r * hh) * ((r * sin(d2r * dc) - s)/
                               (r * cos(d2r *dc) * cos(d2r*h) - c)) );
    dc *= r2d;
    
    equ2ecl(ra,dc,ob);
    // dasha calculations
    l += ay;
    if(l < 0.0)l += 360.0;
    
    
    // document.display.npmoon.value = lon2dmsz(l);
    
    // extract the sign
    float x = fabsf(l);
    d = floor(x);
    m = (x - d);
    s = m * 60;
    m = floor(s);
    s = s - m;
    float z = floor(d/30);
    
    return z; // 0 - Aries etc...
    
    /*
     nk = (l * 60)/800.0;	// get nakshatra
     with(Math){
     document.display.nnakshatra.value = naks[floor(nk)];
     nl = floor(nk) % 9;
     db = 1 - (nk - floor(nk));
     bk = calcbhukti(db,nl);
     ndasha = (db * dasha[nl]) * 365.25;
     jd1 = jd + ndasha;
     d1 = nl;
     }
     */
    
    
}

#pragma mark Chinese Sign Calculation

float dr;
float fnnm(float x) {
    return (x - 360 * floor(x/360));
}

// trig functions in degrees
float fnsn(float x) {
    return sin(x*dr);
}

float fncs(float x) {
    return cos(x*dr);
}


float wSolst (float ys, float chTZ)
{ //chTZ in hours; + = west
    float LO,t,PE,L,DT,chJD,m;
    LO = 270;
    t = (365.2422 * (1*ys + LO / 360) - 693878.7) / 36525;
    PE = .00134 * fncs(22518.7541 * t + 153);
    PE = PE + .00154 * fncs(45037.5082 * t + 217) + .002 * fncs(32964.3577 * t + 313) + .00178 * fnsn(20.2 * t + 231);
    DT = 1;
    int wSolst_iter = 0;
    NSLog(@"[DIAG] wSolst enter ys=%.0f t=%.6f", ys, t);
    while (fabsf(DT * 36525) > .001) {
        L = 279.6967 + 36000.76892 * t + .0003025 * t * t;
        m = 358.476 + 35999.04975 * t - .00015 * t * t - .0000033 * t * t * t;
        L = L + (1.91946 - .004789 * t - .000014 * t * t) * fnsn(m) + (.020094 - .0001 * t) * fnsn(2 * m) + .000293 * fnsn(3 * m);
        L = L - .00479 * fnsn(fnnm(259.18 - 1934.142 * t)) - .00569 + PE + .00179 * fnsn(351 + 445267.1142 * t - .00144 * t * t);
        L = fnnm(L);
        DT = (fnnm(LO - L + 180) - 180) / 36525;
        t = t + DT;
        wSolst_iter++;
        if (wSolst_iter > 1000) {
            NSLog(@"[DIAG] wSolst LOOP LIMIT ys=%.0f iter=%d DT*36525=%f L=%f", ys, wSolst_iter, DT*36525, L);
            break;
        }
    } // LOOP WHILE ABS(DT * 36525) > .001
    chJD = t * 36525 + 2415020 - (.41 + 1.2053 * t + .4992 * t * t) / 1440 - chTZ / 24;
    NSLog(@"[DIAG] wSolst exit iter=%d chJD=%.1f result=%.1f", wSolst_iter, chJD, floor(chJD + .5));
    return floor(chJD + .5);
}

float solTerm (float y, float chTZ, float LO) {
    float ys,t,PE,L,DT,m,chJD;
    if (LO >= 270)
        ys = y - 1;
    else
        ys = 1*y;
    t = (365.2422 * (ys + LO / 360) - 693878.7) / 36525;
    PE = .00134 * fncs(22518.7541 * t + 153);
    PE = PE + .00154 * fncs(45037.5082 * t + 217) + .002 * fncs(32964.3577 * t + 313) + .00178 * fnsn(20.2 * t + 231);
    DT = 1;
    int solTerm_iter = 0;
    NSLog(@"[DIAG] solTerm enter y=%.0f LO=%.0f t=%.6f", y, LO, t);
    while (fabsf(DT * 36525) > .001) {
        L = 279.6967 + 36000.76892 * t + .0003025 * t * t;
        m = 358.476 + 35999.04975 * t - .00015 * t * t - .0000033 * t * t * t;
        L = L + (1.91946 - .004789 * t - .000014 * t * t) * fnsn(m) + (.020094 - .0001 * t) * fnsn(2 * m) + .000293 * fnsn(3 * m);
        L = L - .00479 * fnsn(fnnm(259.18 - 1934.142 * t)) - .00569 + PE + .00179 * fnsn(351 + 445267.1142 * t - .00144 * t * t);
        L = fnnm(L);
        DT = (fnnm(LO - L + 180) - 180) / 36525;
        t = t + DT;
        solTerm_iter++;
        if (solTerm_iter > 1000) {
            NSLog(@"[DIAG] solTerm LOOP LIMIT y=%.0f LO=%.0f iter=%d DT*36525=%f L=%f", y, LO, solTerm_iter, DT*36525, L);
            break;
        }
    } // LOOP WHILE ABS(DT * 36525) > .001
    chJD = t * 36525 + 2415020 - (.41 + 1.2053 * t + .4992 * t * t) / 1440 - chTZ / 24;
    NSLog(@"[DIAG] solTerm exit iter=%d chJD=%.1f result=%.1f", solTerm_iter, chJD, floor(chJD + .5));
    return floor(chJD + .5);
}

float nextNewMoon (float j1, float chTZ) {
    float d,t,k,m,mp,F,jdNo;
    d = j1 - 2415020; t = d / 36525;
    k = (j1 - 2415020.759) / 29.53058868;
    k = floor(k) - 1;
    jdNo = 0;
    int nnm_iter = 0;
    NSLog(@"[DIAG] nextNewMoon enter j1=%.1f k=%.0f", j1, k);
    while (jdNo <= j1){
        m = fnnm(359.22 + 29.10535608 * k);
        mp = fnnm(306.03 + 385.8169181 * k + .01073 * t * t + .00001236 * t * t * t);
        F = fnnm(21.2964 + 390.67050646 * k - .0016528 * t * t);
        
        jdNo = 2415020.75933 + 29.53058868 * k + .0001178 * t * t;
        jdNo = jdNo + .1734 * fnsn(m);
        jdNo = jdNo + .0021 * fnsn(2 * m);
        jdNo = jdNo - .4068 * fnsn(mp);
        jdNo = jdNo + .0161 * fnsn(2 * mp);
        jdNo = jdNo + .0104 * fnsn(2 * F);
        jdNo = jdNo - .0051 * fnsn(m + mp);
        jdNo = jdNo - .0074 * fnsn(m - mp);
        jdNo = jdNo + .001 * fnsn(2 * F - mp);
        
        jdNo = jdNo - (.41 + 1.2053 * t + .4992 * t * t) / 1440;
        jdNo = jdNo - chTZ / 24;
        jdNo = floor(jdNo + .5);
        
        k = k + 1;
        nnm_iter++;
        if (nnm_iter > 10000) {
            NSLog(@"[DIAG] nextNewMoon LOOP LIMIT j1=%.1f iter=%d jdNo=%.1f k=%.0f", j1, nnm_iter, jdNo, k);
            break;
        }
    } // LOOP UNTIL jdNo > j1
    NSLog(@"[DIAG] nextNewMoon exit iter=%d jdNo=%.1f", nnm_iter, jdNo);
    return jdNo;
}

-(int) chineseSign
{
    // consts
    dr = atan(1)/45;
    
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now]; // Get necessary date components
    
    long mon = [components month];
    long day = [components day];
    long year= [components year];
    
    /*
     * y is a 4 digit year
     * d returns the day of the month of Chinese New Year
     * m returns the month of Chinese New Year
     *
     */
    
    float chTZ;            // Chinese Time Zone -- hours
    float s1, s2;            // preceding and contained winter solstice jd
    float solT1, solT2;   // solar terms 1 and 2 - begin and end Aquarius
    float m1, m2, m3, m12;     // new moons
    float NY; // Proposed JD of new year
    int m,d,y;
    float cw0, cw1, cw2, cw3;
    int c;     // animal number
    
    y = (int)year;
    /*
     a = new Array (
     "Rat",  "Ox", "Tiger", "Rabbit(Hare)",
     "Dragon", "Snake", "Horse", "Sheep(Goat)",
     "Monkey", "Rooster", "Dog", "Boar(Pig)")
     var animal,animalPrev;
     */
    
    if (y < 1928)
        chTZ = -(465+40/60)/60;
    else
        chTZ = -8;
    
    s1 = wSolst(y-1,chTZ);
    s2 = wSolst(1*y,chTZ);
    solT1 = solTerm(y, chTZ, 300);
    solT2 = solTerm(y, chTZ, 330);
    m1 = nextNewMoon(s1, chTZ);
    m2 = nextNewMoon(m1, chTZ);
    m3 = nextNewMoon(m2, chTZ);
    m12 = nextNewMoon(s2, chTZ);
    
    NY = m2;
    if (floor((m12 - m1)/ 29.530588 + .5) == 13)
        if (solT1 >= m2 || solT2 >= m3) {
            NY = m3;
            /*  alert("delay")  */
        }
    
    if (NY > 2299160)
    {cw0= floor((NY - 1867216.25)/36524.25);
        cw0= NY + 1 + cw0 - floor(cw0/4);
    } else    {
        cw0= NY;
    };
    
    cw0 += 1524;
    cw1 = floor((cw0 - 122.1)/365.25);
    cw2 = floor(365.25*cw1);
    cw3 = floor((cw0 - cw2)/30.6001);
    d = cw0 - cw2 - floor(30.61*cw3);
    y = cw1 - 4716;
    m = cw3 - 1;
    if (m > 12)
    {m -= 12; y += 1;}
    
    // NSLog(@"start of ch new year %i, %i, %i",(int)d, (int)m, (int)y);
    
    c = (int)(y-4) % 12;
    if (mon == m) {
        if (day < d) {
            c--;
        }
    } else if (mon < m) {
        c--;
    }
    //    if (c == -1) c = 11; //around
    
    while (c < 0) c += 12; //around
    
    return c;
    
    /*
     cPrev= (y-5) % 12;
     animal = a[c]; animalPrev = a[cPrev];
     
     return {month: m, day: d, animal: animal,
     animalPrev: animalPrev}; // object containing the results
     */
}


#pragma mark Western Sign Calculation

-(int) westernSign
{
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now]; // Get necessary date components
    int day = (int)[components day];
    int month = (int)[components month];
    // int year = [components year];
    
    int num=0;
    
    // Aries
    if ((month == 3) && (day >= 21)) num = 0;
    if ((month == 4) && (day <= 19)) num = 0;
    // Taurus
    if ((month == 4) && (day >= 20)) num = 1;
    if ((month == 5) && (day <= 20)) num = 1;
    // Gemini
    if ((month == 5) && (day >= 21)) num = 2;
    if ((month == 6) && (day <= 21)) num = 2;
    // Cancer
    if ((month == 6) && (day >= 22)) num = 3;
    if ((month == 7) && (day <= 22)) num = 3;
    // Leo
    if ((month == 7) && (day >= 23)) num = 4;
    if ((month == 8) && (day <= 22)) num = 4;
    // Virgo
    if ((month == 8) && (day >= 23)) num = 5;
    if ((month == 9) && (day <= 22)) num = 5;
    // Libra
    if ((month == 9) && (day >= 23)) num = 6;
    if ((month == 10) && (day <= 23)) num = 6;
    // Scorpio
    if ((month == 10) && (day >= 24)) num = 7;
    if ((month == 11) && (day <= 21)) num = 7;
    // Sagittarius
    if ((month == 11) && (day >= 22)) num = 8;
    if ((month == 12) && (day <= 21)) num = 8;
    // Capricorn
    if ((month == 12) && (day >= 22)) num = 9;
    if ((month == 1) && (day <= 19)) num = 9;
    // Aquarius
    if ((month == 1) && (day >= 20)) num = 10;
    if ((month == 2) && (day <= 18)) num = 10;
    // Pisces
    if ((month == 2) && (day >= 19)) num = 11;
    if ((month == 3) && (day <= 20)) num = 11;
    
    return num;
}

#pragma mark Aztec Sign Calculation

-(int) aztecSign
{
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now]; // Get necessary date components
    int day = (int)[components day];
    int month = (int)[components month];
    int year = (int)[components year];
    
    int num=0;
    
    // starting 1900
    int yrs[] = { 17, 3, 8, 13, 18, 4, 9, 14, 19, 5, 10, 15, 20, 6, 11, 16, 1, 7, 12, 17, 2, 8, 13, 18, 3, 9, 14, 19, 4, 10, 15, 20, 5, 11, 16, 1, 6, 12, 17, 2, 7, 13, 18, 3, 8, 14, 19, 4, 9, 15, 20, 5, 10, 16, 1, 6, 11, 7, 2, 7, 12, 18, 3, 8, 13, 19, 4, 9, 14, 20, 5, 10, 15, 1, 6, 11, 16, 2, 7, 12, 17, 3, 8, 8, 18 };
    int mnths[] = { 19, 10, 18, 9, 19, 10, 0, 11, 2, 12, 3, 13 };
    
    int y_len = sizeof(yrs) / sizeof(yrs[0]);
    // NSLog(@"y_len %i",y_len);
    while (year >= (1900+y_len))
        year -= y_len;
    while (year < 1900)
        year += y_len;
    year -= 1900;
    // NSLog(@"year %i",year);
    
    num += yrs[year];
    
    //  NSLog(@"num %i",num);
    
    num += mnths[month-1];
    
    NSLog(@"num %i",num);
    
    num += day;
    
    if ((month == 2) && (day == 29))
        num++;
    
    num = num % 20;
    
    return num;
}

#pragma mark Mayan Sign Calculation
float GREGORIAN_EPOCH = 1721425.5;
float MAYAN_COUNT_EPOCH = 584282.5;

int leap_gregorian(int year) {
    return ((year % 4) == 0) && (!(((year % 100) == 0) && ((year % 400) != 0)));
}

float gregorian_to_jd(int year,int month,int day) {
    return (GREGORIAN_EPOCH - 1) +
    (365 * (year - 1)) +
    floor((year - 1) / 4) +
    (-floor((year - 1) / 100)) +
    floor((year - 1) / 400) +
    floor((((367 * month) - 362) / 12) +
          ((month <= 2) ? 0 : (leap_gregorian(year) ? -1 : -2)) +
          day);
}

float mod(float a, float b) {
    return a - (b * floor(a / b));
}
float amod(float a, float b) {
    return mod(a - 1, b) + 1;
}

int jd_to_mayan_tzolkin(float jd) {
    float lcount;
    
    jd = floor(jd) + 0.5;
    lcount = jd - MAYAN_COUNT_EPOCH;
    return (int) amod(lcount + 20, 20);
}

int jd_to_mayan_count(float jd) {
    float d, baktun, katun, tun, uinal, kin;
    
    jd = floor(jd) + 0.5;
    d = jd - MAYAN_COUNT_EPOCH;
    baktun = floor(d / 144000);
    d = mod(d, 144000);
    katun = floor(d / 7200);
    d = mod(d, 7200);
    tun = floor(d / 360);
    d = mod(d, 360);
    uinal = floor(d / 20);
    kin = mod(d, 20);
    
    return (int) baktun;
}

-(int) mayanSign
{
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now]; // Get necessary date components
    int mday = (int)[components day];
    int mon = (int)[components month];
    int year = (int)[components year];
    int hour = 0;
    int min = 0;
    int sec = 0;
    
    //  Update Julian day
    float j = gregorian_to_jd(year, mon + 0, mday) +
    (floor(sec + 60 * (min + 60 * hour) + 0.5) / 86400.0);
    
    return jd_to_mayan_tzolkin(j)-1;
}

#pragma mark Egyptian Sign Calculation

-(int) egyptianSign
{
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now]; // Get necessary date components
    int day = (int)[components day];
    int month = (int)[components month];
    // int year = [components year];
    
    int num=0;
    
    // Thoth
    if ((month == 8) && (day >= 29)) num = 0;
    if ((month == 9) && (day <= 27)) num = 0;
    // Horus
    if ((month == 9) && (day >= 28)) num = 1;
    if ((month == 10) && (day <= 27)) num = 1;
    // Wadjet
    if ((month == 10) && (day >= 28)) num = 2;
    if ((month == 11) && (day <= 26)) num = 2;
    // Sekhmet
    if ((month == 11) && (day >= 27)) num = 3;
    if ((month == 12) && (day <= 26)) num = 3;
    // Sphinx
    if ((month == 12) && (day >= 27)) num = 4;
    if ((month == 1) && (day <= 25)) num = 4;
    // Shu
    if ((month == 1) && (day >= 26)) num = 5;
    if ((month == 2) && (day <= 24)) num = 5;
    // Isis
    if ((month == 2) && (day >= 25)) num = 6;
    if ((month == 3) && (day <= 26)) num = 6;
    // Osiris
    if ((month == 3) && (day >= 27)) num = 7;
    if ((month == 4) && (day <= 25)) num = 7;
    // Amun
    if ((month == 4) && (day >= 26)) num = 8;
    if ((month == 5) && (day <= 25)) num = 8;
    // Hathor
    if ((month == 5) && (day >= 26)) num = 9;
    if ((month == 6) && (day <= 24)) num = 9;
    // Phoenix
    if ((month == 6) && (day >= 25)) num = 10;
    if ((month == 7) && (day <= 24)) num = 10;
    // Anubis
    if ((month == 7) && (day >= 25)) num = 11;
    if ((month == 8) && (day <= 28)) num = 11;
    
    return num;
}

#pragma mark Zoroasto Sign Calculation

-(int) zoroastoSign
{
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now]; // Get necessary date components
    //int day = [components day];
    //int month = [components month];
    int year = (int)[components year];
    
    int num=0;
    // 1906 = 0 - mod 32
    num = year-1906;
    num = num % 32;
    while (num < 0) num += 32; //around
    
    return num;
}

#pragma mark Celtic Sign Calculation
-(int) celticSign
{
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now]; // Get necessary date components
    int day = (int)[components day];
    int month = (int)[components month];
    // int year = [components year];
    
    int num=0;
    
    // Birch
    if ((month == 12) && (day >= 24)) num = 0;
    if ((month == 1) && (day <= 20)) num = 0;
    
    // Rowan
    if ((month == 1) && (day >= 21)) num = 1;
    if ((month == 2) && (day <= 17)) num = 1;
    
    // Ash
    if ((month == 2) && (day >= 18)) num = 2;
    if ((month == 3) && (day <= 17)) num = 2;
    
    // Alder
    if ((month == 3) && (day >= 18)) num = 3;
    if ((month == 4) && (day <= 14)) num = 3;
    
    // Willow
    if ((month == 4) && (day >= 15)) num = 4;
    if ((month == 5) && (day <= 12)) num = 4;
    
    // Hawthorn
    if ((month == 5) && (day >= 13)) num = 5;
    if ((month == 6) && (day <= 9)) num = 5;
    
    // Oak
    if ((month == 6) && (day >= 10)) num = 6;
    if ((month == 7) && (day <= 7)) num = 6;
    
    // Holly
    if ((month == 7) && (day >= 8)) num = 7;
    if ((month == 8) && (day <= 4)) num = 7;
    
    // Hazel
    if ((month == 8) && (day >= 5)) num = 8;
    if ((month == 9) && (day <= 1)) num = 8;
    
    // Vine
    if ((month == 9) && (day >= 2) && (day <= 29)) num = 9;
    
    // Ivy
    if ((month == 9) && (day >= 30)) num = 10;
    if ((month == 10) && (day <= 27)) num = 10;
    
    // Reed
    if ((month == 10) && (day >= 28)) num = 11;
    if ((month == 11) && (day <= 24)) num = 11;
    
    // Elder
    if ((month == 11) && (day >= 25)) num = 12;
    if ((month == 12) && (day <= 23)) num = 12;
    
    return num;
    
}

#pragma mark Norse Sign Calculation
-(int) norseSign
{
    int num=[self westernSign];
    
    num -= 8;
    if (num < 0) num += 12;
    
    return num;
}

#pragma mark Slavic Sign Calculation
- (int) slavicSign
{
    
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now]; // Get necessary date components
    int day = (int)[components day];
    int month = (int)[components month];
    // int year = [components year];
    
    int num=0;
    
    // Yarila
    if ((month == 3) && (day >= 21)) num = 0;
    if ((month == 4) && (day <= 20)) num = 0;
    
    // Lada
    if ((month == 4) && (day >= 21)) num = 1;
    if ((month == 5) && (day <= 21)) num = 1;
    
    // Lola = Dodola
    if ((month == 5) && (day >= 22)) num = 3;
    if ((month == 6) && (day <= 2)) num = 3;
    
    // Kostroma
    if ((month == 6) && (day >= 3) && (day <= 12)) num = 2;
    
    // Dodola
    if ((month == 6) && (day >= 13) && (day <= 21)) num = 3;
    
    // Velez
    if ((month == 6) && (day >= 22)) num = 4;
    if ((month == 7) && (day <= 22)) num = 4;
    
    // Svetovid
    if ((month == 7) && (day >= 6) && (day <= 7)) num = 5;
    
    // Dazhdbog
    if ((month == 7) && (day >= 23)) num = 6;
    if ((month == 8) && (day <= 23)) num = 6;
    
    
    // Rohsanity = Perun
    if ((month == 9) && (day >= 9) && (day <= 11)) num = 11;
    
    // Mokosh
    if ((month == 9) && (day >= 12) && (day <= 27)) num = 7;
    
    // Svarozich
    if ((month == 9) && (day >= 28)) num = 8;
    if ((month == 10) && (day <= 15)) num = 8;
    
    // Mara
    if ((month == 10) && (day >= 16)) num = 9;
    if ((month == 11) && (day <= 1)) num = 9;
    
    // Semargl
    if ((month == 11) && (day >= 2) && (day <= 8)) num = 10;
    
    // Skipper = Perun
    if ((month == 11) && (day >= 9) && (day <= 30)) num = 11;
    
    // Vyrgon = Lada
    if ((month == 12) && (day >= 1) && (day <= 10)) num = 1;
    
    // Kitovas = Perun
    if ((month == 12) && (day >= 11) && (day <= 23)) num = 1;
    
    // Perun
    if ((month == 12) && (day >= 24)) num = 11;
    if ((month == 1) && (day <= 20)) num = 11;
    
    // Stirbog
    if ((month == 1) && (day >= 21)) num = 12;
    if ((month == 2) && (day <= 20)) num = 12;
    
    // Svarog
    if ((month == 2) && (day >= 22)) num = 13;
    if ((month == 3) && (day <= 20)) num = 13;
    
    // Vesna
    if ((month == 8) && (day >= 24)) num = 14;
    if ((month == 9) && (day <= 8)) num = 14;
    
    return num;
    
}

#pragma mark Numerology Number Calculation
- (int) numerologySign
{
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now]; // Get necessary date components
    int day = (int)[components day];
    int month = (int)[components month];
    int year = (int)[components year];
    
    int nT = 0;
    int num = 0;
    
    // calculate
    if (day == 11) {
        num = 11;
    } else if (day == 22) {
        num = 22;
    } else {
        num = day % 10;
        num += lround(floor(day / 10));
    }
    
    if (month == 11) {
        num += 11;
    } else {
        num += month % 10;
        num += lround(floor(month / 10));
    }
    
    num += year % 10;
    num += lround(floor((year % 100) / 10));
    num += lround(floor((year % 1000) / 100));
    num += lround(floor((year % 10000) / 1000));
    
    
    if (num == 11) {
        num = 0;
    } else if (num == 22) {
        num = -1;
    } else {
        while (num > 9) {
            nT = num;
            num = nT % 10;
            num += lround(floor(num / 10));
            if (num == 11) {
                num = 0;
            } else if (num == 22) {
                num = -1;
            }
        }
    }
    
    
    // special case
    if (num == -1) {
        num = 10;
    }
    
    return num;
}


#pragma mark Geek Sign Calculation

-(int) geekSign
{
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now]; // Get necessary date components
    //int day = [components day];
    //int month = [components month];
    int year = (int)[components year];
    
    int num=0;
    // 1936 = 0 - mod 12
    num = year-1936;
    num = num % 12;
    while (num < 0) num += 12; //around
    
    return num;
}

@end




