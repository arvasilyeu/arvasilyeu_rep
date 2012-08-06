load data
 infile 'c:\data\countryList.csv'
 into table countries
 fields terminated by ","
 ( country_id, country_name )