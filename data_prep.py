# Python script 
# File: data_prep.py
# Author: Christian Brandstätter 
# Contact: bran.chri@gmail.com
# Date:  7.05.2020
# Copyright (C) 2020
# Description: Script to clean and reshape the data into multiple tables

import pandas as pd
sales_dat = pd.read_csv("./data_import/sales_data_sample.csv", encoding='iso-8859-1')

# after checking on the data source, some errors were apparent
# price each was capped at 100.00 

sales_dat.dtypes
sales_dat.info()

# datafix1: Clean Timedata 
sales_dat["ORDERDATE"] = pd.to_datetime(sales_dat["ORDERDATE"])
# datafix2: recalculate Priceeach (cap at 100) 
sales_dat["PRICEEACH"] = sales_dat["SALES"] / sales_dat["QUANTITYORDERED"]

# create a unique key 
keytest = sales_dat["ORDERNUMBER"].astype(str)+"_"+sales_dat["ORDERLINENUMBER"].astype(str)
keytest.duplicated().sum() # @ Christian: Erklärung vom duplicated().sum()
sales_dat["PK"] = keytest 

# Funktion zum Erzeugen eines Keys für die
# Aufteilung in verschiedene Tabellen -> Starschema

def create_key(series, first = ""):
    """Function to create a new key_value, if some entries are not unique @ Christian: Erklärng des Kommentars

    :param series: pandas series 
    :param first: enables the addition of a string before integer
    :returns: pandas series with integer / string keys 
    :rtype: series int64 or object if first is given 

    """
    step1 = list(series.unique())
    step2 = dict()

    for i in range(0, len(step1)): # @ Christian: auskommentieren des Codes
        step2[step1[i]] = i+1

    if len(first) > 0:
        for k, v in step2.items():
            step2[k] = first+str(v)
        
    return series.map(step2)

# Star Schema 
# Data Dimensions 

# Center Table 
# Time 
# Product 
# Customer / Region  
sales_dat.columns

# Creating Keys 
sales_dat["ON_ID"] = create_key(sales_dat["ORDERNUMBER"], "ON")
sales_dat["PR_ID"] = create_key(sales_dat["PRODUCTCODE"], "PR")
sales_dat["CU_ID"] = create_key(sales_dat["CUSTOMERNAME"], "CU")

# Center Table # Verbindet alle anderen Tables in der Mitte & erhält den PK der anderen Dimensionen. Von dem ausgehend kann man in die anderen Dimensionen abtauchen. (Time --> Month, Quater)
centertable = sales_dat[["PK", "ON_ID", "PR_ID", "CU_ID", "ORDERNUMBER", "QUANTITYORDERED",
                         "PRICEEACH", "ORDERLINENUMBER", "SALES", "STATUS", "DEALSIZE"]]

# Time Table 
timetable = sales_dat[["ON_ID", "ORDERDATE", "QTR_ID", "MONTH_ID", "YEAR_ID"]]
timetable = timetable.drop_duplicates()

# Product Table 
producttable = sales_dat[["PR_ID", "MSRP", "PRODUCTLINE", "PRODUCTCODE"]]
producttable = producttable.drop_duplicates()

# Customer / Region 
customertable = sales_dat[["CU_ID", "CUSTOMERNAME", "PHONE",
                           "ADDRESSLINE1", "ADDRESSLINE2", "CITY",
                           "STATE", "POSTALCODE", "COUNTRY",
                           "TERRITORY", "CONTACTLASTNAME", "CONTACTFIRSTNAME"]]
customertable = customertable.drop_duplicates()

centertable.to_csv("./data_output/centertable.csv", index=False)
timetable.to_csv("./data_output/ordertimes.csv", index=False)
producttable.to_csv("./data_output/products.csv", index=False)
customertable.to_csv("./data_output/customers.csv", index=False)
