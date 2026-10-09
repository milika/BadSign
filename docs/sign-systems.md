# Sign systems

Each system is a method on `Signs` (`Bad Sign/Signs.m`) returning an index.
The index selects the name from `tableSubData` in `ViewController.m` and the
content files `SignAssets/<row>-<index>.html` and `<row>-<index>@2x.png`.
Only the birth **date** is used; the time of day is ignored (a time picker
existed once and is commented out). Date components come from
`[NSCalendar currentCalendar]`, so they follow the device's time zone.

Expected values for every system are pinned down by unit tests in
`Bad SignTests/Bad_SignTests.m` (reference Chinese New Year dates, the Maya
Long Count, worked life-path numbers). The calculation fixes of October 2026
are described in [history.md](history.md#october-2026-calculation-fixes).

## 0. Western Astrology: `westernSign`

Fixed date ranges.

| # | Sign | Dates | | # | Sign | Dates |
|---|---|---|---|---|---|---|
| 0 | Aries | 21 Mar – 19 Apr | | 6 | Libra | 23 Sep – 23 Oct |
| 1 | Taurus | 20 Apr – 20 May | | 7 | Scorpio | 24 Oct – 21 Nov |
| 2 | Gemini | 21 May – 21 Jun | | 8 | Sagittarius | 22 Nov – 21 Dec |
| 3 | Cancer | 22 Jun – 22 Jul | | 9 | Capricorn | 22 Dec – 19 Jan |
| 4 | Leo | 23 Jul – 22 Aug | | 10 | Aquarius | 20 Jan – 18 Feb |
| 5 | Virgo | 23 Aug – 22 Sep | | 11 | Pisces | 19 Feb – 20 Mar |

## 1. Chinese Astrology: `chineseSign`

Astronomical: finds the date of Chinese New Year for the birth year (second
new moon after the winter solstice, or the third in a leap-month year,
checked against the solar terms at 300° and 330°), in China's time zone
(UTC+8 from 1928, Beijing local mean time UTC+7:45:40 before). The animal
is `(year − 4) mod 12`, minus one if the birthday falls before that year's
New Year. Julian Days are `double`s; with `float` the result was a day off
around some New Years.

Order: 0 Rat, 1 Ox ("Oxen"), 2 Tiger, 3 Rabbit, 4 Dragon, 5 Snake, 6 Horse,
7 Sheep, 8 Monkey, 9 Rooster, 10 Dog, 11 Pig.

## 2. Aztec Astrology: `aztecSign`

The Aztec *tonalpohualli* and the Maya *tzolk'in* are the same 20-day count,
so `aztecSign` returns `mayanSign`. This agrees with Caso's correlation
(13 Aug 1521 Julian, the fall of Tenochtitlan, was 1 Coatl = Snake). Until
October 2026 this used a 1900–1984 lookup table that was one sign ahead of
the historical count for most dates and wrong for everyone born after 1984.

Order: 0 Crocodile, 1 Wind, 2 House, 3 Lizard, 4 Snake, 5 Death, 6 Deer,
7 Rabbit, 8 Water, 9 Dog, 10 Monkey, 11 Grass, 12 Reed, 13 Ocelot, 14 Eagle,
15 Vulture, 16 Motion, 17 Flint Knife, 18 Rain, 19 Flower.

## 3. Mayan Astrology: `mayanSign`

Converts the Gregorian date to a Julian Day and takes the Tzolk'in day sign
from the Long Count epoch (JD 584282.5, the GMT correlation):
`amod(JD − epoch + 20, 20) − 1`. This port follows John Walker's well-known
calendar converter.

Order: 0 Crocodile (Imix), 1 Wind, 2 House, 3 Lizard, 4 Serpent, 5 Death,
6 Deer, 7 Rabbit, 8 Water, 9 Dog, 10 Monkey, 11 Grass, 12 Reed, 13 Jaguar,
14 Eagle, 15 Vulture, 16 Earth, 17 Knife, 18 Storm, 19 Sun (Ajaw).

## 4. Egyptian Astrology: `egyptianSign`

Fixed date ranges.

| # | Sign | Dates | | # | Sign | Dates |
|---|---|---|---|---|---|---|
| 0 | Thoth | 29 Aug – 27 Sep | | 6 | Isis | 25 Feb – 26 Mar |
| 1 | Horus | 28 Sep – 27 Oct | | 7 | Osiris | 27 Mar – 25 Apr |
| 2 | Wadjet | 28 Oct – 26 Nov | | 8 | Amun | 26 Apr – 25 May |
| 3 | Sekhmet | 27 Nov – 26 Dec | | 9 | Hathor | 26 May – 24 Jun |
| 4 | Sphinx | 27 Dec – 25 Jan | | 10 | Phoenix | 25 Jun – 24 Jul |
| 5 | Shu | 26 Jan – 24 Feb | | 11 | Anubis | 25 Jul – 28 Aug |

## 5. Zoroastrian Astrology: `zoroastoSign`

Year only: `(year − 1906) mod 32`.

Order: 0 Deer, 1 Ram, 2 Mongoose, 3 Wolf, 4 Stork, 5 Spider, 6 Snake,
7 Beaver, 8 Turtle, 9 Magpie, 10 Squirrel, 11 Raven, 12 Rooster, 13 Bull,
14 Badger, 15 Camel, 16 Hedgehog, 17 Fallow Deer, 18 Elephant, 19 Horse,
20 Cheetah, 21 Peacock, 22 Swan, 23 Lynx, 24 Donkey, 25 Polar Bear,
26 Eagle, 27 Fox, 28 Dolphin, 29 Wild Boar, 30 Owl, 31 Falcon.

## 6. Celtic (tree) Astrology: `celticSign`

13 fixed date ranges.

| # | Tree | Dates | | # | Tree | Dates |
|---|---|---|---|---|---|---|
| 0 | Birch | 24 Dec – 20 Jan | | 7 | Holly | 8 Jul – 4 Aug |
| 1 | Rowan | 21 Jan – 17 Feb | | 8 | Hazel | 5 Aug – 1 Sep |
| 2 | Ash | 18 Feb – 17 Mar | | 9 | Vine | 2 Sep – 29 Sep |
| 3 | Alder | 18 Mar – 14 Apr | | 10 | Ivy | 30 Sep – 27 Oct |
| 4 | Willow | 15 Apr – 12 May | | 11 | Reed | 28 Oct – 24 Nov |
| 5 | Hawthorn | 13 May – 9 Jun | | 12 | Elder | 25 Nov – 23 Dec |
| 6 | Oak | 10 Jun – 7 Jul | | | | |

## 7. Norse Astrology: `norseSign`

Derived from the Western sign: `(western − 8) mod 12`, so the Norse year
starts at Sagittarius.

| # | God | Western sign | | # | God | Western sign |
|---|---|---|---|---|---|---|
| 0 | Ullr | Sagittarius | | 6 | Baldr | Gemini |
| 1 | Thor | Capricorn | | 7 | Heimdall | Cancer |
| 2 | Vali | Aquarius | | 8 | Freya | Leo |
| 3 | Saga | Pisces | | 9 | Forseti | Virgo |
| 4 | Odin | Aries | | 10 | Njord | Libra |
| 5 | Skadi | Taurus | | 11 | Vidar | Scorpio |

## 8. Slavic Astrology (Svarog circle): `slavicSign`

15 gods, irregular date ranges; some gods own several separate ranges.
Later rules in the code override earlier ones, which is how the short
ranges (e.g. 6–7 Jul) cut into longer ones. Effective result:

| # | God | Dates |
|---|---|---|
| 0 | Yarilo | 21 Mar – 20 Apr |
| 1 | Lada | 21 Apr – 21 May; 1 Dec – 10 Dec |
| 2 | Kostroma | 3 Jun – 12 Jun |
| 3 | Dodola | 22 May – 2 Jun; 13 Jun – 21 Jun |
| 4 | Veles | 22 Jun – 5 Jul; 8 Jul – 22 Jul |
| 5 | Kupalo | 6 Jul – 7 Jul |
| 6 | Dazhdbog | 23 Jul – 23 Aug |
| 7 | Mokosh | 12 Sep – 27 Sep |
| 8 | Svarozich | 28 Sep – 15 Oct |
| 9 | Morena | 16 Oct – 1 Nov |
| 10 | Semargl | 2 Nov – 8 Nov |
| 11 | Perun | 9 Sep – 11 Sep; 9 Nov – 30 Nov; 11 Dec – 20 Jan |
| 12 | Stribog | 21 Jan – 21 Feb |
| 13 | Svarog | 22 Feb – 20 Mar |
| 14 | Vesna | 24 Aug – 8 Sep |

## 9. Numerology: `numerologySign`

Intended: the life-path number. Add the digits of day, month and year
(keeping 11 and 22 whole), then reduce to one digit unless the total is a
master number. The index mapping is unusual:

| Index | Number |
|---|---|
| 0 | 11 |
| 1 – 9 | 1 – 9 |
| 10 | 22 |

Day 11 or 22 and month 11 count as a whole number rather than their digit
sum, and the year's digits are added unreduced. 33 is not treated as a master
number. Example: 1 Jan 1990 → 1 + 1 + (1+9+9+0) = 21 → 3. All names in
`tableSubData` are just "Number"; the HTML page shows the actual number.

## 10. Geek Astrology: `geekSign`

Year only: `(year − 1936) mod 12`.

Order: 0 Robot, 1 Wizard, 2 Alien, 3 Superhero, 4 Slayer, 5 Pirate,
6 Daikaiju, 7 Time Traveler, 8 Spy, 9 Astronaut, 10 Samurai, 11 Explorer.

## 11. Bad Sign: `badSign`

The app's own invention: the sum of the 11 indices above, `mod 12`. Its
names are creatures from Serbian folklore (the code comment calls the list
"Nash", i.e. "ours"):

0 Zmay, 1 Alla, 2 Bauk, 3 Usud, 4 Veshticca, 5 Lesnik, 6 Psoglav,
7 Zduhach, 8 Babaroga, 9 Villa, 10 Malich, 11 Talason.

Because it depends on every other result, any change to another algorithm
changes users' Bad Sign too.

## Moon phase: `phase`

Shown in the stats panel, not in the table. A port of John Walker's
*moontool* algorithm (epoch JD 2444238.5, 1980): computes the Sun's and
Moon's ecliptic longitudes and returns the phase as a fraction of the synodic
month (0 = new, 0.5 = full). `AppDelegate` rounds it to a percentage and maps
it to 8 images:

| % | Image | Label |
|---|---|---|
| 98–100, 0–2 | moon0 | New Moon |
| 3–23 | moon1 | Young Crescent |
| 24–26 | moon2 | First Quarter |
| 27–47 | moon3 | Waxing Gibbous |
| 48–52 | moon4 | Full Moon |
| 53–73 | moon5 | Waning Gibbous |
| 74–76 | moon6 | Last Quarter |
| 77–97 | moon7 | Old Crescent |

`moonSign` (the Moon's zodiac sign) is also implemented, marked "Wrong?" in
the source, and never called.
