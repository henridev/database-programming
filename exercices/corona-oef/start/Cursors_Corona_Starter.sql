-- Exercise 1
-- Create the following overview. First give the SQL statement, then use a cursor to get the following layout
/*
Africa
 - Number of countries =         54
 - Total population = 1,371,687,302
Asia
 - Number of countries =         49
 - Total population = 4,646,440,014
Europe
 - Number of countries =         51
 - Total population = 750,877,952
North America
 - Number of countries =         34
 - Total population = 592,829,053
Oceania
 - Number of countries =         16
 - Total population = 42,898,029
South America
 - Number of countries =         12
 - Total population = 433,950,159
*/




-- Exercise 2: Give per continent a list with the 5 countries with the highest number of deaths
-- Step 1: Give a list of all continents. First give the SQL statement, then use a cursor to get the following layout
-- - Africa
-- - Asia
-- - Europe
-- - North America
-- - Oceania
-- - South America

-- Step 2: Give the countries with the highest number of deaths for Africa. First give the SQL statement, then use a cursor to get the following layout
-- South Africa      87001
-- Tunisia      24732
-- Egypt      17149
-- Morocco      14132
-- Algeria       5767

-- Step 3: Combine both cursors to get the following result
/*
 - Africa
South Africa      87001
Tunisia      24732
Egypt      17149
Morocco      14132
Algeria       5767
 - Asia
India     446658
Indonesia     141381
Iran     119082
Turkey      62938
Philippines      37405
 - Europe
Russia     199450
United Kingdom     136465
Italy     130653
France     117157
Germany      93398
 - North America
United States     687746
Mexico     274703
Canada      27690
Guatemala      13331
Honduras       9679
 - Oceania
Australia       1231
Fiji        590
Papua New Guinea        225
New Zealand         27
Vanuatu          1
 - South America
Brazil     594200
Peru     199228
Colombia     126102
Argentina     114849
Chile      37432
*/

-- Step 4: Replace the TOP 5 values by a cte with dense_rank





-- Exercise 3
-- Make the following, visual overview for the total number of new_cases / 500 for Belgium for each week starting from 2021-01-01
-- This makes it more clear which are the weeks with a lot of new_cases
-- Use the function REPLICATE to get the x's
/*
- 1    xxxxx
- 2    xxxxxxxxxxxxxxxxxxxxxxxxxxx
- 3    xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
- 4    xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
- 5    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
- 6    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
- 7    xxxxxxxxxxxxxxxxxxxxxxxxxx
- 8    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
- 9    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
- 10    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
- 11    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
- 12    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
- 13    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
- 14    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
- 15    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
- 16    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
- 17    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
- 18    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
- 19    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
- 20    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
- 21    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
- 22    xxxxxxxxxxxxxxxxxxxxxxxxx
- 23    xxxxxxxxxxxxxxxxxxxx
- 24    xxxxxxxxxxx
- 25    xxxxxx
- 26    xxxxxx
- 27    xxxxxxxx
- 28    xxxxxxxxxxxxxx
- 29    xxxxxxxxxxxxxxxxxxx
- 30    xxxxxxxxxxxxxxxxxxxx
- 31    xxxxxxxxxxxxxxxxxxxxxx
- 32    xxxxxxxxxxxxxxxxxxxxxxxx
- 33    xxxxxxxxxxxxxxxxxxxxxxxxxx
- 34    xxxxxxxxxxxxxxxxxxxxxxxxxxx
- 35    xxxxxxxxxxxxxxxxxxxxxxxxxxxx
- 36    xxxxxxxxxxxxxxxxxxxxxxxxxxxx
- 37    xxxxxxxxxxxxxxxxxxxxxxxxxxx
- 38    xxxxxxxxxxxxxxxxxxxxxxxxxxxx
- 39    xxxxxxxxxxxxxxxxxxxxxxxxxxx
*/





-- Exercise 4
-- Give an overview of all the golfs: startdate + enddate + number of deaths
-- We define the beginning (ending) of a golf 
-- when the 14 days moving average of positive_rate becomes >= (<) 0.06
/*
Het begin van golf          1: 2020-03-07 00:00:00.0000
Het einde van golf          1: 2020-05-05 00:00:00.0000
Het aantal cases:      50400
Het aantal deaths:       8016
Het begin van golf          2: 2020-10-05 00:00:00.0000
Het einde van golf          2: 2021-01-14 00:00:00.0000
Het aantal cases:     542651
Het aantal deaths:      10230
Het begin van golf          3: 2021-02-25 00:00:00.0000
Het einde van golf          3: 2021-05-21 00:00:00.0000
Het aantal cases:     283803
Het aantal deaths:       2821
*/

