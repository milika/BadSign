//
//  Bad_SignTests.m
//  Bad SignTests
//
//  Created by admin on 12/8/13.
//  Copyright (c) 2013 Void Software. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Signs.h"

@interface Bad_SignTests : XCTestCase

@end

@implementation Bad_SignTests

// Noon in the current calendar, the same way Signs reads the date back.
- (NSDate *)dateFor:(NSInteger)year :(NSInteger)month :(NSInteger)day
{
    NSDateComponents *c = [[NSDateComponents alloc] init];
    c.year = year; c.month = month; c.day = day; c.hour = 12;
    return [[NSCalendar currentCalendar] dateFromComponents:c];
}

- (Signs *)signsFor:(NSInteger)year :(NSInteger)month :(NSInteger)day
{
    return [[Signs alloc] initWithDate:[self dateFor:year :month :day]];
}

#pragma mark Western

- (void)testWesternBoundaries
{
    XCTAssertEqual([[self signsFor:1990 :3 :20] westernSign], 11); // Pisces
    XCTAssertEqual([[self signsFor:1990 :3 :21] westernSign], 0);  // Aries
    XCTAssertEqual([[self signsFor:1990 :12 :22] westernSign], 9); // Capricorn
    XCTAssertEqual([[self signsFor:1990 :1 :19] westernSign], 9);  // Capricorn
    XCTAssertEqual([[self signsFor:1990 :1 :20] westernSign], 10); // Aquarius
}

#pragma mark Chinese (reference: Chinese New Year dates)

- (void)testChineseNewYearBoundaries
{
    XCTAssertEqual([[self signsFor:1912 :2 :17] chineseSign], 11); // Pig
    XCTAssertEqual([[self signsFor:1912 :2 :18] chineseSign], 0);  // Rat, CNY 18 Feb 1912
    XCTAssertEqual([[self signsFor:1920 :2 :19] chineseSign], 7);  // Sheep
    XCTAssertEqual([[self signsFor:1920 :2 :20] chineseSign], 8);  // Monkey, CNY 20 Feb 1920
    XCTAssertEqual([[self signsFor:1985 :2 :19] chineseSign], 0);  // Rat
    XCTAssertEqual([[self signsFor:1985 :2 :20] chineseSign], 1);  // Ox, CNY 20 Feb 1985
    XCTAssertEqual([[self signsFor:1990 :1 :26] chineseSign], 5);  // Snake
    XCTAssertEqual([[self signsFor:1990 :1 :27] chineseSign], 6);  // Horse, CNY 27 Jan 1990
    XCTAssertEqual([[self signsFor:2006 :1 :28] chineseSign], 9);  // Rooster
    XCTAssertEqual([[self signsFor:2006 :1 :29] chineseSign], 10); // Dog, CNY 29 Jan 2006
    XCTAssertEqual([[self signsFor:2023 :1 :21] chineseSign], 2);  // Tiger
    XCTAssertEqual([[self signsFor:2023 :1 :22] chineseSign], 3);  // Rabbit, CNY 22 Jan 2023
    XCTAssertEqual([[self signsFor:1966 :1 :20] chineseSign], 5);  // Snake
    XCTAssertEqual([[self signsFor:1966 :1 :21] chineseSign], 6);  // Horse, CNY 21 Jan 1966
    XCTAssertEqual([[self signsFor:1996 :2 :18] chineseSign], 11); // Pig
    XCTAssertEqual([[self signsFor:1996 :2 :19] chineseSign], 0);  // Rat, CNY 19 Feb 1996
    XCTAssertEqual([[self signsFor:2020 :1 :24] chineseSign], 11); // Pig
    XCTAssertEqual([[self signsFor:2020 :1 :25] chineseSign], 0);  // Rat, CNY 25 Jan 2020
    XCTAssertEqual([[self signsFor:2033 :1 :30] chineseSign], 0);  // Rat
    XCTAssertEqual([[self signsFor:2033 :1 :31] chineseSign], 1);  // Ox, CNY 31 Jan 2033 (leap-month year)
}

#pragma mark Mayan and Aztec (reference: GMT correlation, 1 Coatl = 13 Aug 1521 Julian)

- (void)testMayanTzolkin
{
    XCTAssertEqual([[self signsFor:2012 :12 :21] mayanSign], 19); // 4 Ajaw, end of 13th baktun
    XCTAssertEqual([[self signsFor:2000 :1 :1] mayanSign], 1);    // 11 Ik'
}

- (void)testAztecFollowsTheSameDayCount
{
    XCTAssertEqual([[self signsFor:2012 :12 :21] aztecSign], 19); // Flower
    XCTAssertEqual([[self signsFor:2000 :1 :1] aztecSign], 1);    // Wind
    XCTAssertEqual([[self signsFor:1956 :7 :4] aztecSign], 15);   // Vulture
    XCTAssertEqual([[self signsFor:1985 :1 :1] aztecSign], 3);    // Lizard
    XCTAssertEqual([[self signsFor:1990 :6 :15] aztecSign], 14);  // Eagle
    XCTAssertEqual([[self signsFor:2024 :2 :29] aztecSign], 6);   // Deer
    XCTAssertEqual([[self signsFor:2024 :3 :1] aztecSign], 7);    // Rabbit
}

