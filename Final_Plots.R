# R script 
# File: Final_Plots.R
# Author: Christian Brandstätter 
# Contact: bran.chri@gmail.com
# Date: 10.05.2020
# Copyright (C) 2020
# Description: R-Script for plotting

library(reshape2)
library(ggplot2)
library(dplyr)
library(tidyr)
library(viridis)


# get data files exported from pentaho 
datpath <- "./data_output/Analysis"
filenames <- list.files(datpath, full.names = TRUE)

# get names of dataframes 
varnames <- unlist(lapply(strsplit(filenames, "/"), "[", 4))
varnames <- unlist(lapply(strsplit(varnames, "\\."), "[", 1))

# actual import 
datimport <- lapply(filenames,function(x) read.csv2(x, stringsAsFactors = FALSE))
names(datimport) <- varnames

# splitting to dataframes 
list2env(datimport, envir=.GlobalEnv)

# global environment 
ls()


# preparing data for plotting -> reshape to long 
str(Orders_by_date)
Orders_by_date$orderdate <- as.Date(Orders_by_date$orderdate)

datplot <- melt(Orders_by_date, id.vars = "orderdate")
datplot <- datplot %>% arrange(orderdate, variable)


# This dataset is addressing two questions:
# which countries receive the highest orders and who are the premium customers? 
Orders_by_country$priceeach <- as.numeric(Orders_by_country$priceeach)
Orders_by_country$sales <- as.numeric(Orders_by_country$sales)
Orders_by_country$quantityordered <- as.numeric(Orders_by_country$quantityordered)
Orders_by_country$country <- trimws(Orders_by_country$country)
Orders_by_country$customername <- trimws(Orders_by_country$customername)

ctry_plot <- Orders_by_country %>%
  select(-customername) %>%
  group_by(country) %>% 
  summarize(sales = sum(sales))
## %>%
##   gather(variable, value, -country)

customer_plot <- Orders_by_country %>%
#  select(-country) %>%
  group_by(customername, country) %>% 
  summarize(sales = sum(sales)) %>%
  ungroup() %>%
  arrange(desc(sales)) %>%
  top_n(15, sales)

# sales per customers 
ggplot(customer_plot, aes(reorder(customername, -sales), sales)) + 
  geom_col(aes(fill=country))   +
  labs(y="Sales [USD]", x = "Customer") + theme_minimal(base_size = 20) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5)) +
  labs(title = "Sales per Customers", subtitle="(Top 15, Fill Color = Country)") +
  scale_fill_brewer(palette="Dark2") 
ggsave("./plots/Customers.png")

# Sales per Countries 
ggplot(ctry_plot, aes(reorder(country, -sales), sales)) + 
  geom_col()   +
  labs(y="Sales [USD]", x = "Customer") + theme_minimal(base_size = 20) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5)) +
  labs(title = "Sales per Country")

ggsave("./plots/Countries.png")



str(product_prize)
product_prize$productline <- trimws(product_prize$productline)
product_prize$Price_Mean <- as.numeric(product_prize$Price_Mean)
product_prize$SD_Price <- as.numeric(product_prize$SD_Price)


# Prices per Product category 
ggplot(product_prize, aes(productline, Price_Mean)) + 
                   geom_col()   + 
  labs(y="Mean Price [USD]", x = "Product Line") + theme_minimal(base_size = 20) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5)) +
  labs(title = "Product Prices per Category")
ggsave("./plots/product_price.png")



# Time Series 
ggplot(datplot[datplot$variable == "sales", ], aes(orderdate, as.numeric(value))) + 
  geom_line() +
  stat_smooth(method = "loess", formula = y ~ x, size = 1) + 
  scale_x_date(date_breaks = "3 month",
               date_minor_breaks = "1 month", date_labels = "%b-%Y")+ 
  labs(y="Sales [USD]", x = "Date [mon-YYYY]", title = "Sales per Time",
       subtitle = "smoothing line: loess") + theme_minimal(base_size = 20)+ 
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5))

ggsave("./plots/Time_Series.png")



str(Country_Year_Product)
Country_Year_Product$year_id <- as.integer(Country_Year_Product$year_id)
Country_Year_Product$productline <- trimws(Country_Year_Product$productline)
Country_Year_Product$sum_sales <- as.numeric(Country_Year_Product$sum_sales)
Country_Year_Product$country <- trimws(Country_Year_Product$country)

CYP_plot <- Country_Year_Product[, c("country", "year_id", "productline", "sum_sales")]

ggplot(CYP_plot, aes(x=country, y = sum_sales, group = productline, fill = productline))+
  geom_col() +
  facet_wrap(.~year_id) +
    labs(y="Sales [USD]", x = "Country") + theme_minimal(base_size = 10) +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5)) +
  labs(title = "Sales per Country, Year and Category") +
  scale_fill_brewer(palette="Spectral") 
ggsave("./plots/Synthesis.png")