- (void)testAztecMatchesMayanEveryDay
{
    for (NSInteger year = 1900; year <= 2030; year += 7) {
        for (NSInteger month = 1; month <= 12; month++) {
            for (NSInteger day = 1; day <= 28; day += 3) {
                Signs *s = [self signsFor:year :month :day];
                XCTAssertEqual([s aztecSign], [s mayanSign], @"%ld-%ld-%ld", (long)year, (long)month, (long)day);
            }
        }
    }
}

#pragma mark Egyptian, Zoroastrian, Celtic, Norse, Geek

- (void)testEgyptianBoundaries
{
    XCTAssertEqual([[self signsFor:1990 :8 :28] egyptianSign], 11); // Anubis
    XCTAssertEqual([[self signsFor:1990 :8 :29] egyptianSign], 0);  // Thoth
}

- (void)testZoroastrianCycle
{
    XCTAssertEqual([[self signsFor:1906 :6 :1] zoroastoSign], 0);
    XCTAssertEqual([[self signsFor:1938 :6 :1] zoroastoSign], 0);
    XCTAssertEqual([[self signsFor:1905 :6 :1] zoroastoSign], 31);
    XCTAssertEqual([[self signsFor:2026 :6 :1] zoroastoSign], 24);
}

- (void)testCelticBoundaries
{
    XCTAssertEqual([[self signsFor:1990 :12 :23] celticSign], 12); // Elder
    XCTAssertEqual([[self signsFor:1990 :12 :24] celticSign], 0);  // Birch
    XCTAssertEqual([[self signsFor:1990 :9 :29] celticSign], 9);   // Vine
    XCTAssertEqual([[self signsFor:1990 :9 :30] celticSign], 10);  // Ivy
}

- (void)testNorseFollowsWestern
{
    XCTAssertEqual([[self signsFor:1990 :4 :1] norseSign], 4);  // Aries -> Odin
    XCTAssertEqual([[self signsFor:1990 :12 :1] norseSign], 0); // Sagittarius -> Ullr
}

- (void)testGeekCycle
{
    XCTAssertEqual([[self signsFor:1936 :6 :1] geekSign], 0);
    XCTAssertEqual([[self signsFor:1935 :6 :1] geekSign], 11);
    XCTAssertEqual([[self signsFor:1990 :6 :1] geekSign], 6);
}

#pragma mark Slavic

- (void)testSlavic
{
    XCTAssertEqual([[self signsFor:1990 :2 :20] slavicSign], 12); // Stribog
    XCTAssertEqual([[self signsFor:1990 :2 :21] slavicSign], 12); // Stribog
    XCTAssertEqual([[self signsFor:1990 :2 :22] slavicSign], 13); // Svarog
    XCTAssertEqual([[self signsFor:1990 :12 :5] slavicSign], 1);  // Lada
    XCTAssertEqual([[self signsFor:1990 :12 :15] slavicSign], 11); // Perun
    XCTAssertEqual([[self signsFor:1990 :7 :6] slavicSign], 5);   // Kupalo
}

- (void)testSlavicCoversEveryDay
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *date = [self dateFor:2024 :1 :1];
    for (int i = 0; i < 366; i++) {
        int s = [[[Signs alloc] initWithDate:date] slavicSign];
        XCTAssertTrue(s >= 0 && s < 15, @"%@", date);
        date = [cal dateByAddingUnit:NSCalendarUnitDay value:1 toDate:date options:0];
    }
}

#pragma mark Numerology (index 0 = 11, 1-9 = 1-9, 10 = 22)

- (void)testNumerologyLifePath
{
    XCTAssertEqual([[self signsFor:1990 :1 :1] numerologySign], 3);   // 1+1+19 = 21 -> 3
    XCTAssertEqual([[self signsFor:1985 :12 :25] numerologySign], 6); // 7+3+23 = 33 -> 6
    XCTAssertEqual([[self signsFor:1999 :11 :29] numerologySign], 5); // 11+11+28 = 50 -> 5
    XCTAssertEqual([[self signsFor:1999 :1 :22] numerologySign], 6);  // 22+1+28 = 51 -> 6
    XCTAssertEqual([[self signsFor:1990 :2 :8] numerologySign], 0);   // 8+2+19 = 29 -> 11
    XCTAssertEqual([[self signsFor:1990 :1 :2] numerologySign], 10);  // 2+1+19 = 22
    XCTAssertEqual([[self signsFor:1989 :9 :9] numerologySign], 9);   // 9+9+27 = 45 -> 9
}

#pragma mark Bad Sign

- (void)testBadSignIsSumOfOthersMod12
{
    Signs *s = [self signsFor:1990 :1 :1];
    int sum = [s westernSign] + [s chineseSign] + [s aztecSign] + [s mayanSign] + [s egyptianSign]
            + [s zoroastoSign] + [s celticSign] + [s norseSign] + [s slavicSign] + [s numerologySign]
            + [s geekSign];
    XCTAssertEqual([s badSign], sum % 12);
}

@end
